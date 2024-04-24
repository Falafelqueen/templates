run "if uname | grep -q 'Darwin'; then pgrep spring | xargs kill -9; fi"

# Gemfile
# All env gems
general_gems = <<~RUBY
  gem 'autoprefixer-rails'
  gem 'simple_form', github: 'heartcombo/simple_form'
  gem 'tailwindcss-rails'
  \n # Use devise for authentication
  gem 'devise'
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
run 'rm bin/setup'

# Use create_file to overwrite bin/setup with the new content
create_file 'bin/setup', setup_script_content, force: true

# Make sure bin/setup is executable
run 'chmod +x bin/setup'

def flashes
  <<~HTML
    <% if notice %>
      <div class="bg-yellow-50 border border-yellow-200 text-sm text-yellow-800 rounded-lg p-4 dark:bg-yellow-800/10 dark:border-yellow-900 dark:text-yellow-500" role="alert">
        <div class="flex">
          <div class="flex-shrink-0">
            <svg class="flex-shrink-0 size-4 mt-0.5" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"></path>
              <path d="M12 9v4"></path>
              <path d="M12 17h.01"></path>
            </svg>
          </div>
          <div class="ms-4">
            <h3 class="text-sm font-semibold">
              <%= notice %>
            </h3>
            <% if flash[:info] %>
              <div class="mt-1 text-sm text-yellow-700">
                <%= flash[:info] %>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    <% end %>

    <% if alert %>
      <div class="bg-red-50 border border-red-200 text-sm text-red-800 rounded-lg p-4 dark:bg-red-800/10 dark:border-red-900 dark:text-red-500" role="alert">
        <div class="flex">
          <div class="flex-shrink-0">
          <!-- icon start -->
            <span class="inline-flex justify-center items-center size-8 rounded-full border-4 border-red-100 bg-red-200 text-red-800 dark:border-red-900 dark:bg-red-800 dark:text-red-400">
              <svg class="flex-shrink-0 size-4" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M18 6 6 18"></path>
                <path d="m6 6 12 12"></path>
              </svg>
            </span>
          <!-- icon end -->
          </div>
          <div class="ms-4">
            <h3 class="text-sm font-semibold">
              <%= notice %>
            </h3>
            <% if flash[:info] %>
              <div class="mt-1 text-sm text-red-700 dark:text-red-400">
                <%= flash[:info] %>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    <% end %>
  HTML
end

def set_up_tests
  # Remove test folder
  run 'rm -rf test'
  # Install rspec
  rails_command 'generate rspec:install'
end

def set_up_tailwind
  # Add tailwind
  rails_command 'tailwindcss:install'
  ## Replace tailwind config file
  run 'rm -rf config/tailwind.config.js'
  run 'curl -L https://raw.githubusercontent.com/Falafelqueen/templated/main/config/tailwind.config.js > config/tailwind.config.js'
end

def set_up_simple_form
  # Add simple form
  rails_command 'generate simple_form:install'
  ## Replace simple form config file
  run 'rm -rf config/initializers/simple_form.rb'
  run 'curl -L https://raw.githubusercontent.com/Falafelqueen/templated/main/config/initializers/simple_form.rb > config/initializers/simple_form.rb'
  ## Add custom simple form wrapper
  run 'mkdir lib/simple_form'
  run 'curl -L https://raw.githubusercontent.com/Falafelqueen/templated/main/lib/simple_form/extensions.rb > lib/simple_form/extensions.rb'
  ## Replace to application_helper.rb to have tailwind_simple_form_for helper
  run 'rm -rf app/helpers/application_helper.rb'
  run 'curl -L https://raw.githubusercontent.com/Falafelqueen/templated/main/app/helpers/application_helper.rb > app/helpers/application_helper.rb'
  ## Add increase/descrease functionality to numeric controls
  run 'yarn add stimulus-numeric-controls'
end

def devise_replace_view_content
  link_to = <<~HTML
    <p>Unhappy? <%= link_to "Cancel my account", registration_path(resource_name), data: { confirm: "Are you sure?" }, method: :delete %></p>
  HTML
  button_to = <<~HTML
    <div class="flex align-items-center">
      <div>Unhappy?</div>
      <%= button_to "Cancel my account", registration_path(resource_name), data: { confirm: "Are you sure?" }, method: :delete, class: "py-3 px-4 inline-flex items-center gap-x-2 text-sm font-semibold rounded-full border border-transparent bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50 disabled:pointer-events-none" %>
    </div>
  HTML
  gsub_file('app/views/devise/registrations/edit.html.erb', link_to, button_to)
end

def devise_uncomment_navigational_formats
  gsub_file('config/initializers/devise.rb', "# config.navigational_formats = ['*/*', :html, :turbo_stream]", " config.navigational_formats = ['*/*', :html, :turbo_stream]")
end

def add_flash_partial
  # Create flash partial for notice and alert
  file 'app/views/shared/_flashes_general.html.erb', flashes
  # Add flash messages to application.html.erb
  inject_into_file 'app/views/layouts/application.html.erb', after: "<body>\n" do
    <<-HTML
      <%= render 'shared/flashes_general' %>
    HTML
  end
end

def set_up_devise
  # Set up devise with User model
  rails_command 'generate devise:install'
  rails_command 'generate devise User'
  add_flash_partial
  rails_command 'generate devise:views'
  devise_replace_view_content
  devise_uncomment_navigational_formats
end

# After bundle
after_bundle do
  set_up_tests
  set_up_tailwind
  set_up_simple_form

  # Add active storage
  rails_command 'active_storage:install'

  # Create home page
  rails_command 'generate controller Pages home --skip-routes --no-test-framework'
  route 'root to: "pages#home"'

  set_up_devise

  # Create .env file to store secret keys
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
