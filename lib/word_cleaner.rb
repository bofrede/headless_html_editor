# MS Word specific HTML cleaning.
module WordCleaner
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
    rebuild_toc if options[:rebuild_toc]
    # Remove empty paragraphs
    @dom.css('p').each do |p|
      if p.content.gsub("\uC2A0", '').strip.size == 0 && !p.at_css('img')
        puts 'Removing empty paragraph.'
        p.remove
      end
    end
    @dom.css('table + br').remove
  end

  def rebuild_toc
    # Remove page numbers from TOC
    @dom.css('.MsoToc1 a, .MsoToc2 a, .MsoToc3 a, .MsoToc4 a').each do |item|
      item.inner_html = item.inner_text.sub(/\A(\d+\.)+/, '').sub(/(\s+\d+)\Z/, '').strip
    end
    # Rewrite Toc as ordered list.
    toc_item = @dom.at_css('.MsoToc1')
    previous_toc_level = 0
    new_toc = []
    loop do
      break if toc_item.nil?
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
      loop do
        toc_item = toc_item.next_element
        breake unless toc_item && toc_item.text?
      end
      toc_item = nil unless toc_item && toc_item.attr('class') && toc_item.attr('class').start_with?('MsoToc')
    end
    @dom.at_css('.MsoToc1').replace(new_toc.join('')) if @dom.at_css('.MsoToc1')
    # Remove old Table of Contents
    @dom.css('.MsoToc1, .MsoToc2, .MsoToc3, .MsoToc4').each { |item| item.remove }
  end

  # Remove ins and del tags added by MS Words Change Tracking.
  def accept_word_changes_tracked
    @dom.css('del').remove
    @dom.css('ins').each do |ins|
      ins.replace ins.inner_html
    end
  end
end