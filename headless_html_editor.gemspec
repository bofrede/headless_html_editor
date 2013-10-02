# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'headless_html_editor/version'

Gem::Specification.new do |spec|
  spec.name          = 'headless_html_editor'
  spec.version       = HeadlessHtmlEditor::VERSION
  spec.authors       = ['Bo Frederiksen']
  spec.email         = ['bofrede@bofrede.dk']
  spec.description   = 'Headless HTML Editor - edit HTML files, without a UI.'
  spec.summary       = ''
  spec.homepage      = ''
  spec.license       = 'MIT'
  spec.files         = ['lib/headless_html_editor.rb']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']
  spec.add_dependency 'nokogiri', '>= 1.6.0'
  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
