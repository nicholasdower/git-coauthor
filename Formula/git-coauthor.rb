class GitCoauthor < Formula
  desc "CLI used to manage Git coauthors"
  homepage "https://github.com/nicholasdower/git-coauthor"
  url "https://github.com/nicholasdower/git-coauthor/archive/v5.tar.gz"
  sha256 "76ba84841c9ff82ac924050e305a81c59f0b3a2f9b4dd3d7d717d118787818ba"
  license "MIT"

  def install
    lib.install Dir["lib/*"]
    bin.install "bin/git-coauthor"
    system "git", "config", "--global", "alias.coauthor", "'!git-coauthor'"
  end

  test do
    assert_match "git-coauthor version 5", shell_output("#{bin}/git-coauthor --version")
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
