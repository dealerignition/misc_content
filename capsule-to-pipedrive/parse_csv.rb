#!/usr/bin/ruby
require 'csv'
require './bi/lib/binary_search/pure'
require 'net/http'
require 'net/https'

def stringCompare str1, str2
	str1.downcase! 
	pairs1 = (0..str1.length-2).collect {|i| str1[i,2]}.reject {
	  |pair| pair.include? " "}
	str2.downcase! 
	pairs2 = (0..str2.length-2).collect {|i| str2[i,2]}.reject {
	  |pair| pair.include? " "}
	union = pairs1.size + pairs2.size 
	intersection = 0 

	pairs1.each do |p1| 
	  0.upto(pairs2.size-1) do |i| 
		if p1 == pairs2[i] 
		  intersection += 1 
		  pairs2.slice!(i) 
		  break 
		end 
	  end 
	end 

	(2.0 * intersection) / union
end

class DataMover
  class Update
    attr_reader :type, :content, :org_id

    def initialize(type, content, org)
      @type, @content, @org_id = type, content, org
    end

    def push_to_pipedrive connection, headers
      content = @type.capitalize + ":\n" + @content
      data =  
        '&comment[item_type]=org' +
        '&comment[item_id]=' + org_id.to_s +
        '&comment[content]=' + content
      resp, data = connection.post('/comments/add', data, headers)
      puts org_id
      puts resp.code

      unless resp.code.to_i.eql? 302
        puts "We have a problem."
        gets
      end
    end
  end

  def connect_to_pipedrive 
    # Connect to Pipedrive
    @con = Net::HTTP.new('app.pipedrive.com', 443)
    @con.use_ssl = true

    # Login to Pipedrive
    path = '/auth/login'
    resp, data = @con.get(path) # Set cookies
    cookie = resp.response['set-cookie']

    data = 'login=luke%2bauto@dealerignition.com&password=thisisacomputer'

    @headers = {
      'Cookie' => cookie,
      'Content-Type' => 'application/x-www-form-urlencoded'
    }

    resp, data = @con.post(path, data, @headers)
  end

  def handle_updates org_id, updates
    updates = updates.drop 1 # first item in updates is an empty string

    while not updates.first.instance_of? Update
      parts = updates.slice!(0, 2)
      updates.push Update.new(parts.first, parts.last, org_id)
    end

    updates.each do |update|
      update.push_to_pipedrive @con, @headers
    end
  end

  def find_org_id name
    r = @orgs.binary_index(name)
    return @ids[r.last] if r.first

    # Check around correct alphabetical location
    start = [r.last-2, 0].max
    finish = [r.last+2, @orgs.size-1].min

    top = [-1, 0]
    start.upto(finish).each do |i|
      score = stringCompare @orgs[i].downcase, name.downcase
      score += 0.3 if @orgs[i].downcase.include? name.downcase \
                      or name.downcase.include? @orgs[i].downcase
      top[0], top[1] = i, score if score > top[1]
    end

    # There were no matches.
    return nil if top.first.eql? -1

    # There was a 90% or better match.
    id = top.first
    return @ids[id] if top.last > 0.9

    # Check the whole list
    @orgs.each do |o|
      score = stringCompare o.downcase, name.downcase
      score += 0.3 if o.downcase.include? name.downcase \
                      or name.downcase.include? o.downcase
      top[0], top[1] = o, score if score > top[1]
      break if top.last > 0.93
    end

    # There were no good matches.
    return nil unless top.last > 0.9

    # There was a 90% or better match.
    id = @orgs.index top.first
    return @ids[id]
  end

  def run
    # open orgs file
    @ids = []
    @orgs = []

    first = true
    CSV.foreach("orgs.csv") do |row|
      if first
        first = false
        next
      end

      @ids.push row.first.to_i
      @orgs.push row[1]
    end
    @orgs.sort

    connect_to_pipedrive

    # Open and parse csv data file
    first = true
    CSV.foreach("contacts.csv") do |row|
      if first
        first = false
        next
      end

      i = 0
      unless row.last.eql? nil or (row[6].nil? or row[6].empty?)
        org_id = find_org_id row[6]
        handle_updates org_id, row.last.split(/=== (\w+) ===/) unless org_id.nil?
        i += 1
        puts i
      end
    end
  end
end

DataMover.new().run
