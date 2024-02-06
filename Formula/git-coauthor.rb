class GitCoauthor < Formula
  desc "CLI used to manage Git coauthors"
  homepage "https://github.com/nicholasdower/git-coauthor"
  url "https://github.com/nicholasdower/git-coauthor/archive/v6.tar.gz"
  sha256 "00a634d0f3a4095df40131b0e13446f71ef59f25668aa257b3e7271e182f35a7"
  license "MIT"

  def install
    lib.install Dir["lib/*"]
    bin.install "bin/git-coauthor"
    system "git", "config", "--global", "alias.coauthor", "'!git-coauthor'"
  end

  test do
    assert_match "git-coauthor version 6", shell_output("#{bin}/git-coauthor --version")
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
