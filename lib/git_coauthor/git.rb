# frozen_string_literal: true

require 'English'
require 'open3'

module GitCoauthor
  class Git
    def self.commit_message(sha)
      message = `git log --format="%B" --max-count=1 #{sha} 2> /dev/null`
      [$CHILD_STATUS.success?, message]
    end

    def self.amend_commit_message(message)
      Open3.popen2('git commit --amend --only --no-verify --file -') do |stdin, _, wait_thr|
        stdin.puts(message)
        stdin.close
        wait_thr.value.success?
      end
    end

    def self.config_get(key)
      value = `git config #{key} 2> /dev/null`.strip
      [$CHILD_STATUS.success?, value]
    end

    def self.config_set(key, value)
      `git config #{key} #{value} 2> /dev/null`
      $CHILD_STATUS.success?
    end

    def self.config_unset(key)
      `git config --unset #{key} 2> /dev/null`
      $CHILD_STATUS.success?
    end
  end
end
