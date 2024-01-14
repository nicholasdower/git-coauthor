# frozen_string_literal: true

require_relative '../spec_helper'

describe 'CLI' do
  subject { cli.run }

  let(:cli) { GitCoauthor::CLI.new(['--install'], stdout, stderr) }
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }

  before do
    allow(Kernel).to receive(:exit).with(0).and_raise(StandardError.new('success'))
    allow(Kernel).to receive(:exit).with(1).and_raise(StandardError.new('error'))
  end

  context 'git-coauthor --install' do
    context 'when installation succeeds' do
      before { allow(GitCoauthor::Git).to receive(:install).and_return(true) }

      it 'installs git-coauthor' do
        expect(GitCoauthor::Git).to receive(:install)
        subject rescue nil
      end

      it 'does not print a message to stdout' do
        subject rescue nil
        expect(stdout.string).to eq('')
      end

      it 'does not print an error message' do
        subject rescue nil
        expect(stderr.string).to eq('')
      end

      it 'exits without an error' do
        expect { subject }.to raise_error(StandardError, 'success')
      end
    end

    context 'when installation fails' do
      before { allow(GitCoauthor::Git).to receive(:install).and_return(false) }

      it 'does not print a message to stdout' do
        subject rescue nil
        expect(stdout.string).to eq('')
      end

      it 'prints an error message' do
        subject rescue nil
        expect(stderr.string).to eq("fatal: could not install git-coauthor\n")
      end

      it 'exits with an error' do
        expect { subject }.to raise_error(StandardError, 'error')
      end
    end
  end
end
