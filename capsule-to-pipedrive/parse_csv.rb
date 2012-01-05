#!/usr/bin/ruby
require 'csv'

class Person
  attr_reader :first_name, :last_name, :orginization

  def initialize(first, last, org)
    @first_name, @last_name, @orginization = first, last, org
  end

  def to_s
    @first_name + " " + @last_name
  end
end

class Update
  attr_reader :type, :content, :person

  def initialize(type, content, person)
    @type, @content, @person = type, content, person
  end
end

def readFile
  first = true

  CSV.foreach("contacts.csv") do |row|
    if first
      first = false
      next
    end

    unless row.last.eql? nil or (row[3].nil? or row[3].empty?) or (row[4].nil? or row[4].empty?)
      person = Person.new(row[3], row[4], row[6].to_s)
      puts person
      handle_updates person, row.last.split(/=== (\w+) ===/)
    end
  end
end

def handle_updates person, updates
  updates = updates.drop 1 # first item in updates is an empty string

  while not updates.first.instance_of? Update
    parts = updates.slice!(0, 2)
    updates.push Update.new(parts.first, parts.last, person)
  end

  updates.each do |update|
    handle_update update
  end
end

def handle_update update
end

readFile
