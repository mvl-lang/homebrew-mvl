class MvlAT10 < Formula
  desc "Maximum Verifiable Language — compiler (v1.0.x line)"
  homepage "https://mvl-lang.org"
  license "Apache-2.0"

  # v1.0.x uses the prebuilt binary + resource tarballs attached to
  # the v1.0.0 GitHub release.  Installs in ~1 second (no cargo
  # build needed).  Kept as a keg-only versioned formula so it
  # doesn't collide with the current-line `mvl` formula.
  url "https://github.com/mvl-lang/mvl/releases/download/v1.0.0/mvl-v1.0.0-aarch64-apple-darwin.tar.gz"
  sha256 "a453fe6137c2cb025fa60220731766d6e999422300caefaf5178bf5a16280b49"
  version "1.0.0"

  # Prebuilt binary — no build deps required.  Only the aarch64-apple-
  # darwin tarball was published for v1.0.0 (see mvl-lang/mvl#1809).
  # Users on Intel Mac / Linux / other should use the current `mvl`
  # formula, which builds from source.
  depends_on arch: :arm64
  depends_on :macos

  # This is a versioned formula — Homebrew keeps it out of PATH by
  # default so `mvl@1.0` and `mvl` can coexist.  Users opt in with
  # `brew link mvl@1.0` or invoke `#{HOMEBREW_PREFIX}/opt/mvl@1.0/bin/mvl`.
  keg_only :versioned_formula

  resource "stdlib" do
    url "https://github.com/mvl-lang/mvl/releases/download/v1.0.0/mvl-stdlib-1.0.0.tar.gz"
    sha256 "8e61dea7702469630fd87798978b754108f5c2457b9f676176af32842f3eba30"
  end

  resource "runtime" do
    url "https://github.com/mvl-lang/mvl/releases/download/v1.0.0/mvl-runtime-1.0.0.tar.gz"
    sha256 "b4b31d5cd853cba0f959c1834de0271d9404b613db061a3bd49a2154bf9d5f9f"
  end

  def install
    libexec.install "mvl"

    # Stdlib: tarball has `std/` at top level; Homebrew's stage(target)
    # strips single-dir wrappers, so we stage INTO `std/` explicitly.
    stdlib_target = share/"mvl/toolchains/#{version}/std"
    stdlib_target.mkpath
    resource("stdlib").stage(stdlib_target)

    # Runtime: tarball has TWO top-level dirs (rust/, rust-tokio/) so
    # Homebrew does not strip — stage into runtime/<version>/ directly.
    runtime_target = share/"mvl/runtime/#{version}"
    runtime_target.mkpath
    resource("runtime").stage(runtime_target)

    # Wrap `mvl` so MVL_HOME is set even when users invoke via the full
    # keg-only path.
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
