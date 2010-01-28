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

    private
    # determine if they passed in a plugin name or uri
    # return the uri if found on herocutter
    def fetch_git_uri(name, herocutter_url = HEROCUTTER_URL)
      begin
        json = JSON.parse(RestClient.get("#{herocutter_url}/plugins/#{name}.json"))
      rescue
        return name
      end

      if json['error'].nil? and json['plugin']['uri']
        json['plugin']['uri']
      else
        name
      end
    end

  end
end
