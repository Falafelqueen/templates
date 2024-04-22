run "if uname | grep -q 'Darwin'; then pgrep spring | xargs kill -9; fi"

# Gemfile
# All env gems
general_gems = <<~RUBY
  gem 'autoprefixer-rails'
  gem 'simple_form', github: 'heartcombo/simple_form'
  gem 'sassc-rails'
  \n
RUBY

test_gems = <<~RUBY
  \n  # Rspec is set up for both test and development
      # To launch the html in browser and see the test (debugging purposes)
      gem "launchy"
RUBY

development_and_test_gems = <<~RUBY
  \n  # Store secret keys in .env file
    gem 'rspec-rails'
    gem 'dotenv-rails'
    \n  # Check performance of queries [https://github.com/kirillshevch/query_track]
    gem 'query_track'
    gem 'factory_bot_rails'
    gem 'faker'
    gem 'webdrivers'
    \n  # One-liners to test common Rails functionality [https://github.com/thoughtbot/shoulda-matchers/tree/main]
    gem 'shoulda-matchers', '~> 6.0'
RUBY

inject_into_file 'Gemfile', before: 'group :development, :test do' do
  general_gems
end

# Development and Test gems
inject_into_file 'Gemfile', after: 'group :development, :test do' do
  development_and_test_gems
end

# Test gems
inject_into_file 'Gemfile', after: 'group :test do' do
  test_gems
end

# Define the content for bin/setup
# Define the content to be written to bin/setup
setup_script_content = <<~RUBY
  #!/usr/bin/env ruby

  def setup
    log "Installing gems"
    # Only do bundle install if the much-faster
    # bundle check indicates we need to
    system! "bundle check || bundle install"

    log "Installing Node modules"
    # Only do yarn install if the much-faster
    # yarn check indicates we need to. Note that
    # --check-files is needed to force Yarn to actually
    # examine what's in the node_modules
    system! "bin/yarn check --check-files || yarn install"

    log "Dropping & creating the development database"
    # Note that the very first time this runs, db:reset
    # will fail, but this failure is fixed by
    # doing rails db:migrate
    system! "bin/rails db:reset || bin/rails db:migrate"

    log "Dropping & creating the test database"
    # Setting the RAILS_ENV explicitly to be sure
    # we actually reset the test database
    system!({"RAILS_ENV" => "test"}, "bin/rails db:reset")

    log "All set up."
    log ""
    log "To see commonly-needed commands, run:"
    log ""
    log "   bin/setup help"
    log ""
  end

  def help
    log "Useful commands"
    log ""
    log " bin/run         ## run app locally"
    log ""
    log " bin/ci          ## run all test and checks CI would"
    log ""
    log " spec            ## run all tests"
    log ""
    log " bin/setup help  ## show help commands"
    log ""
  end

  def system!(*args)
    log "Executing \#{args}"
    if system(*args)
      log "\#{args} succeeded"
    else
      log "\#{args} failed"
      abort
    end
  end

  def log(message)
    puts "[bin/setup] \#{message}"
  end

  # end of helpers

  if ARGV[0] == "help"
    help
  else
    setup
  end
RUBY

# bin/setup
## Write into setup file
run('rm bin/setup')
# Use create_file to overwrite bin/setup with the new content
create_file 'bin/setup', setup_script_content, force: true

# Make sure bin/setup is executable
run 'chmod +x bin/setup'

# After bundle
after_bundle do
  # remove test folder
  run('rm -rf test')
  # install rspec
  generate('rspec:install')

  # add tailwind
  rails_command 'css:install:tailwind'

  # add active storage
  rails_command 'active_storage:install'

  ## add simple form

  generate('simple_form:install')

  # create home page
  generate(:controller, 'pages', 'home', '--skip-routes', '--no-test-framework')
  route 'root to: "pages#home"'

  # create .env file to store secret keys
  # Dotenv
  run "touch '.env'"

  # Add .env to .gitignore
  append_to_file '.gitignore', '.env'

  # Initialize git
  git :init
  git add: '.'
  git commit: "-m 'Initial commit from template'"
end

# Do not generate extra files
initializer 'generators.rb', <<-CODE
  Rails.application.config.generators do |g|
    g.test_framework :rspec, {
                     fixtures: false,
                     fixture_replacement: :factory_bot,
                     dir: 'spec/factories',
                     view_specs: false,
                     helper_specs: false,
                     routing_specs: false,
                     request_specs: false,
                     controller_specs: false
                    }
  end
CODE
