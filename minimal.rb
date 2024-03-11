run "if uname | grep -q 'Darwin'; then pgrep spring | xargs kill -9; fi"

# Gemfile
# All env gems
general_gems = <<~RUBY
  gem 'autoprefixer-rails'
  gem 'simple_form', github: 'heartcombo/simple_form'
  gem 'sassc-rails'
RUBY

test_gems = <<~RUBY
  \n gem 'rspec-rails'
  \t gem 'factory_bot_rails'
  \t gem 'faker'
  \t gem 'selenium-webdriver'
  \t gem 'webdrivers'
  \t gem 'axe-core-capybara'
  \t gem 'axe-core-rspec'
RUBY

development_gems = <<~RUBY

  \n # Store secret keys in .env file
     gem 'dotenv-rails'
  \n # Check performance of queries [https://github.com/kirillshevch/query_track]
  \sgem 'query_track'
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

# After bundle
after_bundle do
  generate('rspec:install')
end
