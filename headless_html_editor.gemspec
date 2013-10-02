# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'headless_html_editor'
  spec.version       = '0.0.1'
  spec.authors       = ['Bo Frederiksen']
  spec.email         = ['bofrede@bofrede.dk']
  spec.summary       = 'Headless HTML Editor - edit HTML files, without a UI.'
  spec.description   = 'Headless HTML Editor - edit HTML files, without a UI.'
  spec.homepage      = 'https://github.com/bofrede/headless_html_editor'
  spec.license       = 'MIT'
  spec.files         = ['lib/headless_html_editor.rb']
  spec.require_paths = ['lib']
  spec.add_dependency 'nokogiri', '>= 1.6.0'
  spec.add_development_dependency 'rake'
end
