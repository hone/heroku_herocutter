require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require 'yaml'

describe Heroku::Command::Plugins do
  describe "on plugin load" do
    before(:each) do
      @directory = File.expand_path(File.dirname(__FILE__) + "/../../../")
      @herocutter_plugin_name = File.basename(File.expand_path(File.dirname(__FILE__) + "/../../"))
      @herocutter_plugin_path = "#{@directory}/#{@herocutter_plugin_name}"
      stub(Heroku::Plugin).list { [@herocutter_plugin_name] }
      stub(Heroku::Plugin).directory { @directory }
    end

    it "should include plugin directory in path" do
      Heroku::Plugin.load!
      $:.include?("#{@herocutter_plugin_path}/lib").should be_true
    end

    it "should load the init file" do
      init_file = @herocutter_plugin_path + "/init.rb"
      stub(Heroku::Plugin).load(init_file)
      Heroku::Plugin.load!
    end

    describe "on new plugin install" do
      def install_command
        Heroku::Command.run("plugins:install", [@plugin_name])
      end

      before(:each) do
        @plugin_name = "new_plugin"
        @git_uri = "git://github.com/hone/new_plugin.git"
        @error_response = <<JSON
{
  "error": "No plugin of that name found."
}
JSON
        @success_response = <<JSON
{
  "plugin": {
      "name": "new_plugin",
      "uri": "#{@git_uri}",
      "updated_at": "2010-01-28T07:10:30Z",
      "id": 11,
      "description": "A new plugin",
      "downloads_count": 1,
      "created_at": "2010-01-28T07:07:55Z"
  }
}
JSON
        @plugin = Heroku::Plugin.new(@git_uri)
        stub(Heroku::Plugin).new(@git_uri) { @plugin }
        stub(@plugin).system(anything) { true }
      end

      it "should fetch the git uri" do
        mock(RestClient).get(anything) { @success_response }
        install_command
      end

      describe "when the git fetch is successful" do
        before(:each) do
          stub(RestClient).get(anything) { @success_response }
        end

        it "should install the plugin" do
          mock.instance_of(Heroku::Command::Plugins).install
          install_command
        end

        it "should use the git uri found" do
          mock(Heroku::Plugin).new(@git_uri) { @plugin }
          install_command
        end
      end

      describe "when the git fetch is unsuccessful" do
        before(:each) do
          stub(RestClient).get(anything) { @error_resonse }
        end

        it "should pass the name/git uri passed through" do
          mock(Heroku::Plugin).new(@plugin_name) { @plugin }

          install_command
        end

        it "should install the plugin" do
          mock.instance_of(Heroku::Command::Plugins).install

          install_command
        end

      end
    end # install

    describe "on plugin push" do
      def push_command(uri = nil, name = nil)
        Heroku::Command.run("plugins:push", [uri, name])
      end

      before(:each) do
        @uri = "git://github.com/hone/heroku_herocutter.git"
      end

      describe "when YAML loads successfully" do
        before(:each) do
          @sandbox = @herocutter_plugin_path + "/spec/tmp"
          if File.exist?(@sandbox)
            FileUtils.rm_rf(@sandbox)
          end
          FileUtils.mkdir_p(@sandbox)

          @config_file = @sandbox + "/herocutter"
          File.open(@config_file, 'w') do |file|
            YAML.dump({'api_key' => '4f104e7891b31d4ac004677c9dfd0ac5'}, file)
          end

          stub.instance_of(Heroku::Command::Plugins).herocutter_file { @config_file }
        end

        after(:each) do
          FileUtils.rm_rf(@sandbox)
        end

        describe "and when the response posts successfully" do
          before(:each) do

            @git_uri = "git://github.com/hone/new_plugin.git"
            @success_response = <<JSON
{
  "plugin": {
      "name": "new_plugin",
      "uri": "#{@git_uri}",
      "updated_at": "2010-01-28T07:10:30Z",
      "id": 11,
      "description": "A new plugin",
      "downloads_count": 1,
      "created_at": "2010-01-28T07:07:55Z"
  }
}
JSON
            stub(RestClient).post(anything, anything, anything) { @success_response }
          end

          it "should display the plugin pushed and the uri" do
            mock.instance_of(Heroku::Command::Plugins).display("pushed plugin with uri: #{@uri}")

            push_command(@uri)
          end

          it "should pass the name and uri in the post" do
            name = "new plugin"
            mock(RestClient).post(anything, hash_including(:plugin => {:uri => @uri, :name => name }), anything) { @success_response }

            push_command(@uri, "new plugin")
          end

          it "should rewrite github uris" do
            mock(RestClient).post(anything,
                                  hash_including(:plugin => {:uri  => "git://github.com/hone/new_plugin.git",
                                                             :name => "new plugin" }),
                                  anything) { @success_response }

            push_command("git@github.com:hone/new_plugin.git", "new plugin")
          end

          describe "and when the uri is not passed in" do
            before(:each) do
              @git_uri = "git@heroku.com:hone/new_plugin.git"
              @git_remote_show_origin = "  URL: #{@git_uri}"
              stub.instance_of(Heroku::Command::Plugins).git_remote_show_origin { @git_remote_show_origin }
            end

            it "should generate the uri from the git origin remote" do
              name = "new plugin"
              mock(RestClient).post(anything, hash_including(:plugin => {:uri => @git_uri, :name => name }), anything) { @success_response }
              push_command(nil, "new plugin")
            end
          end
        end

        describe "and when the response returns an error" do
          before(:each) do
            @error_response = <<JSON
{
  "error": "Could not create plugin"
}
JSON

            stub(RestClient).post(anything, anything, anything) { @error_response }
          end

          it "should show an error" do
            mock.instance_of(Heroku::Command::Plugins).error(is_a(String))

            push_command(@uri)
          end
        end
      end

      describe "YAML load error" do
        before(:each) do
          stub(YAML).load_file { raise Errno::ENOENT }
        end

        it "should display error" do
          mock.instance_of(Heroku::Command::Plugins).error(anything)
          push_command(@uri)
        end
      end
    end
  end # load!
end
