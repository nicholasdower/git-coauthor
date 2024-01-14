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

  before do
    allow(Dir).to receive(:home).and_return('/home/')
    allow(File).to receive(:exist?).with('/home/.git-coauthors').and_return(!user_config.nil?)
    allow(YAML).to receive(:safe_load_file).with('/home/.git-coauthors').and_return(user_config) if user_config

    allow(Dir).to receive(:pwd).and_return('/home/project')
    allow(File).to receive(:exist?).with('/home/project/.git-coauthors').and_return(!repo_config.nil?)
    allow(YAML).to receive(:safe_load_file).with('/home/project/.git-coauthors').and_return(repo_config) if repo_config

    allow(Kernel).to receive(:exit).with(0).and_raise(StandardError.new('success'))
    allow(Kernel).to receive(:exit).with(1).and_raise(StandardError.new('error'))

    allow(File).to receive(:write)
    allow(FileUtils).to receive(:rm_f)
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

    it 'does not print the config' do
      subject rescue nil
      expect(stdout.string).to eq('')
    end

    it 'exits with an error' do
      expect { subject }.to raise_error(StandardError, 'error')
    end

    it 'does not write any config or template' do
      expect(File).not_to receive(:write)
      subject rescue nil
    end
  end

  shared_examples 'print config' do |config|
    it 'prints the config' do
      subject rescue nil
      expect(stdout.string).to eq(config)
    end
  end

  shared_examples 'write repo config' do |config|
    it 'writes the config' do
      expect(File).to receive(:write).with('/home/project/.git-coauthors', config)
      subject rescue nil
    end
  end

  shared_examples 'write user config' do |config|
    it 'writes the config' do
      expect(File).to receive(:write).with('/home/.git-coauthors', config)
      subject rescue nil
    end
  end

  context 'git coauthor --config "foo: Foo <foo@bar.com>"' do
    context 'when single valid config specified' do
      let(:argv) { %w[--config foo] }

      include_examples 'error', "fatal: invalid config\n"
    end

    context 'when multiple configs specified and one is invalid' do
      let(:argv) { ['--config', 'foo: Foo <foo@bar.com>', 'bar'] }

      include_examples 'error', "fatal: invalid config\n"
    end

    context 'when single valid config specified' do
      let(:argv) { ['--config', 'foo: Foo <foo@bar.com>'] }

      include_examples 'print config', ".git-coauthors:\n  foo: Foo <foo@bar.com>\n"
      include_examples 'write repo config', "foo: Foo <foo@bar.com>\n"
      include_examples 'success'
    end

    context 'when multiple valid configs specified' do
      let(:argv) { ['--config', 'foo: Foo <foo@bar.com>', 'bar: Bar <bar@bar.com>'] }

      include_examples 'print config', ".git-coauthors:\n  bar: Bar <bar@bar.com>\n  foo: Foo <foo@bar.com>\n"
      include_examples 'write repo config', "bar: Bar <bar@bar.com>\nfoo: Foo <foo@bar.com>\n"
      include_examples 'success'
    end

    context 'when adding to an existing config' do
      let(:argv) { ['--config', 'foo: Foo <foo@bar.com>'] }
      let(:repo_config) { { 'baz' => 'Baz <baz@bar.com>' } }

      include_examples 'print config', ".git-coauthors:\n  baz: Baz <baz@bar.com>\n  foo: Foo <foo@bar.com>\n"
      include_examples 'write repo config', "baz: Baz <baz@bar.com>\nfoo: Foo <foo@bar.com>\n"
      include_examples 'success'
    end

    context 'when updating an existing config' do
      let(:argv) { ['--config', 'baz: Bar <bar@bar.com>'] }
      let(:repo_config) { { 'baz' => 'Baz <baz@bar.com>' } }

      include_examples 'print config', ".git-coauthors:\n  baz: Bar <bar@bar.com>\n"
      include_examples 'write repo config', "baz: Bar <bar@bar.com>\n"
      include_examples 'success'
    end
  end

  context 'git coauthor --config --global "foo: Foo <foo@bar.com>"' do
    context 'when single valid config specified' do
      let(:argv) { %w[--config --global foo] }

      include_examples 'error', "fatal: invalid config\n"
    end

    context 'when multiple configs specified and one is invalid' do
      let(:argv) { ['--config', '--global', 'foo: Foo <foo@bar.com>', 'bar'] }

      include_examples 'error', "fatal: invalid config\n"
    end

    context 'when single valid config specified' do
      let(:argv) { ['--config', '--global', 'foo: Foo <foo@bar.com>'] }

      include_examples 'print config', "/home/.git-coauthors:\n  foo: Foo <foo@bar.com>\n"
      include_examples 'write user config', "foo: Foo <foo@bar.com>\n"
      include_examples 'success'
    end

    context 'when multiple valid configs specified' do
      let(:argv) { ['--config', '--global', 'foo: Foo <foo@bar.com>', 'bar: Bar <bar@bar.com>'] }

      include_examples 'print config', "/home/.git-coauthors:\n  bar: Bar <bar@bar.com>\n  foo: Foo <foo@bar.com>\n"
      include_examples 'write user config', "bar: Bar <bar@bar.com>\nfoo: Foo <foo@bar.com>\n"
      include_examples 'success'
    end

    context 'when adding to an existing config' do
      let(:argv) { ['--config', '--global', 'foo: Foo <foo@bar.com>'] }
      let(:user_config) { { 'baz' => 'Baz <baz@bar.com>' } }

      include_examples 'print config', "/home/.git-coauthors:\n  baz: Baz <baz@bar.com>\n  foo: Foo <foo@bar.com>\n"
      include_examples 'write user config', "baz: Baz <baz@bar.com>\nfoo: Foo <foo@bar.com>\n"
      include_examples 'success'
    end

    context 'when updating an existing config' do
      let(:argv) { ['--config', '--global', 'baz: Bar <bar@bar.com>'] }
      let(:user_config) { { 'baz' => 'Baz <baz@bar.com>' } }

      include_examples 'print config', "/home/.git-coauthors:\n  baz: Bar <bar@bar.com>\n"
      include_examples 'write user config', "baz: Bar <bar@bar.com>\n"
      include_examples 'success'
    end
  end

  context 'git coauthor --config' do
    let(:argv) { ['--config'] }

    context 'when no config exists' do
      let(:repo_config) { nil }

      include_examples 'print config', ".git-coauthors:\n"
      include_examples 'success'
    end

    context 'when config exists' do
      let(:repo_config) { { 'baz' => 'Baz <baz@bar.com>' } }

      include_examples 'print config', ".git-coauthors:\n  baz: Baz <baz@bar.com>\n"
      include_examples 'success'
    end
  end

  context 'git coauthor --config --global' do
    let(:argv) { %w[--config --global] }

    context 'when no config exists' do
      let(:user_config) { nil }

      include_examples 'print config', "/home/.git-coauthors:\n"
      include_examples 'success'
    end

    context 'when config exists' do
      let(:user_config) { { 'baz' => 'Baz <baz@bar.com>' } }

      include_examples 'print config', "/home/.git-coauthors:\n  baz: Baz <baz@bar.com>\n"
      include_examples 'success'
    end
  end

  context 'git coauthor --config --delete' do
    let(:argv) { %w[--config --delete] }

    context 'when no config exists' do
      let(:repo_config) { nil }

      include_examples 'write repo config', "\n"
      include_examples 'print config', ".git-coauthors:\n"
      include_examples 'success'
    end

    context 'when config exists' do
      let(:repo_config) { { 'baz' => 'Baz <baz@bar.com>' } }

      include_examples 'write repo config', "\n"
      include_examples 'print config', ".git-coauthors:\n"
      include_examples 'success'
    end
  end

  context 'git coauthor --config --delete --global' do
    let(:argv) { %w[--config --delete --global] }

    context 'when no config exists' do
      let(:user_config) { nil }

      include_examples 'write user config', "\n"
      include_examples 'print config', "/home/.git-coauthors:\n"
      include_examples 'success'
    end

    context 'when config exists' do
      let(:user_config) { { 'baz' => 'Baz <baz@bar.com>' } }

      include_examples 'write user config', "\n"
      include_examples 'print config', "/home/.git-coauthors:\n"
      include_examples 'success'
    end
  end

  context 'git coauthor --config --delete foo' do
    let(:argv) { %w[--config --delete foo] }

    context 'when no config exists' do
      let(:repo_config) { nil }

      include_examples 'write repo config', "\n"
      include_examples 'print config', ".git-coauthors:\n"
      include_examples 'success'
    end

    context 'when config exists without alias' do
      let(:repo_config) { { 'baz' => 'Baz <baz@bar.com>' } }

      include_examples 'write repo config', "baz: Baz <baz@bar.com>\n"
      include_examples 'print config', ".git-coauthors:\n  baz: Baz <baz@bar.com>\n"
      include_examples 'success'
    end

    context 'when config exists with only alias' do
      let(:repo_config) { { 'foo' => 'Foo <foo@bar.com>' } }

      include_examples 'write repo config', "\n"
      include_examples 'print config', ".git-coauthors:\n"
      include_examples 'success'
    end

    context 'when config exists with multiple aliases' do
      let(:repo_config) { { 'foo' => 'Foo <foo@bar.com>', 'bar' => 'Bar <bar@bar.com>' } }

      include_examples 'write repo config', "bar: Bar <bar@bar.com>\n"
      include_examples 'print config', ".git-coauthors:\n  bar: Bar <bar@bar.com>\n"
      include_examples 'success'
    end
  end

  context 'git coauthor --config --delete --global foo' do
    let(:argv) { %w[--config --delete --global foo] }

    context 'when no config exists' do
      let(:user_config) { nil }

      include_examples 'write user config', "\n"
      include_examples 'print config', "/home/.git-coauthors:\n"
      include_examples 'success'
    end

    context 'when config exists without alias' do
      let(:user_config) { { 'baz' => 'Baz <baz@bar.com>' } }

      include_examples 'write user config', "baz: Baz <baz@bar.com>\n"
      include_examples 'print config', "/home/.git-coauthors:\n  baz: Baz <baz@bar.com>\n"
      include_examples 'success'
    end

    context 'when config exists with only alias' do
      let(:user_config) { { 'foo' => 'Foo <foo@bar.com>' } }

      include_examples 'write user config', "\n"
      include_examples 'print config', "/home/.git-coauthors:\n"
      include_examples 'success'
    end

    context 'when config exists with multiple aliases' do
      let(:user_config) { { 'foo' => 'Foo <foo@bar.com>', 'bar' => 'Bar <bar@bar.com>' } }

      include_examples 'write user config', "bar: Bar <bar@bar.com>\n"
      include_examples 'print config', "/home/.git-coauthors:\n  bar: Bar <bar@bar.com>\n"
      include_examples 'success'
    end
  end
end
