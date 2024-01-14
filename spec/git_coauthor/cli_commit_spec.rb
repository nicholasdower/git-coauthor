# frozen_string_literal: true

require_relative '../spec_helper'

describe 'CLI' do
  subject { cli.run }

  let(:cli) { GitCoauthor::CLI.new(argv, stdout, stderr) }
  let(:argv) { [] }
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }
  let(:user_config) { nil }
  let(:repo_config) { nil }
  let(:commit_message) { nil }

  before do
    allow(Dir).to receive(:home).and_return('/home/')
    allow(File).to receive(:exist?).with('/home/.git-coauthors').and_return(!user_config.nil?)
    allow(YAML).to receive(:safe_load_file).with('/home/.git-coauthors').and_return(user_config) if user_config

    allow(Dir).to receive(:pwd).and_return('/home/project')
    allow(File).to receive(:exist?).with('/home/project/.git-coauthors').and_return(!repo_config.nil?)
    allow(YAML).to receive(:safe_load_file).with('/home/project/.git-coauthors').and_return(repo_config) if repo_config

    allow(Kernel).to receive(:exit).with(0).and_raise(StandardError.new('success'))
    allow(Kernel).to receive(:exit).with(1).and_raise(StandardError.new('error'))

    allow(GitCoauthor::Git).to receive(:commit_message).and_return([!commit_message.nil?, commit_message])
    allow(GitCoauthor::Git).to receive(:amend_commit_message).and_return(true)
  end

  shared_examples 'success' do
    it 'does not print an error message' do
      subject rescue nil
      expect(stderr.string).to eq('')
    end

    it 'exits without an error' do
      expect { subject }.to raise_error(StandardError, 'success')
    end
  end

  shared_examples 'error' do |message|
    it 'prints an error message' do
      subject rescue nil
      expect(stderr.string).to eq(message)
    end

    it 'does not print the commit' do
      subject rescue nil
      expect(stdout.string).to eq('')
    end

    it 'exits with an error' do
      expect { subject }.to raise_error(StandardError, 'error')
    end
  end

  shared_examples 'print commit' do |commit|
    it 'prints the commit' do
      subject rescue nil
      expect(stdout.string).to eq(commit)
    end
  end

  shared_examples 'amend commit' do |message|
    it 'amends the commit' do
      expect(GitCoauthor::Git).to receive(:amend_commit_message).with(message).and_return(true)
      subject rescue nil
    end
  end

  shared_examples 'do not amend commit' do
    it 'does not amend the commit' do
      expect(GitCoauthor::Git).not_to receive(:amend_commit_message)
      subject rescue nil
    end
  end

  context 'git coauthor foo' do
    let(:commit_message) { "Foo\n\nBar\n" }
    let(:argv) { ['foo'] }

    context 'when the previous commit cannot be retrieved' do
      let(:commit_message) { nil }

      include_examples 'do not amend commit'
      include_examples 'error', "fatal: cannot read the previous commit message\n"
    end

    context 'when the config does not contain the specified alias' do
      include_examples 'do not amend commit'
      include_examples 'error', "fatal: invalid coauthor: foo\n"
    end

    context 'when the user config contains the specified alias' do
      let(:user_config) { { 'foo' => 'Foo <foo@bar.com>' } }

      include_examples 'amend commit', "Foo\n\nBar\n\nCo-authored-by: Foo <foo@bar.com>\n"
      include_examples 'print commit', "Commit:\n  Co-authored-by: Foo <foo@bar.com>\n"
      include_examples 'success'
    end

    context 'when the repo config contains the specified alias' do
      let(:repo_config) { { 'foo' => 'Foo <foo@bar.com>' } }

      include_examples 'amend commit', "Foo\n\nBar\n\nCo-authored-by: Foo <foo@bar.com>\n"
      include_examples 'print commit', "Commit:\n  Co-authored-by: Foo <foo@bar.com>\n"
      include_examples 'success'
    end

    context 'when the repo and user config contain the specified alias' do
      let(:user_config) { { 'foo' => 'Foo <foo@bar.com>' } }
      let(:repo_config) { { 'foo' => 'Bar <bar@bar.com>' } }

      include_examples 'amend commit', "Foo\n\nBar\n\nCo-authored-by: Bar <bar@bar.com>\n"
      include_examples 'print commit', "Commit:\n  Co-authored-by: Bar <bar@bar.com>\n"
      include_examples 'success'
    end

    context 'when the previous commit cannot be amended' do
      let(:user_config) { { 'foo' => 'Foo <foo@bar.com>' } }

      before do
        allow(GitCoauthor::Git).to receive(:amend_commit_message).and_return(false)
      end

      include_examples 'error', "fatal: cannot amend the previous commit message\n"
    end
  end

  context 'git coauthor foo bar' do
    let(:commit_message) { "Foo\n\nBar\n" }
    let(:argv) { %w[foo bar] }

    context 'when the config does not contain one of the specified aliases' do
      let(:user_config) { { 'foo' => 'Foo <foo@bar.com>' } }

      include_examples 'do not amend commit'
      include_examples 'error', "fatal: invalid coauthor: bar\n"
    end

    context 'when the user config contains the specified aliases' do
      let(:user_config) { { 'foo' => 'Foo <foo@bar.com>', 'bar' => 'Bar <bar@bar.com>' } }

      include_examples 'amend commit',
                       "Foo\n\nBar\n\nCo-authored-by: Bar <bar@bar.com>\nCo-authored-by: Foo <foo@bar.com>\n"
      include_examples 'print commit',
                       "Commit:\n  Co-authored-by: Bar <bar@bar.com>\n  Co-authored-by: Foo <foo@bar.com>\n"
      include_examples 'success'
    end

    context 'when the repo config contains the specified alias' do
      let(:repo_config) { { 'foo' => 'Foo <foo@bar.com>', 'bar' => 'Bar <bar@bar.com>' } }

      include_examples 'amend commit',
                       "Foo\n\nBar\n\nCo-authored-by: Bar <bar@bar.com>\nCo-authored-by: Foo <foo@bar.com>\n"
      include_examples 'print commit',
                       "Commit:\n  Co-authored-by: Bar <bar@bar.com>\n  Co-authored-by: Foo <foo@bar.com>\n"
      include_examples 'success'
    end
  end

  context 'git coauthor' do
    let(:argv) { [] }

    context 'when the previous commit cannot be retrieved' do
      let(:commit_message) { nil }

      include_examples 'do not amend commit'
      include_examples 'error', "fatal: cannot read the previous commit message\n"
    end

    context 'when the previous commit does not contain any coauthors' do
      let(:commit_message) { "Foo\n\nBar\n" }

      include_examples 'print commit', "Commit:\n"
      include_examples 'success'
    end

    context 'when the previous commit contains a single coauthor' do
      let(:commit_message) { "Foo\n\nBar\nCo-authored-by: Foo <foo@bar.com>\n" }

      include_examples 'print commit', "Commit:\n  Co-authored-by: Foo <foo@bar.com>\n"
      include_examples 'success'
    end

    context 'when the previous commit contains multiple coauthors' do
      let(:commit_message) { "Foo\n\nBar\nCo-authored-by: Bar <bar@bar.com>\nCo-authored-by: Foo <foo@bar.com>\n" }

      include_examples 'print commit',
                       "Commit:\n  Co-authored-by: Bar <bar@bar.com>\n  Co-authored-by: Foo <foo@bar.com>\n"
      include_examples 'success'
    end
  end

  context 'git coauthor --delete' do
    let(:argv) { ['--delete'] }

    context 'when the previous commit cannot be retrieved' do
      let(:commit_message) { nil }

      include_examples 'do not amend commit'
      include_examples 'error', "fatal: cannot read the previous commit message\n"
    end

    context 'when the previous commit does not contain any coauthors' do
      let(:commit_message) { "Foo\n\nBar\n" }

      include_examples 'amend commit', "Foo\n\nBar\n"
      include_examples 'print commit', "Commit:\n"
      include_examples 'success'
    end

    context 'when the previous commit contains one coauthor' do
      let(:commit_message) { "Foo\n\nBar\n\nCo-authored-by: Foo <foo@bar.com>\n" }

      include_examples 'amend commit', "Foo\n\nBar\n"
      include_examples 'print commit', "Commit:\n"
      include_examples 'success'
    end

    context 'when the previous commit contains multiple coauthors' do
      let(:commit_message) { "Foo\n\nBar\n\nCo-authored-by: Bar <bar@bar.com>\nCo-authored-by: Foo <foo@bar.com>\n" }

      include_examples 'amend commit', "Foo\n\nBar\n"
      include_examples 'print commit', "Commit:\n"
      include_examples 'success'
    end

    context 'when the previous commit cannot be amended' do
      let(:commit_message) { "Foo\n\nBar\n" }

      before do
        allow(GitCoauthor::Git).to receive(:amend_commit_message).and_return(false)
      end

      include_examples 'error', "fatal: cannot amend the previous commit message\n"
    end
  end

  context 'git coauthor --delete foo' do
    let(:argv) { %w[--delete foo] }

    context 'when the previous commit cannot be retrieved' do
      let(:commit_message) { nil }

      include_examples 'do not amend commit'
      include_examples 'error', "fatal: cannot read the previous commit message\n"
    end

    context 'when the config does not contain the specified alias' do
      let(:commit_message) { "Foo\n\nBar\n" }

      include_examples 'do not amend commit'
      include_examples 'error', "fatal: invalid coauthor: foo\n"
    end

    context 'when the user config contains the specified alias and they are one of the coauthors' do
      let(:commit_message) { "Foo\n\nBar\n\nCo-authored-by: Bar <bar@bar.com>\nCo-authored-by: Foo <foo@bar.com>\n" }
      let(:user_config) { { 'foo' => 'Foo <foo@bar.com>' } }

      include_examples 'amend commit', "Foo\n\nBar\n\nCo-authored-by: Bar <bar@bar.com>\n"
      include_examples 'print commit', "Commit:\n  Co-authored-by: Bar <bar@bar.com>\n"
      include_examples 'success'
    end

    context 'when the repo config contains the specified alias and they are one of the coauthors' do
      let(:commit_message) { "Foo\n\nBar\n\nCo-authored-by: Bar <bar@bar.com>\nCo-authored-by: Foo <foo@bar.com>\n" }
      let(:repo_config) { { 'foo' => 'Foo <foo@bar.com>' } }

      include_examples 'amend commit', "Foo\n\nBar\n\nCo-authored-by: Bar <bar@bar.com>\n"
      include_examples 'print commit', "Commit:\n  Co-authored-by: Bar <bar@bar.com>\n"
      include_examples 'success'
    end

    context 'when the user config contains the specified alias and they are the only coauthor' do
      let(:commit_message) { "Foo\n\nBar\n\nCo-authored-by: Foo <foo@bar.com>\n" }
      let(:user_config) { { 'foo' => 'Foo <foo@bar.com>' } }

      include_examples 'amend commit', "Foo\n\nBar\n"
      include_examples 'print commit', "Commit:\n"
      include_examples 'success'
    end

    context 'when the previous commit cannot be amended' do
      let(:commit_message) { "Foo\n\nBar\n" }
      let(:user_config) { { 'foo' => 'Foo <foo@bar.com>' } }

      before do
        allow(GitCoauthor::Git).to receive(:amend_commit_message).and_return(false)
      end

      include_examples 'error', "fatal: cannot amend the previous commit message\n"
    end
  end

  context 'git coauthor --delete foo bar' do
    let(:argv) { %w[--delete foo bar] }

    context 'when the config does not contain one of the specified aliases' do
      let(:commit_message) { "Foo\n\nBar\n" }
      let(:user_config) { { 'foo' => 'Foo <foo@bar.com>' } }

      include_examples 'do not amend commit'
      include_examples 'error', "fatal: invalid coauthor: bar\n"
    end

    context 'when the user config contains the specified aliases and they are the only coauthors' do
      let(:commit_message) { "Foo\n\nBar\n\nCo-authored-by: Bar <bar@bar.com>\nCo-authored-by: Foo <foo@bar.com>\n" }
      let(:user_config) { { 'foo' => 'Foo <foo@bar.com>', 'bar' => 'Bar <bar@bar.com>' } }

      include_examples 'amend commit', "Foo\n\nBar\n"
      include_examples 'print commit', "Commit:\n"
      include_examples 'success'
    end

    context 'when the user config contains the specified aliases and they are among the coauthors' do
      let(:commit_message) do
        <<~COMMIT
          Foo

          Bar

          Co-authored-by: Bar <bar@bar.com>
          Co-authored-by: Baz <baz@bar.com>
          Co-authored-by: Foo <foo@bar.com>
        COMMIT
      end
      let(:user_config) { { 'foo' => 'Foo <foo@bar.com>', 'bar' => 'Bar <bar@bar.com>' } }

      include_examples 'amend commit', "Foo\n\nBar\n\nCo-authored-by: Baz <baz@bar.com>\n"
      include_examples 'print commit', "Commit:\n  Co-authored-by: Baz <baz@bar.com>\n"
      include_examples 'success'
    end

    context 'when the previous commit cannot be amended' do
      let(:commit_message) { "Foo\n\nBar\n" }
      let(:user_config) { { 'foo' => 'Foo <foo@bar.com>', 'bar' => 'Bar <bar@bar.com>' } }

      before do
        allow(GitCoauthor::Git).to receive(:amend_commit_message).and_return(false)
      end

      include_examples 'error', "fatal: cannot amend the previous commit message\n"
    end
  end
end
