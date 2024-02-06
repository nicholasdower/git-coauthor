# frozen_string_literal: true

require 'fileutils'
require 'optparse'
require 'set'
require 'yaml'

require_relative 'git'
require_relative 'version'

module GitCoauthor
  class CLI
    TEMPLATE_FILE_NAME = '.git-coauthors-template'
    CONFIG_FILE_NAME = '.git-coauthors'

    attr_reader :argv, :stdout, :stderr, :options, :parser

    def initialize(argv = ARGV, stdout = $stdout, stderr = $stderr)
      @argv = argv
      @stdout = stdout
      @stderr = stderr
      @options = {
        add: false, list: false, delete: false, session: false, config: false, global: false
      }
      @parser = OptionParser.new do |opts|
        opts.banner = <<~DOC
          Manages Git coauthors.

          Usage: git coauthor <args>

          Installation:
            brew tap nicholasdower/formulas
            brew install git-coauthor

          Uninstallation:
            brew uninstall git-coauthor
            brew untap nicholasdower/formulas

          Example Usage:
              git coauthor alias...                                   # Add one or more coauthors to the previous commit
              git coauthor                                            # List the coauthors on the previous commit
              git coauthor --delete                                   # Delete all coauthors from the previous commit
              git coauthor --delete alias...                          # Delete one or more coauthors from the previous commit

              git coauthor --config "alias: Name <email>"...          # Add a coauthor to the local config
              git coauthor --config --global "alias: Name <email>"... # Add a coauthor to the global config
              git coauthor --config                                   # List the local config
              git coauthor --config --global                          # List the global config
              git coauthor --config --delete                          # Delete the local config
              git coauthor --config --delete --global                 # Delete the global config
              git coauthor --config --delete alias...                 # Delete one or more coauthors from the local config
              git coauthor --config --delete --global alias...        # Delete one or more coauthors from the global config

              git coauthor --session alias...                         # Add one or more coauthors to the current session
              git coauthor --session                                  # List the coauthors in the current session
              git coauthor --session --delete                         # Delete the current session
              git coauthor --session --delete alias...                # Delete one or more coauthors from the current session

          Options:
        DOC

        opts.on('-d', '--delete', 'Delete coauthors') do
          @options[:delete] = true
        end

        opts.on('-s', '--session', 'Updat, delete or print  session') do
          @options[:session] = true
        end

        opts.on('-c', '--config', 'Update, delete or print configuration') do
          @options[:config] = true
        end

        opts.on('-g', '--global', 'Update or print the global coauthor configuration') do
          @options[:global] = true
        end

        opts.on('-v', '--version', 'Print version') do
          stdout.puts("git-coauthor version #{GitCoauthor::VERSION}")
          Kernel.exit(0)
        end

        opts.on('-h', 'Print help') do
          stdout.puts(parser.help)
          Kernel.exit(0)
        end
      end
    end

    def run
      parser.parse!(argv)

      case params
      when %i[config add args]
        # git coauthor --config "foo: Foo <foo@bar.com>"
        argv.each do |arg|
          parts = arg.split(':').map(&:strip)
          fail('fatal: invalid config') unless parts.size == 2

          repo_config[parts[0]] = parts[1]
        end
        write_config(repo_file, repo_config)
        print_config(CONFIG_FILE_NAME, repo_config)
      when %i[config add global args]
        # git coauthor --config --global "foo: Foo <foo@bar.com>"
        argv.each do |arg|
          parts = arg.split(':').map(&:strip)
          fail('fatal: invalid config') unless parts.size == 2

          user_config[parts[0]] = parts[1]
        end
        write_config(user_file, user_config)
        print_config(user_file, user_config)
      when %i[config list]
        # git coauthor --config
        print_config(CONFIG_FILE_NAME, repo_config)
      when %i[config list global]
        # git coauthor --config --global
        print_config(user_file, user_config)
      when %i[config delete]
        # git coauthor --config --delete
        File.write(repo_file, "\n")
        print_config(CONFIG_FILE_NAME, {})
      when %i[config delete global]
        # git coauthor --config --delete --global
        File.write(user_file, "\n")
        print_config(user_file, {})
      when %i[config delete args]
        # git coauthor --config --delete foo
        config = repo_config.reject { |k, _| argv.include?(k) }
        write_config(repo_file, config)
        print_config(CONFIG_FILE_NAME, config)
      when %i[config delete global args]
        # git coauthor --config --delete --global foo
        config = user_config.reject { |k, _| argv.include?(k) }
        write_config(user_file, config)
        print_config(user_file, config)
      when %i[default add args]
        # git coauthor foo
        previous_message = commit_message('HEAD')
        msg_without_coauthors = without_coauthors(previous_message)
        coauthors_to_add = args_as_coauthors
        previous_coauthors = previous_message.split("\n").select { _1.match(/^Co-authored-by:.*/) }
        coauthors = Set.new(previous_coauthors + coauthors_to_add).to_a.sort
        message = "#{msg_without_coauthors}\n#{coauthors.join("\n")}\n"
        amend_commit_message(message)
        stdout.puts('Commit:')
        coauthors.each { stdout.puts("  #{_1}") }
      when %i[default list]
        # git coauthor
        message = commit_message('HEAD')
        stdout.puts('Commit:')
        message.scan(/^ *Co-authored-by:.*$/).sort.map { stdout.puts("  #{_1}") }
      when %i[default delete]
        # git coauthor --delete
        message = without_coauthors(commit_message('HEAD'))
        amend_commit_message(message)
        stdout.puts('Commit:')
      when %i[default delete args]
        # git coauthor --delete foo
        previous_message = commit_message('HEAD')
        msg_without_coauthors = without_coauthors(previous_message)
        to_remove = args_as_coauthors
        previous_coauthors = previous_message.split("\n").select { _1.match(/^Co-authored-by:.*/) }
        coauthors = previous_coauthors - to_remove
        message = if coauthors.any?
                    "#{msg_without_coauthors}\n#{coauthors.join("\n")}\n"
                  else
                    msg_without_coauthors
                  end
        amend_commit_message(message)
        stdout.puts('Commit:')
        coauthors.each { stdout.puts("  #{_1}") }
      when %i[session add args]
        # git coauthor --session foo
        success, template_path = Git.config_get('commit.template')

        coauthors = args_as_coauthors
        existing_template = ['', '']

        if success && template_path != TEMPLATE_FILE_NAME
          fail("fatal: commit template not found: #{template_path}") unless File.exist?(template_path)

          existing_template = File.read(template_path).split("\n")
          success = Git.config_set('commit.template.backup', template_path)
          fail("fatal: failed to set commit.template.backup to #{template_path}") unless success

          existing_template << '' while existing_template.size < 2
        elsif success && template_path == TEMPLATE_FILE_NAME
          fail("fatal: commit template not found: #{template_path}") unless File.exist?(template_path)

          existing_template = File.read(template_path).split("\n")
          previous_coauthors = existing_template.select { _1.match(/^Co-authored-by:.*/) }
          existing_template = existing_template.reject { _1.match(/^Co-authored-by:.*/) }
          coauthors = Set.new(coauthors + previous_coauthors).to_a
        end

        coauthors = coauthors.sort
        template = existing_template + coauthors
        File.write(TEMPLATE_FILE_NAME, "#{template.join("\n")}\n")
        success = Git.config_set('commit.template', TEMPLATE_FILE_NAME)
        fail('fatal: cannot set git commit template') unless success

        stdout.puts('Session:')
        coauthors.each { stdout.puts("  #{_1}") }
      when %i[session list]
        # git coauthor --session
        success, template_path = Git.config_get('commit.template')
        unless success && template_path == TEMPLATE_FILE_NAME
          stdout.puts('Session:')
          Kernel.exit(0)
        end
        fail("fatal: git commit template not exist: #{template_path}") unless File.exist?(template_path)

        template = File.read(template_path).strip
        coauthors = template.split("\n").select { _1.match(/^Co-authored-by:.*/) }.sort
        stdout.puts('Session:')
        coauthors.each { stdout.puts("  #{_1}") }
      when %i[session delete]
        # git coauthor --session --delete
        success, template_path = Git.config_get('commit.template')
        delete_session(template_path) if success && template_path == TEMPLATE_FILE_NAME
        stdout.puts('Session:')
      when %i[session delete args]
        # git coauthor --session --delete foo
        _, template_path = Git.config_get('commit.template')
        unless template_path == TEMPLATE_FILE_NAME
          stdout.puts('Session:')
          Kernel.exit(0)
        end

        unless File.exist?(TEMPLATE_FILE_NAME)
          delete_session(TEMPLATE_FILE_NAME)
          stdout.puts('Session:')
          Kernel.exit(0)
        end

        to_remove = args_as_coauthors
        template = File.read(template_path).strip
        previous_coauthors = template.split("\n").select { _1.match(/^Co-authored-by:.*/) }
        coauthors = previous_coauthors - to_remove
        if coauthors.any?
          File.write(template_path, "\n\n#{coauthors.join("\n")}\n")
        else
          delete_session(template_path)
        end
        stdout.puts('Session:')
        coauthors.each { stdout.puts("  #{_1}") }
      else
        fail('fatal: unexpected arguments or options')
      end

      Kernel.exit(0)
    rescue OptionParser::ParseError => e
      fail("fatal: #{e}")
    end

    private

    def commit_message(sha)
      success, message = Git.commit_message(sha)
      fail('fatal: cannot read the previous commit message') unless success

      message
    end

    def amend_commit_message(message)
      success = Git.amend_commit_message(message)
      fail('fatal: cannot amend the previous commit message') unless success
    end

    def params
      [
        entity,
        action,
        options[:global] ? :global : nil,
        argv.any? ? :args : nil
      ].compact
    end

    def entity
      case [options[:session], options[:config]]
      when [true, false]
        :session
      when [false, true]
        :config
      when [false, false]
        :default
      else
        fail('fatal: unexpected arguments or options')
      end
    end

    def action
      case [options[:delete], argv.any?]
      when [true, false], [true, true]
        :delete
      when [false, true]
        :add
      when [false, false]
        :list
      else
        fail('fatal: unexpected arguments or options')
      end
    end

    def fail(message)
      stderr.puts(message)
      Kernel.exit(1)
    end

    def user_file
      @user_file ||= File.join(Dir.home, CONFIG_FILE_NAME)
    end

    def repo_file
      @repo_file ||= File.join(Dir.pwd, CONFIG_FILE_NAME)
    end

    def user_config
      @user_config ||= File.exist?(user_file) ? YAML.safe_load_file(user_file) || {} : {}
    end

    def repo_config
      @repo_config ||= File.exist?(repo_file) ? YAML.safe_load_file(repo_file) || {} : {}
    end

    def config
      @config ||= {}.merge(user_config).merge(repo_config)
    end

    def without_coauthors(commit_message)
      "#{commit_message.split("\n").reject { _1.match(/^ *Co-authored-by:.*$/) }.join("\n").strip}\n"
    end

    def args_as_coauthors
      return @args_as_coauthors if @args_as_coauthors

      raise 'internal error: no args' if argv.empty?

      @args_as_coauthors = argv.map do |arg|
        fail("fatal: invalid coauthor: #{arg}") unless config[arg]

        "Co-authored-by: #{config[arg]}"
      end
    end

    def write_config(file, config)
      File.write(file, config.sort.to_h.map { |k, v| "#{k}: #{v}" }.join("\n") + "\n")
    end

    def print_config(file, config)
      stdout.puts("#{file}:")
      max_short = config.map { |short, _| short.size }.max
      config.sort.to_h.each do |short, long|
        short += ':'
        stdout.puts("  #{short.ljust(max_short + 1)} #{long}")
      end
    end

    def delete_session(template_path)
      success, backup_template_path = Git.config_get('commit.template.backup')
      if success
        success = Git.config_set('commit.template', backup_template_path)
        fail('fatal: failed to set git commit template backup') unless success

        success = Git.config_unset('commit.template.backup')
        fail('fatal: failed to unset git commit template backup') unless success
      else
        success = Git.config_unset('commit.template')
        fail('fatal: failed to unset git commit template') unless success
      end
      FileUtils.rm_f(template_path)
    end
  end
end
