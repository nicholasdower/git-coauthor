class GitCoauthor < Formula
  desc "CLI used to manage Git coauthors"
  homepage "https://github.com/nicholasdower/git-coauthor"
  url "https://github.com/nicholasdower/git-coauthor/archive/v4.tar.gz"
  sha256 "5882b0e61143a38b33b2cf7b1e225f9020e50a98e4c240e059a5e8be997f2865"
  license "MIT"

  def install
    lib.install Dir["lib/*"]
    bin.install "bin/git-coauthor"
    system "git", "config", "--global", "alias.coauthor", "'!git-coauthor'"
  end

  test do
    assert_match "git-coauthor version 4", shell_output("#{bin}/git-coauthor --version")
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
