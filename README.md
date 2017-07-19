# HeadlessHtmlEditor
[![Gem Version](https://badge.fury.io/rb/headless_html_editor.png)](http://badge.fury.io/rb/headless_html_editor)
[![Build Status](https://secure.travis-ci.org/bofrede/headless_html_editor.png?branch=master)](http://travis-ci.org/bofrede/headless_html_editor)

Headless HTML Editor - edit HTML files, without a UI.

## Installation

Add this line to your application's Gemfile:

    gem 'headless_html_editor'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install headless_html_editor

## Usage
    require 'headless_html_editor'

    editor = HeadlessHtmlEditor.new(File.expand_path(ARGV[0]))
    editor.dom.at_css('html').add_child '<!-- HeadlessHtmlEditor was here! -->'
    editor.save!

See the nokogiri documentation for documentation on the dom object.

## Contributing

1. Fork it.
2. Create your feature branch. `git checkout -b my-new-feature`
3. Commit your changes. `git commit -am 'Add some feature'`
4. Push to the branch. `git push origin my-new-feature`
5. Create new Pull Request.
