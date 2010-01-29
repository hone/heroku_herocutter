=begin
  Copyright (c) 2010 Terence Lee.

  This file is part of Heroku Herocutter.

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end

module Heroku::Command
  class Plugins < Base
    HEROCUTTER_URL = "http://herocutter.heroku.com"

    def install_with_herocutter
      name = args.shift
      new_name = fetch_git_uri(name)
      args.unshift(new_name)

      install_without_herocutter
    end

    alias_method :install_without_herocutter, :install
    alias_method :install, :install_with_herocutter

    def push
      begin
        yaml = YAML.load_file(herocutter_file)
      rescue Errno::ENOENT
        api_key_error
        return
      end

      if yaml['api_key'].nil?
        api_key_error
        return
      end
      uri = args[0]
      name = args[1]

      if uri.nil?
        uri = prepare_uri_from_git_origin
        github_uri_rewrite!(uri)
      end
      if uri and not uri.empty?
        response = RestClient.post("#{HEROCUTTER_URL}/api/v1/plugins",
          {
            :api_key => yaml['api_key'],
            :plugin => {:uri => uri, :name => name},
            :format => 'json'
          },
          {"Authorization" => yaml['api_key'] }
        )
        json = JSON.parse(response)
        if json and json['error']
          push_plugin_error
        else
          display "pushed plugin with uri: #{uri}"
        end
      else
        push_plugin_error
        return
      end

      uri
    end

    private
    # determine if they passed in a plugin name or uri
    # return the uri if found on herocutter
    def fetch_git_uri(name, herocutter_url = HEROCUTTER_URL)
      begin
        response = RestClient.get("#{herocutter_url}/api/v1/plugins/#{name}.json")
        json = JSON.parse(response)
      rescue
        return name
      end

      if json['error'].nil? and json['plugin']['uri']
        json['plugin']['uri']
      else
        name
      end
    end

    def herocutter_file
      "#{home_directory}/.heroku/herocutter"
    end

    def api_key_error
      error "Could not find file #{herocutter_file}. Please check http://herocutter.heroku.com/profile"
    end

    def push_plugin_error
      error "Could not push plugin, check your API key.  See http://herocutter.heroku.com/profile for more info"
    end

    def git_remote_show_origin
      `git remote show origin | grep URL`
    end

    def github_uri_rewrite!(uri)
      if /git@github.com/.match(uri)
        uri.sub!("git@github.com:", "git://github.com/")
      end
    end

    def prepare_uri_from_git_origin
      uri = git_remote_show_origin
      if uri and /URL: /.match(uri)
        uri = uri.split("URL: ").last.chomp
      end

      uri
    end

  end
end
