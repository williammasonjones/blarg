require "blarg/version"
require 'pry'

BLOG_REPO = '/Users/brit/projects/improvedmeans/'

module Blarg
  module Models
  end
end


class PostImporter
  include Enumerable

  def initialize(posts_dir)
    @posts_dir = posts_dir
  end

  # NOTE: Trailing slash matters here.
  def each
    Dir.glob(@posts_dir + '*.post').each { |post| yield post }
  end

  def parse_post(file)
    result = {}
    File.open(file, 'r') do |f|
      result = parse_header(f)
      result[:text] = f.read
      result[:tags].split(', ')
    end
    result
  end

  private
  def marker?(line)
    line.chomp == ';;;;;'
  end

  def parse_header(fd)
    result = {}
    unless marker?(fd.readline)
      raise "The file '#{file}' does not have a valid header."
    end
    line = fd.readline
    until marker?(line)
      key, val = parse_metadata(line)
      result[key.to_sym] = val
      line = fd.readline
    end
    result
  end

  def parse_metadata(line)
    matcher = /^([a-zA-Z]+):\s+(.*)$/
    matches = line.match(matcher)
    return matches[1], matches[2]
  end
end

class BlogApp
  private
  def prompt(question, validator, error_msg, clear: nil)
    `clear` if clear
    puts "\n#{question}\n"
    result = gets.chomp
    until result =~ validator
      puts "\n#{error_msg}\n"
      result = gets.chomp
    end
    exit if result == 'QUIT'
    puts
    result
  end
end
