class GitCoauthor < Formula
  desc "List or add Git coauthors"
  homepage "https://github.com/nicholasdower/git-coauthor"
  url "https://github.com/nicholasdower/git-coauthor/archive/v1.0.0.tar.gz"
  sha256 "ca06c5ced654e79fb4d6111a8e3e46dc3470ad432a5e0e2ee71b58336b7308d9"
  license "MIT"

  def install
    lib.install Dir["lib/*"]
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
