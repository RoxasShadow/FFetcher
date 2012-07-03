#--
# Copyright(C) 2012 Giovanni Capuano <webmaster@giovannicapuano.net>
#
# FFetcher is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# FFetcher is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with FFetcher.  If not, see <http://www.gnu.org/licenses/>.
#++
class String

  def strip_html_tags
    self.gsub(/<("[^"]*"|'[^']*'|[^'">])*>/, '')
  end
  
  def fix_encode # Pok\xE8mon => Pokèmon
    self.force_encoding 'ISO-8859-1'
    self.encode 'UTF-8'
  end
  
  def get_last_parentheses # <a href="...">Foo (bar)</a>\n[...](xyz) => xyz
    scan(/\(([^\)]+)\)/).last.first
  end
  
  def decode_html
    HTMLEntities.new.decode self
  end
  
  def to_filename(spacer = '_', limit = 255)
    self.gsub!(/"\/\*?<>|:/, spacer) # "/\*?<>|: are denied
    self.slice! limit..-1
    self
  end
  
  def page_exists?(path = '')
    begin
      if path.empty?
        !Nokogiri::HTML(open(self)).to_s.empty?
      else
        !Nokogiri::HTML(open(self)).xpath(path).first.to_s.empty?
      end
    rescue Exception => e
      false
    end
  end
  
end
