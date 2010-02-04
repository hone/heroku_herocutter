require File.expand_path(File.dirname(__FILE__) + "/../example_helper")

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

    # don't know how to mock out load
    it "should load the init file", :pending => true do
      init_file = @herocutter_plugin_path + "/init.rb"
      stub(Kernel).load(init_file)
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
        stub(@plugin).system("git init > /dev/null 2>&1") { true } 
        stub(@plugin).system("git pull --depth 1 #{@git_uri}  > /dev/null 2>&1") { true }
      end

      it "should fetch the git uri" do
        mock(RestClient).get(anything) { @success_response }
        install_command
      end

      describe "when the git fetch is successful" do
        before(:each) do
          stub(RestClient).get(anything) { @success_response }
        end

        # waiting on refactoring of I/O in heroku gem
        it "should display plugin is installed", :pending => true do
          install_command
        end

        it "should install the plugin" do
          mock(@plugin).install { true }
          install_command
        end

        it "should use the git uri found" do
          mock(@plugin).system("git pull --depth 1 #{@git_uri}  > /dev/null 2>&1") { true }
          install_command
        end
      end
    end # install
  end # load!
end
