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
  let(:template) { nil }

  before do
    allow(Dir).to receive(:home).and_return('/home/')
    allow(File).to receive(:exist?).with('/home/.git-coauthors').and_return(!user_config.nil?)
    allow(YAML).to receive(:safe_load_file).with('/home/.git-coauthors').and_return(user_config) if user_config

    allow(Dir).to receive(:pwd).and_return('/home/project')
    allow(File).to receive(:exist?).with('/home/project/.git-coauthors').and_return(!repo_config.nil?)
    allow(YAML).to receive(:safe_load_file).with('/home/project/.git-coauthors').and_return(repo_config) if repo_config

    allow(Kernel).to receive(:exit).with(0).and_raise(StandardError.new('success'))
    allow(Kernel).to receive(:exit).with(1).and_raise(StandardError.new('error'))

    allow(File).to receive(:read).with('.git-coauthors-template').and_return(template) if template
    allow(File).to receive(:exist?).with('.git-coauthors-template').and_return(!template.nil?)
    allow(File).to receive(:write)
    allow(FileUtils).to receive(:rm_f)
  end

  shared_examples 'success' do |session|
    it 'does not print an error message' do
      subject rescue nil
      expect(stderr.string).to eq('')
    end

    it 'prints the session' do
      subject rescue nil
      expect(stdout.string).to eq(session)
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

    it 'does not print the session' do
      subject rescue nil
      expect(stdout.string).to eq('')
    end

    it 'does not write the template' do
      expect(File).not_to receive(:write)
      subject rescue nil
    end

    it 'does not remove the template' do
      expect(FileUtils).not_to receive(:rm_f)
      subject rescue nil
    end

    it 'exits with an error' do
      expect { subject }.to raise_error(StandardError, 'error')
    end
  end

  shared_examples 'write template' do |template|
    it 'writes the template' do
      expect(File).to receive(:write).with('.git-coauthors-template', template)
      subject rescue nil
    end
  end

  shared_examples 'remove template' do
    it 'removes the template' do
      expect(FileUtils).to receive(:rm_f).with('.git-coauthors-template')
      subject rescue nil
    end
  end

  shared_examples 'set template' do |path|
    it 'sets the template' do
      expect(GitCoauthor::Git).to receive(:config_set).with('commit.template', path)
      subject rescue nil
    end
  end

  shared_examples 'unset template' do
    it 'unsets the template' do
      expect(GitCoauthor::Git).to receive(:config_unset).with('commit.template')
      subject rescue nil
    end
  end

  shared_examples 'set template backup' do |path|
    it 'sets the template backup' do
      expect(GitCoauthor::Git).to receive(:config_set).with('commit.template.backup', path)
      subject rescue nil
    end
  end

  shared_examples 'unset template backup' do
    it 'unsets the template backup' do
      expect(GitCoauthor::Git).to receive(:config_unset).with('commit.template.backup')
      subject rescue nil
    end
  end

  context 'git coauthor --session' do
    let(:argv) { ['--session'] }

    context 'when no session exists' do
      let(:template) { nil }

      before { allow(GitCoauthor::Git).to receive(:config_get).with('commit.template').and_return([false, nil]) }

      include_examples 'success', "Session:\n"
    end

    context 'when a different git commit template is in use' do
      let(:template) { nil }

      before { allow(GitCoauthor::Git).to receive(:config_get).with('commit.template').and_return([true, 'foo']) }

      include_examples 'success', "Session:\n"
    end

    context 'when the commit template file does not exist' do
      before do
        allow(GitCoauthor::Git).to receive(:config_get).with('commit.template').and_return(
          [true, '.git-coauthors-template']
        )
        allow(File).to receive(:exist?).with('.git-coauthors-template').and_return(false)
      end

      include_examples 'error', "fatal: git commit template not exist: .git-coauthors-template\n"
    end

    context 'when a session exists' do
      let(:template) { "\n\nCo-authored-by: Foo <foo@bar.com>" }

      before do
        allow(GitCoauthor::Git).to receive(:config_get).with('commit.template').and_return(
          [true, '.git-coauthors-template']
        )
      end

      include_examples 'success', "Session:\n  Co-authored-by: Foo <foo@bar.com>\n"
    end
  end

  context 'git coauthor --session foo' do
    let(:argv) { %w[--session foo] }

    context 'when the existing commit template file does not exist' do
      let(:user_config) { { 'foo' => 'Foo <foo@bar.com>' } }

      before do
        allow(GitCoauthor::Git).to receive(:config_get).with('commit.template').and_return([true, 'moo'])
        allow(File).to receive(:exist?).with('moo').and_return(false)
      end

      include_examples 'error', "fatal: commit template not found: moo\n"
    end

    context 'when the existing commit template file exists' do
      let(:user_config) { { 'foo' => 'Foo <foo@bar.com>' } }

      before do
        allow(GitCoauthor::Git).to receive(:config_get).with('commit.template').and_return([true, 'moo'])
        allow(File).to receive(:exist?).with('moo').and_return(true)
        allow(File).to receive(:read).with('moo').and_return("Foo\n\nBar\n")
      end

      include_examples 'set template backup', 'moo'
      include_examples 'write template', "Foo\n\nBar\nCo-authored-by: Foo <foo@bar.com>\n"
      include_examples 'success', "Session:\n  Co-authored-by: Foo <foo@bar.com>\n"
    end

    context 'when there is not an existing coauthors commit template' do
      let(:user_config) { { 'foo' => 'Foo <foo@bar.com>' } }

      before do
        allow(GitCoauthor::Git).to receive(:config_get).with('commit.template').and_return([false, nil])
      end

      include_examples 'write template', "\n\nCo-authored-by: Foo <foo@bar.com>\n"
      include_examples 'success', "Session:\n  Co-authored-by: Foo <foo@bar.com>\n"
    end

    context 'when the coauthors commit template file does not exist' do
      let(:user_config) { { 'foo' => 'Foo <foo@bar.com>' } }

      before do
        allow(GitCoauthor::Git).to receive(:config_get).with('commit.template').and_return(
          [true, '.git-coauthors-template']
        )
        allow(File).to receive(:exist?).with('.git-coauthors-template').and_return(false)
      end

      include_examples 'error', "fatal: commit template not found: .git-coauthors-template\n"
    end

    context 'when coauthors commit template file exists' do
      let(:user_config) { { 'foo' => 'Foo <foo@bar.com>' } }

      before do
        allow(GitCoauthor::Git).to receive(:config_get).with('commit.template').and_return(
          [true, '.git-coauthors-template']
        )
        allow(File).to receive(:exist?).with('.git-coauthors-template').and_return(true)
        allow(File).to receive(:read).with('.git-coauthors-template').and_return(
          "\n\nCo-authored-by: Bar <bar@bar.com>\n"
        )
      end

      include_examples 'write template', "\n\nCo-authored-by: Bar <bar@bar.com>\nCo-authored-by: Foo <foo@bar.com>\n"
      include_examples 'success', "Session:\n  Co-authored-by: Bar <bar@bar.com>\n  Co-authored-by: Foo <foo@bar.com>\n"
    end
  end

  context 'git coauthor --session foo bar' do
    let(:argv) { %w[--session foo bar] }

    context 'when the existing commit template file does not exist' do
      let(:user_config) { { 'foo' => 'Foo <foo@bar.com>', 'bar' => 'Bar <bar@bar.com>' } }

      before do
        allow(GitCoauthor::Git).to receive(:config_get).with('commit.template').and_return([true, 'moo'])
        allow(File).to receive(:exist?).with('moo').and_return(false)
      end

      include_examples 'error', "fatal: commit template not found: moo\n"
    end

    context 'when the existing commit template file exists' do
      let(:user_config) { { 'foo' => 'Foo <foo@bar.com>', 'bar' => 'Bar <bar@bar.com>' } }

      before do
        allow(GitCoauthor::Git).to receive(:config_get).with('commit.template').and_return([true, 'moo'])
        allow(File).to receive(:exist?).with('moo').and_return(true)
        allow(File).to receive(:read).with('moo').and_return("Foo\n\nBar\n")
      end

      include_examples 'set template backup', 'moo'
      include_examples 'write template',
                       "Foo\n\nBar\nCo-authored-by: Bar <bar@bar.com>\nCo-authored-by: Foo <foo@bar.com>\n"
      include_examples 'success', "Session:\n  Co-authored-by: Bar <bar@bar.com>\n  Co-authored-by: Foo <foo@bar.com>\n"
    end

    context 'when there is not an existing coauthors commit template' do
      let(:user_config) { { 'foo' => 'Foo <foo@bar.com>', 'bar' => 'Bar <bar@bar.com>' } }

      before do
        allow(GitCoauthor::Git).to receive(:config_get).with('commit.template').and_return([false, nil])
      end

      include_examples 'write template', "\n\nCo-authored-by: Bar <bar@bar.com>\nCo-authored-by: Foo <foo@bar.com>\n"
      include_examples 'success', "Session:\n  Co-authored-by: Bar <bar@bar.com>\n  Co-authored-by: Foo <foo@bar.com>\n"
    end

    context 'when the coauthors commit template file does not exist' do
      let(:user_config) { { 'foo' => 'Foo <foo@bar.com>', 'bar' => 'Bar <bar@bar.com>' } }

      before do
        allow(GitCoauthor::Git).to receive(:config_get).with('commit.template').and_return(
          [true, '.git-coauthors-template']
        )
        allow(File).to receive(:exist?).with('.git-coauthors-template').and_return(false)
      end

      include_examples 'error', "fatal: commit template not found: .git-coauthors-template\n"
    end

    context 'when coauthors commit template file exists' do
      let(:user_config) { { 'foo' => 'Foo <foo@bar.com>', 'bar' => 'Bar <bar@bar.com>' } }

      before do
        allow(GitCoauthor::Git).to receive(:config_get).with('commit.template').and_return(
          [true, '.git-coauthors-template']
        )
        allow(File).to receive(:exist?).with('.git-coauthors-template').and_return(true)
        allow(File).to receive(:read).with('.git-coauthors-template').and_return(
          "\n\nCo-authored-by: Baz <baz@bar.com>\n"
        )
      end

      include_examples 'write template',
                       <<~TEMPLATE


                         Co-authored-by: Bar <bar@bar.com>
                         Co-authored-by: Baz <baz@bar.com>
                         Co-authored-by: Foo <foo@bar.com>
                       TEMPLATE
      include_examples 'success',
                       <<~TEMPLATE
                         Session:
                           Co-authored-by: Bar <bar@bar.com>
                           Co-authored-by: Baz <baz@bar.com>
                           Co-authored-by: Foo <foo@bar.com>
                       TEMPLATE
    end
  end

  context 'git coauthor --session --delete' do
    let(:argv) { %w[--session --delete] }

    context 'when the coauthors commit template is set without a backup' do
      before do
        allow(GitCoauthor::Git).to receive(:config_get).with('commit.template').and_return(
          [true, '.git-coauthors-template']
        )
        allow(GitCoauthor::Git).to receive(:config_unset).with('commit.template').and_return(true)
        allow(File).to receive(:exist?).with('.git-coauthors-template').and_return(false)
        allow(GitCoauthor::Git).to receive(:config_get).with('commit.template.backup').and_return([false, nil])
      end

      include_examples 'remove template'
      include_examples 'success', "Session:\n"
    end

    context 'when the existing commit template file is not a coauthors template' do
      before do
        allow(GitCoauthor::Git).to receive(:config_get).with('commit.template').and_return([true, 'moo'])
      end

      include_examples 'success', "Session:\n"
    end

    context 'when there is not an existing commit template' do
      before do
        allow(GitCoauthor::Git).to receive(:config_get).with('commit.template').and_return([false, nil])
      end

      include_examples 'success', "Session:\n"
    end

    context 'when the coauthors commit template is set with a backup' do
      before do
        allow(GitCoauthor::Git).to receive(:config_get).with('commit.template').and_return(
          [true, '.git-coauthors-template']
        )
        allow(GitCoauthor::Git).to receive(:config_unset).with('commit.template').and_return(true)
        allow(File).to receive(:exist?).with('.git-coauthors-template').and_return(false)
        allow(GitCoauthor::Git).to receive(:config_get).with('commit.template.backup').and_return([true, 'moo'])
        allow(GitCoauthor::Git).to receive(:config_unset).with('commit.template.backup').and_return(true)
        allow(GitCoauthor::Git).to receive(:config_set).with('commit.template', 'moo').and_return(true)
      end

      include_examples 'remove template'
      include_examples 'set template', 'moo'
      include_examples 'unset template backup'
      include_examples 'success', "Session:\n"
    end
  end

  context 'git coauthor --session --delete foo' do
    let(:argv) { %w[--session --delete foo] }

    context 'when there is not an existing commit template' do
      before do
        allow(GitCoauthor::Git).to receive(:config_get).with('commit.template').and_return([false, nil])
      end

      include_examples 'success', "Session:\n"
    end

    context 'when the existing commit template file is not a coauthors template' do
      before do
        allow(GitCoauthor::Git).to receive(:config_get).with('commit.template').and_return([true, 'moo'])
      end

      include_examples 'success', "Session:\n"
    end

    context 'when the coauthors commit template file does not exist' do
      before do
        allow(GitCoauthor::Git).to receive(:config_get).with('commit.template').and_return(
          [true, '.git-coauthors-template']
        )
        allow(GitCoauthor::Git).to receive(:config_get).with('commit.template.backup').and_return([false, nil])
        allow(File).to receive(:exist?).with('.git-coauthors-template').and_return(false)
        allow(GitCoauthor::Git).to receive(:config_unset).with('commit.template').and_return(true)
        allow(FileUtils).to receive(:rm_f).with('.git-coauthors-template')
      end

      include_examples 'success', "Session:\n"
    end
  end
end
