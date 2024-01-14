# frozen_string_literal: true

require_relative '../spec_helper'

describe 'CLI' do
  subject { cli.run }

  let(:cli) { GitCoauthor::CLI.new(argv, stdout, stderr) }
  let(:argv) { [] }
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }

  before do
    allow(Kernel).to receive(:exit).with(0).and_raise(StandardError.new('success'))
    allow(Kernel).to receive(:exit).with(1).and_raise(StandardError.new('error'))
  end

  context 'git-coauthor --foo' do
    let(:argv) { ['--foo'] }

    it 'does not print a message to stdout' do
      subject rescue nil
      expect(stdout.string).to eq('')
    end

    it 'prints an error message' do
      subject rescue nil
      expect(stderr.string).to eq("fatal: invalid option: --foo\n")
    end

    it 'exits with an error' do
      expect { subject }.to raise_error(StandardError, 'error')
    end
  end

  context 'git-coauthor --session=1' do
    let(:argv) { ['--session=1'] }

    it 'does not print a message to stdout' do
      subject rescue nil
      expect(stdout.string).to eq('')
    end

    it 'prints an error message' do
      subject rescue nil
      expect(stderr.string).to eq("fatal: needless argument: --session=1\n")
    end

    it 'exits with an error' do
      expect { subject }.to raise_error(StandardError, 'error')
    end
  end
end
