# frozen_string_literal: true

require_relative 'lib/git_coauthor/version'

Gem::Specification.new do |spec|
  spec.name = 'git-coauthor'
  spec.description = 'Git Coauthor'
  spec.summary = 'CLI used to manage Git coauthors'
  spec.homepage = 'https://github.com/nicholasdower/git-coauthor'
  spec.version = GitCoauthor::VERSION
  spec.license = 'MIT'
  spec.authors = ['Nick Dower']
  spec.email = 'nicholasdower@gmail.com'
  spec.files = Dir['lib/**/*.rb'] + Dir['bin/*']
  spec.bindir = 'bin'
  spec.metadata = {
    'bug_tracker_uri' => 'https://github.com/nicholasdower/git-coauthor/issues',
    'changelog_uri' => "https://github.com/nicholasdower/git-coauthor/releases/tag/v#{GitCoauthor::VERSION}",
    'documentation_uri' => "https://www.rubydoc.info/github/nicholasdower/git-coauthor/v#{GitCoauthor::VERSION}",
    'homepage_uri' => 'https://github.com/nicholasdower/git-coauthor',
    'rubygems_mfa_required' => 'true',
    'source_code_uri' => 'https://github.com/nicholasdower/git-coauthor'
  }
  spec.required_ruby_version = '>= 2.7.0'
end
