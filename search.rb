#!/usr/bin/env ruby
require 'trollop'
require 'mechanize'
require 'nokogiri'
require 'uri'
require 'ap'

class Mechanize::Page
  def resolve_url(url)
    if url.nil?
      url = []
    end
    mech.agent.resolve(url,self).to_s
  end
end

module Scrape
	class Search
		def initialize opts = {}
			@options = opts
			@agent = new_agent_with_default_attributes
			@queries = @options[:query]
			@queries.each do |q|
				page = self.search q
				self.parse page
			end
		end

		def search query 
			page = @agent.get("http://torrentz.eu/search?f=#{query}")
			return page
		end

		def parse page
			page.search('/html/body/div[3]/dl/dt/a').map do |link|
				url = page.resolve_url(link[:href])
				grab @agent.get(url), link.text
			end
		end

		def grab page, title
			ap title = title.gsub(/ /,"_")
			page.search('/html/body/div[3]/dl/dt/a').map do |link|
				if link.to_s.include?('torlock')
					site = @agent.get(link[:href])
					torrent = site.search('td a')
					begin
						Thread.new {system("wget #{torrent[4][:href]} -O #{title}.torrent")}
					rescue
						ap torrent
					end
				end
			end
		end

		def new_agent_with_default_attributes
		    agent = Mechanize.new
		    agent.user_agent = @options[:ua] ||= 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_4) AppleWebKit/536.11 (KHTML, like Gecko) Chrome/20.0.1132.43 Safari/536.11'
		    agent.open_timeout = 300
		    agent.read_timeout = 300
		    agent.html_parser = Nokogiri::HTML
		    agent.ssl_version = 'SSLv3'
		    agent.keep_alive = true
		    agent.idle_timeout = 300
		    agent.max_history = 10
		    return agent
		  end
	end
end

opts = Trollop::options do
  banner = ":Usage =>ruby search.rb -q tv [options]" 
  opt :query, "Set what it is you want to search for", :type => :strings
  opt :pages, "Set the number of pages deep you want to go", :default => 1
  opt :ua, "Set a custom user agent. Ex:-ua Googlebot"
end

Scrape::Search.new(opts)

