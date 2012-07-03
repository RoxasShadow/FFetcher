#! /usr/bin/env ruby
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
require 'optparse'
require 'open-uri'
require 'nokogiri'
require 'htmlentities'

VERSION = '0.1'

class String

  def strip_html_tags
    self.gsub(/<("[^"]*"|'[^']*'|[^'">])*>/, '')
  end
  
  def fix_encode # Pok\xE8mon => Pokèmon
    self.force_encoding 'ISO-8859-1'
    self.encode 'UTF-8'
  end
  
  def get_last_parentheses
    scan(/\(([^\)]+)\)/).last.first
  end
  
  def decode_html
    HTMLEntities.new.decode self
  end
  
  def to_filename
    self.gsub(/\W/, ' ').gsub(/\  /, '-').gsub(/(-)$/, '').gsub(/^(-)/, '')[0..59]
  end
  
end

options = { :backup => true }
OptionParser.new { |opts|
	opts.banner = 'Usage: ruby ffetcher.rb [option] [arg]'
	
	opts.on '-h', '--help', 'Displays this help' do
		puts opts
		exit
	end
	opts.on '-v', '--version', 'Displays the version' do
		puts VERSION
		exit
	end
	opts.on '--no-backup', 'Disable backup function and output the fetched data' do |value|
		options[:backup] = false
	end
}.parse!

abort "Section URL is required. Type `#{File.basename(__FILE__)} -h` for more information." if ARGV.empty?
section = ARGV[0]
section_name = Nokogiri::HTML(open(section)).xpath('/html/head/title').to_s.strip_html_tags.chomp.to_filename

pages = [ section ]
topics = []

# Getting all the pages of a section
latest = 30
page = Nokogiri::HTML(open(section)).xpath('//ul[@class = "pages"]//li').first
if !page.nil?
  n = page.to_s.get_last_parentheses.to_i - 1
  for i in 1..n
    pages << "#{section}&st=#{latest}"
    latest += 30
  end
end

# Getting all the topics of a section
pages.each { |page|
  Nokogiri::HTML(open(page)).xpath('//h2[@class = "web"]//a').each { |topic|
    next if topic['title'].nil?
    topics << {
      :date   => topic['title'].gsub(/This topic was started: /, ''),
      :title  => topic.inner_html.fix_encode.decode_html.strip_html_tags,
      :url    => [ topic['href'] ]
    }
  }
}

# Do what you want with topics

# ---

# Following blocks of code can require *MORE* time and bandwidth usage!

# Getting all the pages of each topic 
topics.each { |topic|
  latest = 15
  page = Nokogiri::HTML(open(topic[:url].first)).xpath('//ul[@class = "pages"]//li').first
  if !page.nil?
    n = page.to_s.get_last_parentheses.to_i - 1
    topic_pages = []
    for i in 1..n
      topic_pages << "#{topic[:url].first}&st=#{latest}"
      latest += 15
    end
    topic[:url] += topic_pages
  end
}

if options[:backup]
  # Backupping
  Dir::mkdir("#{section_name}") unless File.directory? "#{section_name}"
  
  topics.each { |topic|
    Dir::mkdir("#{section_name}/#{topic[:title].to_filename}") unless File.directory? "#{section_name}/#{topic[:title].to_filename}"
    topic[:url].each_with_index { |u, i|
      File.open("#{section_name}/#{topic[:title].to_filename}/#{i + 1}.html", ?w) { |f|
        f.write Nokogiri::HTML(open(u)).to_s
      }
    }
  }
end

if options[:backup]
  puts "Fetched and saved #{topics.length} topics in #{pages.length} pages on #{section_name}."
else
  puts "Fetched #{topics.length} topics in #{pages.length} pages on #{section_name}."
  puts
  puts '----------------------------'
  # Printing all the topics of a section.
  topics.each { |t|
    p t
  }
  puts '----------------------------'
end
