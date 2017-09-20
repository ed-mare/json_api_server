# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'simple_json_api/version'

Gem::Specification.new do |spec|
  spec.name          = 'simple_json_api'
  spec.version       = SimpleJsonApi::VERSION
  spec.authors       = ['ed.mare']

  spec.summary       = 'Implements JSON API 1.0 - data, errors, meta, pagination, sort, ' \
                        'filters, sparse fieldsets and inclusion of related resources.'
  spec.description   = 'For building JSON APIs.'
  spec.homepage      = 'https://github.com/ed-mare/simple_json_api'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.1'

  spec.rdoc_options += ['--main', 'README.md', '--exclude', 'spec', '--exclude', 'bin', '--exclude', 'Dockerfile',
                        '--exclude', 'Gemfile', '--exclude', 'Gemfile.lock', '--exclude', 'Rakefile']

  spec.add_dependency 'oj', '~> 3.0'
  spec.add_dependency 'railties', '>= 5.0'
  spec.add_dependency 'activesupport', '>= 5.0'
  spec.add_dependency 'will_paginate', '~> 3.1.0' # for Rails 3+, Sinatra, and Merb

  spec.add_development_dependency 'bundler', '>= 1.13'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'rake', '>= 10.0'
  spec.add_development_dependency 'rspec', '>= 3.0'
  spec.add_development_dependency 'rails', '>= 4.1'
  spec.add_development_dependency 'rspec-rails', '>= 3.5'
  spec.add_development_dependency 'rubocop', '>= 0.47'
end
