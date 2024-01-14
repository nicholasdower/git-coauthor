# frozen_string_literal: true

require_relative '../spec_helper'

describe 'CLI' do
  subject { cli.run }

  let(:cli) { GitCoauthor::CLI.new(['-h'], stdout, stderr) }
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }

  before do
    allow(Kernel).to receive(:exit).with(0).and_raise(StandardError.new('success'))
    allow(Kernel).to receive(:exit).with(1).and_raise(StandardError.new('error'))
  end

  context 'git-coauthor --help' do
    it 'prints the help' do
      subject rescue nil
      expect(stdout.string).to start_with('Manages Git coauthors.')
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
