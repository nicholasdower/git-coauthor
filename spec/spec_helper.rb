# frozen_string_literal: true

if ENV['COVERAGE'] == '1'
  require 'simplecov'
  require 'simplecov-console'

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
    [SimpleCov::Formatter::HTMLFormatter, SimpleCov::Formatter::Console]
  )

  SimpleCov.start do
    enable_coverage :branch
    minimum_coverage line: 100, branch: 100
    add_filter %w[spec/ lib/git_coauthor/git.rb]
  end
end

require_relative '../lib/git_coauthor/cli'
