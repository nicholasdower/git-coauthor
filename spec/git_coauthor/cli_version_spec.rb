# frozen_string_literal: true

require_relative '../spec_helper'

describe 'CLI' do
  subject { cli.run }

  let(:cli) { GitCoauthor::CLI.new(['--version'], stdout, stderr) }
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }

  before do
    allow(Kernel).to receive(:exit).with(0).and_raise(StandardError.new('success'))
    allow(Kernel).to receive(:exit).with(1).and_raise(StandardError.new('error'))
  end

  context 'git-coauthor --version' do
    it 'prints the version' do
      subject rescue nil
      expect(stdout.string).to eq("git-coauthor version 1\n")
    end

    it 'does not print an error message' do
      subject rescue nil
      expect(stderr.string).to eq('')
    end

    it 'exits without an error' do
      expect { subject }.to raise_error(StandardError, 'success')
    end
  end
end
