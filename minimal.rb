run "if uname | grep -q 'Darwin'; then pgrep spring | xargs kill -9; fi"

# Gemfile
# All env gems
general_gems = <<~RUBY
  gem 'autoprefixer-rails'
  gem 'simple_form', github: 'heartcombo/simple_form'
  gem 'sassc-rails'
RUBY

inject_into_file 'Gemfile', before: 'group :development, :test do' do
  general_gems
end

# Development and Test gems
gem_group :development, :test do
  # Store secret keys in .env file
  gem 'dotenv-rails'
  # Check performance of queries [https://github.com/kirillshevch/query_track]
  gem 'query_track'
end


# Setting up rspec
gem_group :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'selenium-webdriver'
  gem 'webdrivers'
  gem 'axe-core-capybara'
  gem 'axe-core-rspec'
end

# After bundle
after_bundle do
  generate('rspec:install')
end
