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

    it "should load the plugin without errors" do
      Heroku::Plugin.load!
      $:.include?("#{@herocutter_plugin_path}/lib").should be_true
    end

    describe "on new plugin install" do
      before(:each) do
        @plugin_name = "new_plugin"
        @error_response = <<JSON
{
  "error": "No plugin of that name found." 
}
JSON
        @success_response = <<JSON
{
  "plugin": {
      "name": "herocutter",
      "uri": "git://github.com/hone/heroku_herocutter.git",
      "updated_at": "2010-01-28T07:10:30Z",
      "id": 11,
      "description": "Provides extra heroku plugin functionality to work with Herocutter",
      "downloads_count": 1,
      "created_at": "2010-01-28T07:07:55Z"
  }
}
JSON
      end

      fit "should fetch the git uri" do
        mock(RestClient).get(anything) { @success_response }
        Heroku::Command.run("plugins:install", [@plugin_name])
      end

      describe "when the git fetch is successful" do
        before(:each) do
          stub(RestClient).get("#{Heroku::Command::Plugins::HEROCUTTER_URL}/api/v1/plugins/", :format => 'json') { @success_response }
        end

      end
    end
  end # load!
end
