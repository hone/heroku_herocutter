require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

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
  end # load!
end
