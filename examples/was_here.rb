#!/usr/bin/env ruby
require 'headless_html_editor'

editor = HeadlessHtmlEditor.new(File.expand_path(ARGV[0]))
editor.dom.at_css('html').add_child '<!-- HeadlessHtmlEditor was here! -->'
editor.save!
