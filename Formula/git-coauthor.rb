class GitCoauthor < Formula
  desc "List or add Git coauthors"
  homepage "https://github.com/nicholasdower/git-coauthor"
  url "https://github.com/nicholasdower/git-coauthor/releases/download/v1.0.0/release.tar.gz"
  sha256 "8ab4717e697d796fc1ff93dc9a3679e21d345e2d0cd7b1c041f68e8ade068784"
  license "MIT"

  def install
    bin.install "bin/git-coauthor"
    man1.install "man/git-coauthor.1"
  end

  test do
    assert_match "git-coauthor", shell_output("#{bin}/git-coauthor --version")
  end

  def caveats
    <<~EOS
      To add the coauthor Git alias:

        git config --global alias.coauthor '!git-coauthor'
    EOS
  end
end
