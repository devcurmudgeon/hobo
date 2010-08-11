require 'generators/hobo_support/thor_shell'
module Hobo
  class SetupWizardGenerator < Rails::Generators::Base

    include Generators::HoboSupport::ThorShell

    def startup
      say_title 'Startup'
      say 'Initializing Hobo...'
      invoke 'hobo:startup'
    end

    def choose_test_framework
      say_title 'Test Framework'
      return unless yes_no? "Do you want to customize the test_framework?"
      require 'generators/hobo/test_framework/test_framework_generator'
      f = Hobo::TestFrameworkGenerator::FRAMEWORKS * '|'
      test_framework = choose("Choose your preferred test framework: [<enter>=#{f}]:", /^(#{f})$/, 'test_unit')
      fixtures = yes_no?("Do you want the test framework to generate the fixtures?")
      fixture_replacement = ask("Type your preferred fixture replacement or <enter> for no replacement:")
      invoke 'hobo:test_framework', [test_framework, fixture_replacement], :fixtures => fixtures
      say("WARNING: Remember to add the '#{fixture_replacement}' gem to the Gemfile at the following prompt", Color::RED) unless fixture_replacement.blank?
    end

    def gems
      say_title "Optional Gems"
      gem 'will_paginate' if yes_no?("Do you want to use the 'will_paginate' gem in your application (recommended)?")
      statements = []
      say <<EOQ
You can append a few statements to the Gemfile now. For example if you choose 'factory_girl' as the fixture_replacement, you should enter something like:
    gem 'factory_girl', :group => :test
and that will be appended to the Gemfile, so the Hobo generators will imediately use it to produce your fixtures.
EOQ
      statements = multi_ask "Type your statement or <enter> to stop adding:"
      unless statements.empty?
        append_file 'Gemfile', statements * "\n"
        puts run('bundle install')
      end
    end

    def invite_only_option
      say_title 'Invite Only Option'
      @invite_only = yes_no?("Do you want to add the features for an invite only website?")
    end

    def rapid
      say_title 'Hobo Rapid'
      say 'Installing Hobo Rapid and default theme...'
      invoke 'hobo:rapid', [], :invite_only => @invite_only
    end

    def user_resource
      say_title 'User Resource'
      @user_resource_name = ask("Choose a name for the user resource [<enter>=user|<custom_name>]:", 'user')
      say "Installing '#{@user_resource_name}' resources..."
      invoke 'hobo:user_resource', [@user_resource_name], :invite_only => @invite_only
    end

    def front_controller
      say_title 'Front Controller'
      front_controller_name = ask("Choose a name for the front controller [<enter>=front|<custom_name>]:", 'front')
      say "Installing #{front_controller_name} controller..."
      invoke 'hobo:front_controller', [front_controller_name], :invite_only => @invite_only
    end

    def admin_subsite
      say_title 'Admin Subsite'
      admin = @invite_only ? true : yes_no?("Do you want to add an admin subsite?")
      return unless admin
      admin_subsite_name = ask("Choose a name for the admin subsite [<enter>=admin|<custom_name>]:", 'admin')
      say "Installing admin subsite..."
      invoke 'hobo:admin_subsite', [admin_subsite_name, @user_resource_name], :invite_only => @invite_only
    end

    def migration
      say_title 'DB Migration'
      action = choose('Initial Migration: [s]kip, [g]enerate migration file only, generate and [m]igrate [s|g|m]:', /^(s|g|m)$/)
      opt = case action
            when 's'
              return say('Migration skipped!')
            when 'g'
              {:generate => true}
            when 'm'
              {:migrate => true}
          end
      say action == 'g' ? 'Generating Migration...' : 'Migrating...'
      invoke 'hobo:migration', ['initial_migration'], opt
    end

    def i18n
      say_title 'I18n'
      # search for hobo available locales
      locales = Hobo::Engine.paths.config.locales.paths.map do |l|
        l =~ /hobo\.([^\/]+)\.yml$/
        $1.to_sym.inspect
      end
      # choose default_locale
      say "The available Hobo internal locales are #{locales * ', '} (please, contribute to more translations)"
      default_locale = ask "Do you want to set a default locale? Type the locale or <enter> to skip:"
      default_locale.gsub!(/\:/, '')
      environment "config.i18n.default_locale = #{default_locale.to_sym.inspect}"
      say "NOTICE: You should manually install in 'config/locales' the Rails locale file(s) that your application will use.", Color::YELLOW
    end

    def git_repo
      say_title 'Git Repository'
      return unless yes_no?("Do you want to initialize a git repository now?")
      say 'Initializing git repository...'
      append_file '.gitignore', "/app/views/taglibs/auto/*\n/config/hobo_routes.rb\n"
      git :init
      git :add => '.'
      git :commit => '-m "initial commit"'
    end

    def finalize
      say_title 'Process completed!'
      say <<EOF
You can start your application with `rails server`
(run with --help for options). Then point your browser to
http://localhost:3000/

Follow the guidelines to start developing your application.
You can find the following resources handy:

* The Getting Started Guide: http://guides.rubyonrails.org/getting_started.html
* Ruby on Rails Tutorial Book: http://www.railstutorial.org/

EOF
    end

  end
end