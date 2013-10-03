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

# Headless HTML Editor. Edit HTML files programmatically.
class HeadlessHtmlEditor
  attr_reader :dom

  # Create a new Headless HTML Editor.
  def initialize(input_file_name, input_encoding = 'utf-8')
    @input_file_name = input_file_name
    if File.file?(input_file_name) && File.fnmatch?('**.html', input_file_name)
      # read html file
      puts "R: #{input_file_name}"
      @dom = Nokogiri::HTML(
        open(input_file_name, "r:#{input_encoding}", universal_newline: false)
      )
    end
  end

  UNWANTED_CLASSES = %w{MsoNormal MsoBodyText NormalBold MsoTitle MsoHeader Templatehelp
                        TOCEntry Indent1 MsoCaption MsoListParagraph
                        MsoNormalTable MsoTableGrid MsoTableClassic1
                        MsoListParagraphCxSpFirst MsoListParagraphCxSpMiddle MsoListParagraphCxSpLast
                        MsoCommentText msocomtxt msocomoff MsoEndnoteText MsoFootnoteText}

  # Cleanup after MS Word.
  def remove_word_artifacts(options = { rebuild_toc: true })
    @dom.css('meta[name="Generator"]').remove
    # Remove abandoned anchors, that are not linked to.
    @dom.css('a[name]').each do |a|
      if @dom.css('a[href="#' + a['name'] + '"]').size == 0
        puts "<a name=\"#{a['name']}\"> was removed, because it had no links to it."
        a.replace(a.inner_html)
      end
    end
    # Clean up h1-h6 tags
    headings = @dom.css('h1, h2, h3, h4, h5, h6')
    headings.each do |heading|
      a = heading.at_css('a[name]')
      if a
        heading['id'] = a['name'].sub(/_Toc/, 'Toc')
        a.replace(a.inner_html)
      end
      heading.inner_html = heading.inner_html.sub(/\A(\s*\d+\.?)+\uC2A0*/, '').strip
    end
    # Remove Words "normal" classes.
    UNWANTED_CLASSES.each do |class_name|
      @dom.css(".#{class_name}").each do |node|
        node.remove_attribute('class')
      end
    end
    # Remove unwanted section tags
    @dom.css('.WordSection1, .WordSection2, .WordSection3, .WordSection4, .WordSection5, .WordSection6, .WordSection7, .WordSection8').each do |section|
      puts "Removing #{section.name}.#{section['class']}"
      section.replace(section.inner_html)
    end
    if options[:rebuild_toc]
      # Remove page numbers from TOC
      @dom.css('.MsoToc1 a, .MsoToc2 a, .MsoToc3 a, .MsoToc4 a').each do |item|
        item.inner_html = item.inner_text.sub(/\A(\d+\.)+/, '').sub(/(\s+\d+)\Z/, '').strip
      end
      # Rewrite Toc as ordered list.
      toc_item = @dom.at_css('.MsoToc1')
      previous_toc_level = 0
      new_toc = []
      while toc_item
        toc_item.inner_html = toc_item.inner_html.sub(/\n/, ' ')
        class_attr = toc_item.attr('class')
        current_toc_level = class_attr[6].to_i
        new_toc << "</li>\n" if previous_toc_level == current_toc_level
        new_toc << "</ol>\n</li>\n" if previous_toc_level > current_toc_level
        new_toc << "\n<ol#{' id="toc"' if previous_toc_level == 0}>\n" if previous_toc_level < current_toc_level
        link = toc_item.at_css('a')
        if link.nil?
          puts toc_item.to_s
         else
          toc_item.at_css('a').inner_html = link.inner_html.sub(/\A(\s*\d+)/, '').strip
          new_toc << "<li>#{toc_item.inner_html.sub(/#_Toc/, '#Toc')}"
        end
        previous_toc_level = current_toc_level
        begin
          toc_item = toc_item.next_element
        end while toc_item && toc_item.text?
        toc_item = nil unless toc_item && toc_item.attr('class') && toc_item.attr('class').start_with?('MsoToc')
      end
      @dom.at_css('.MsoToc1').replace(new_toc.join('')) if @dom.at_css('.MsoToc1')
      # Remove old Table of Contents
      @dom.css('.MsoToc1, .MsoToc2, .MsoToc3, .MsoToc4').each { |item| item.remove }
    end
    # Remove empty paragraphs
    @dom.css('p').each do |p|
      if p.content.gsub("\uC2A0", '').strip.size == 0 && !p.at_css('img')
        puts 'Removing empty paragraph.'
        p.remove
      end
    end
    @dom.css('table + br').remove
  #  /<!--\[if[.\n\r]+\[endif\]\s*-->/
  end

  # Remove script tags from the header
  def remove_header_scripts
    @dom.css('head script').remove
  end

  # Remove ins and del tags added by MS Words Change Tracking.
  def accept_word_changes_tracked
    @dom.css('del').remove
    @dom.css('ins').each do |ins|
      ins.replace ins.inner_html
    end
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
      if File.writable?(output_file_name) || !File.exists?(output_file_name)
        File.open(output_file_name, "w:#{output_encoding}", universal_newline: false) do |f|
          f.write @dom.to_html({ encoding: output_encoding, indent: 2 })
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
