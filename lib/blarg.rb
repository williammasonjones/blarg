require "blarg/version"
require 'pry'

BLOG_REPO = '/Users/brit/projects/improvedmeans/'

module Blarg
  module Models
  end
end

module Promptable
  def prompt(question, validator, error_msg, clear: nil)
    `clear` if clear
    puts "\n#{question}\n"
    result = $stdin.gets.chomp
    until result =~ validator
      puts "\n#{error_msg}\n"
      result = $stdin.gets.chomp
    end
    puts
    result
  end
end

class PostImporter
  include Enumerable
  include Promptable

  def initialize(posts_dir)
    @posts_dir = posts_dir
    choices = {}
    self.each_with_index do |post, i|
      choices[i+1] = post
    end
    @choices = choices
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
      result[:date] = DateTime.parse(result[:date])
      result[:tags] = result[:tags].split(', ')
    end
    result
  end

  def choose_post
    @choices.each do |i, post|
      puts "(#{i}) -- #{File.basename(post)}"
    end
    result = prompt("Which post would you like to import from your previous blog?",
                    /^#{@choices.keys.join('|')}$/,
                    "Please choose one of the listed numeric options.")
    path = @choices[result.to_i]
    parse_post(path)
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
  include Promptable

  def initialize
    @importer = PostImporter.new BLOG_REPO
  end

  def run
    puts "Hello there. Welcome to your personal blaaaarg!"
    # TODO: Have choose method for post screen or index screen.
    post_screen
  end

  def self.quit_handler
    puts "Thanks for blarging! Goodbye!"
    exit
  end

  private
  def import_post
    more = prompt("Would you like to import another post? (yes/y, no/n, all)",
                  /^y|yes|n|no|all$/, "Please choose 'y', 'yes', 'n', 'no', or 'all'.")
    until ['n', 'no'].include?(more)
      if more == 'all'
        @importer.each do |p|
          opts = @importer.parse_post(p)
          Blarg::Models::Post.create(opts)
        end
      else
        opts = @importer.choose_post
        Blarg::Models::Post.create(opts)
      end
    end
  end

  def post_screen
    message = "Would you like to (1) write a new post, (2) import a post from another blog, (3) find an existing post, or (QUIT)?"
    choice = prompt(message, /^([123]|QUIT)$/, "Please choose 1, 2, 3, or QUIT.", clear: true)
    case choice.to_i
    when 1
      add_post
    when 2
      import_post
    when 3
      # TODO: We might want to edit or delete a post that we find.
      find_post
    else
      BlogApp.quit_handler
    end
  end

  def index_screen
    message = "Would you like to (1) view indexes by date, (2) view indexes by tag, or (QUIT)?"
    choice = prompt(message, /^([12]|QUIT)$/, "Please choose 1, 2, or QUIT.", clear: true)
    case choice.to_i
    when 1
      view_date_index
    when 2
      view_tag_index
    else
      BlogApp.quit_handler
    end
  end
end

blog = BlogApp.new
blog.run
