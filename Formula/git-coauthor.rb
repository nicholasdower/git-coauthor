class GitCoauthor < Formula
  desc "CLI used to manage Git coauthors"
  homepage "https://github.com/nicholasdower/git-coauthor"
  url "https://github.com/nicholasdower/git-coauthor/archive/v7.tar.gz"
  sha256 "ca06c5ced654e79fb4d6111a8e3e46dc3470ad432a5e0e2ee71b58336b7308d9"
  license "MIT"

  def install
    lib.install Dir["lib/*"]
    bin.install "bin/git-coauthor"
    system "git", "config", "--global", "alias.coauthor", "'!git-coauthor'"
  end

  test do
    assert_match "git-coauthor version 7", shell_output("#{bin}/git-coauthor --version")
  end

  def caveats
    <<~EOS
      Git Coauthor installed as `git coauthor`. Try:

        git coauthor -h

      To add the ca alias:

        git config --global alias.ca '!git-coauthor'
    EOS
  end
end
