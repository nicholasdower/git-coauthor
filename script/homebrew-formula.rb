#!/usr/bin/env ruby
# frozen_string_literal: true

require 'English'

raise('fatal: you must set VERSION') unless ENV['VERSION']

raise('fatal: you must specify a version') unless ENV['VERSION'].size == 1

version = ENV.fetch('VERSION')
raise('fatal: invalid version') unless version.match?(/^[1-9][0-9]*$/)

url = "https://github.com/nicholasdower/git-coauthor/archive/v#{version}.tar.gz"
`curl --silent -L -o release.tar.gz #{url} >/dev/null`
raise('fatal: failed to download') unless $CHILD_STATUS.success?

sha = `shasum -a 256 release.tar.gz | cut -d' ' -f1`.strip
raise('fatal: failed to generate sha') unless $CHILD_STATUS.success?

formula = format(File.read('Formula/template.txt'), version: version, url: url, sha: sha)
File.write('Formula/git-coauthor.rb', formula)
