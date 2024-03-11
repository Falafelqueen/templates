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
  \n  # Setting up rspec
    gem 'rspec-rails'
    gem 'factory_bot_rails'
    gem 'faker'
    gem 'webdrivers'
    gem 'axe-core-capybara'
    gem 'axe-core-rspec'
RUBY

development_gems = <<~RUBY
  \n  # Store secret keys in .env file
    gem 'dotenv-rails'
    \n  # Check performance of queries [https://github.com/kirillshevch/query_track]
    gem 'query_track'
RUBY

inject_into_file 'Gemfile', before: 'group :development, :test do' do
  general_gems
end

# Development and Test gems
inject_into_file 'Gemfile', after: 'group :development, :test do' do
  development_gems
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
    system! "bin/yarn check --check-files || bin/yarn install"

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
RUBY

# Overwrite (or create) the bin/setup file with the new content
File.write('bin/setup', setup_script_content)

# Ensure the bin/setup file is executable
File.chmod(0755, 'bin/setup')

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
end
