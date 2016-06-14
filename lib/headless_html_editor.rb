#!/usr/bin/env ruby
# coding: utf-8
# rubocop:disable LineLength, MethodLength

begin
  require 'nokogiri'
rescue LoadError => le
  $stderr.puts "LoadError: #{le.message}"
  $stderr.puts 'Run: gem install nokogiri'
  exit
end
require_relative 'word_cleaner'

# Headless HTML Editor. Edit HTML files programmatically.
class HeadlessHtmlEditor
  attr_reader :dom

  include ::WordCleaner

  # Create a new Headless HTML Editor.
  def initialize(input_file_name, input_encoding = 'utf-8')
    @input_file_name = input_file_name
    if File.file?(input_file_name) && File.fnmatch?('**.html', input_file_name, File::FNM_CASEFOLD)
      # read html file
      puts "R: #{input_file_name}"
      @dom = Nokogiri::HTML(
        open(input_file_name, "r:#{input_encoding}", universal_newline: false)
      )
    end
  end

  # Remove script tags from the header
  def remove_header_scripts
    @dom.css('head script').remove
  end

  # Change h1 to h2 and so on. h6 is not changed, so its a potential mess.
  def demote_headings
    @dom.css('h1, h2, h3, h4, h5').each do |heading|
      heading.name = "h#{heading.name[1].to_i + 1}"
    end
  end

  def remove_break_after_block
    block_tags = %w{h1 h2 h3 h4 h5 h6 p div table}
    @dom.css(block_tags.join(' + br, ') + ' + br').remove
  end

  # Save the file with the same file name.
  def save!(output_encoding = 'utf-8')
    save_as!(@input_file_name, output_encoding)
  end

  # Save file with a new file name.
  def save_as!(output_file_name, output_encoding = 'utf-8')
    puts "W: #{output_file_name}"
    begin
      if File.writable?(output_file_name) || !File.exist?(output_file_name)
        File.open(output_file_name, "w:#{output_encoding}", universal_newline: false) do |f|
          f.write @dom.to_html(encoding: output_encoding, indent: 2)
        end
      else
        $stderr.puts 'Failed: Read only!'
      end
    rescue StandardError => se
      $stderr.puts "\nFailed!\n#{se.message}"
    end
  end

  # Edit all HTML files in a folder.
  def self.edit_folder(folder, &block)
    Dir.open(folder.gsub(/\\/, '/')) do |d|
      d.each do |file_name|
        file_name = File.join(d.path, file_name)
        if File.file? file_name
          editor = new(file_name)
          unless editor.dom.nil?
            yield editor
            editor.save!
          end
        end
      end
    end
  end

  # Edit files listed in a text file. File names are absolute.
  # If the first character on a line is # the line is ignored.
  def self.bulk_edit(file_list_file_name, &block)
    txt_file_name = File.expand_path(file_list_file_name)
    File.readlines(txt_file_name).each do |file_name|
      unless file_name.start_with? '#'
        # Strip added to remove trailing newline characters.
        file_name.strip!
        if File.file? file_name
          editor = new(file_name)
          if editor.dom.nil?
            puts "No DOM found in #{file_name}."
          else
            yield editor
            editor.save!
          end
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  HeadlessHtmlEditor.edit_folder(File.expand_path(ARGV[0])) do |editor|
    editor.dom.at_css('html').add_child '<!-- HeadlessHtmlEditor was here! -->'
  end
end
