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

Heroku::Command::Help.group('Herocutter Plugins') do |group|
  group.command 'plugins:install <plugin name>',        'install the plugin from herocutter'
  group.command 'plugins:push [<git_uri>]',     'push plugin up to herocutter'
end
