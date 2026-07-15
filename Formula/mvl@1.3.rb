class MvlAT13 < Formula
  desc "Maximum Verifiable Language — compiler (v1.3.x line)"
  homepage "https://mvl-lang.org"
  license "Apache-2.0"

  # v1.3.x builds from source.  Track the highest patch in the 1.3
  # line — bump the URL/SHA/version fields when 1.3.4 lands.  Kept
  # as a keg-only versioned formula so it can coexist with the
  # current-line `mvl` formula, which will move to 2.x eventually.
  url "https://github.com/mvl-lang/mvl/archive/refs/tags/v1.3.3.tar.gz"
  sha256 "5b62cd7a1e113ef28df34dca594a19d0203e083cfc86530b1712204909d1113c"
  version "1.3.3"

  depends_on "rust" => :build
  depends_on "z3"

  # Versioned formula — not on PATH by default so users can pin the
  # 1.3 line independently of whatever the current `mvl` formula
  # ships.  Opt in with `brew link mvl@1.3`.
  keg_only :versioned_formula

  def install
    system "cargo", "build", "--release"

    libexec.install "target/release/mvl"

    stdlib_target = share/"mvl/toolchains/#{version}/std"
    stdlib_target.install Dir["std/*.mvl"], *Dir["std/*"].select { |p| File.directory?(p) }

    (share/"mvl/runtime/#{version}/rust").install Dir["runtime/rust/*"]
    if File.directory?("runtime/rust-tokio")
      (share/"mvl/runtime/#{version}/rust-tokio").install Dir["runtime/rust-tokio/*"]
    end

    (bin/"mvl").write_env_script libexec/"mvl",
      MVL_HOME: "#{share}/mvl"
  end

  def caveats
    <<~EOS
      MVL v#{version} is installed as a keg-only versioned formula.
      It is NOT on your PATH by default (that slot belongs to the
      current `mvl`).  To use it:

        # Option A — run via full path
        #{opt_bin}/mvl --version

        # Option B — link it into PATH (unlinks the current `mvl`)
        brew unlink mvl && brew link mvl@1.3

      Stdlib + runtime live under: #{share}/mvl
      MVL_HOME is set automatically by the wrapper in bin/mvl.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/mvl --version")

    (testpath/"hello.mvl").write <<~MVL
      fn main() -> Unit ! Console {
          println("hello from mvl@1.3")
      }
    MVL

    system bin/"mvl", "check", testpath/"hello.mvl"
  end
end
