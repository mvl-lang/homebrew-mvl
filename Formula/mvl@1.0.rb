class MvlAT10 < Formula
  desc "Maximum Verifiable Language — compiler (v1.0.x line)"
  homepage "https://mvl-lang.org"
  license "Apache-2.0"

  # v1.0.x builds from source.  We initially tried the prebuilt
  # binary attached to the v1.0.0 release, but it was linked
  # against libz3.4.15 — the current Homebrew z3 is 4.16.  ABI
  # drift makes the pinned binary unusable on modern installs.
  # Building from source at the v1.0.0 tag against whatever z3
  # Homebrew currently ships is the robust choice.
  url "https://github.com/mvl-lang/mvl/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "f7eaa0f9ab4fe741ea9459d1576a8ac320cee784ce3eb83297fc7e5be7b647ea"
  version "1.0.0"

  depends_on "rust" => :build
  depends_on "z3"

  # Kept as a keg-only versioned formula so `mvl@1.0` and the
  # current-line `mvl` coexist.  Users opt in with
  # `brew link mvl@1.0` or invoke the full opt/-path.
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
        brew unlink mvl && brew link mvl@1.0

      Stdlib + runtime live under: #{share}/mvl
      MVL_HOME is set automatically by the wrapper in bin/mvl.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/mvl --version")

    (testpath/"hello.mvl").write <<~MVL
      fn main() -> Unit ! Console {
          println("hello from mvl@1.0")
      }
    MVL

    system bin/"mvl", "check", testpath/"hello.mvl"
  end
end
