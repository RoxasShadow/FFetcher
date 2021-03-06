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
require './string.rb'

VERSION = '0.6.0'

options = { :backup => true, :overwrite => true }

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
	opts.on '-m', '--mute', 'Minimize the output' do
		options[:mute] = true
	end
	opts.on '-s ', '--section ', 'The section URL to fetch' do |url|
		options[:section] = url
	end
	opts.on '-f ', '--file ', 'The file with the section URLs to fetch' do |file|
		options[:file] = file
	end
	opts.on '--no-backup', 'Disable backup function and output the fetched data' do
		options[:backup] = false
	end
	opts.on '--no-overwrite', 'Saves only new topics not backupped.' do
		options[:overwrite] = false
	end
}.parse!

sections = []
if !options[:section].nil?
  sections << options[:section]
elsif !options[:file].nil? && File.exists?(options[:file])
  puts 'Parsing section URLs...'
  file = File.open(options[:file]).read
  file.gsub!(/\r\n?/, "\n")
  file.each_line { |line|
    next unless line.start_with? 'http'
    sections << line.chomp
  }
end

tmp = sections.clone
sections.delete_if { |s|
  !s.page_exists?
}

puts "The following URL(s) are not valid or not found:\n\t#{(tmp - sections).join("\n\t")}" if (tmp - sections).length > 0

abort "Not valid section URL(s) found. Type `#{File.basename(__FILE__)} -h` for more information." if sections.empty?

sections.each { |section|
  tmp = Nokogiri::HTML(open(section))
  section_name = tmp.xpath('/html/head/title').to_s.chomp.strip_html_tags.fix_encode.to_filename
  puts "\t\t\t--- Entering in #{section_name} ---" if options[:mute].nil?

  Dir::mkdir(section_name) if options[:backup] && !File.directory?(section_name)

  pages = [ section ]
  topics = []

  # Getting all the pages of a section
  latest = 30
  page = tmp.xpath('//ul[@class = "pages"]//li').first
  if !page.nil?
    n = page.to_s.get_last_parentheses.to_i - 1
    1.upto(n) do
      pages << "#{section}&st=#{latest}"
      latest += 30
    end
  end

  # Getting all the topics of a section
  pages.each_with_index { |page, i|
    puts "Fetching topics list: #{i+1}/#{pages.length}..." if options[:mute].nil?
    
    tmp = Nokogiri::HTML(open(page))
    
    tmp.xpath('//h2[@class = "web"]//a').each { |topic|
      next if topic['title'].nil?
      
      topics << {
        :date   => topic['title'].gsub(/This topic was started: /, ''),
        :title  => topic.inner_html.chomp.strip_html_tags.fix_encode,
        :url    => [ topic['href'] ]
      }
    }
    
    if options[:backup]
      next if !options[:overwrite] && File.exists?("#{section_name}/index#{i+1}.html")
      puts "Downloading section index (page #{i+1})..." if options[:mute].nil?
      File.open("#{section_name}/index#{i+1}.html", ?w) { |f|
        f.write tmp.to_s
      }
    end
  }

  # Do what you want with topics

  # ---

  # Following blocks of code can require *MORE* time and bandwidth usage!

  tmp = []
  # Getting all the pages of each topic
  topics.each_with_index { |topic, i|
      puts "Fetching topics page: #{i+1}/#{topics.length}..." if options[:mute].nil?
      
      next unless topic[:url].first.page_exists? '//ul[@class = "pages"]//li'
      page = Nokogiri::HTML(open(topic[:url].first)).xpath('//ul[@class = "pages"]//li').first
      
      latest = 15
      n = page.to_s.get_last_parentheses.to_i - 1
      1.upto(n) do
        topic[:url] << "#{topic[:url].first}&st=#{latest}"
        latest += 15
      end
  }
    
  # Backupping
  if options[:backup]
    
    topics.each_with_index { |topic, i|
      puts "Downloading topic: #{i+1}/#{topics.length}..." if options[:mute].nil?
      
      Dir::mkdir("#{section_name}/#{topic[:title].to_filename}") unless File.directory? "#{section_name}/#{topic[:title].to_filename}"
      
      topic[:url].each_with_index { |u, i|
        next if !options[:overwrite] && File.exists?("#{section_name}/#{topic[:title].to_filename}/#{i + 1}.html")
        next unless u.page_exists?
        File.open("#{section_name}/#{topic[:title].to_filename}/#{i + 1}.html", ?w) { |f|
          f.write Nokogiri::HTML(open(u)).to_s
        }
      }
    }
  end

  if options[:backup]
    puts "\t\t\t--- Fetched and saved #{topics.length} topics in #{pages.length} pages on #{section_name} ---"
  else
    puts "\t\t\t--- Fetched #{topics.length} topics in #{pages.length} pages on #{section_name} ---"
    puts
    puts '----------------------------'
    # Printing all the topics of a section.
    
    topics.each { |t|
      
      puts "Date:\t#{t[:date]}"
      puts "Title:\t#{t[:title]}"
      puts "URL:\t#{t[:url].join("\n\t")}"
      puts
    }
    puts '----------------------------'
  end
  
  puts
}
