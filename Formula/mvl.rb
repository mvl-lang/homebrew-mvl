class Mvl < Formula
  desc "Maximum Verifiable Language — compiler that verifies 11 properties"
  homepage "https://mvl-lang.org"
  license "Apache-2.0"
  version "1.0.0"

  # Only Apple Silicon binary is published today.  Other platforms build
  # from source (add depends_on "rust" => :build below when you extend this).
  on_macos do
    on_arm do
      url "https://github.com/mvl-lang/mvl/releases/download/v1.0.0/mvl-v1.0.0-aarch64-apple-darwin.tar.gz"
      sha256 "a453fe6137c2cb025fa60220731766d6e999422300caefaf5178bf5a16280b49"
    end
  end

  # Standard library — installed alongside the compiler under share/mvl/.
  # Downloaded as a separate resource so both artifacts stay in lockstep
  # with the compiler version tag.
  resource "stdlib" do
    url "https://github.com/mvl-lang/mvl/releases/download/v1.0.0/mvl-stdlib-1.0.0.tar.gz"
    sha256 "8e61dea7702469630fd87798978b754108f5c2457b9f676176af32842f3eba30"
  end

  # Rust FFI runtime — required by `mvl build` when transpiling to Rust.
  resource "runtime" do
    url "https://github.com/mvl-lang/mvl/releases/download/v1.0.0/mvl-runtime-1.0.0.tar.gz"
    sha256 "b4b31d5cd853cba0f959c1834de0271d9404b613db061a3bd49a2154bf9d5f9f"
  end

  def install
    # 1. The real binary lives in libexec; a wrapper in bin/ sets MVL_HOME.
    libexec.install "mvl"

    # 2. Stdlib layout expected by the compiler:
    #      $MVL_HOME/toolchains/<compiler_version>/std/*.mvl
    resource("stdlib").stage do
      (share/"mvl/toolchains/#{version}").install "std"
    end

    # 3. Runtime layout — Rust FFI bridge lives under runtime/<version>/.
    #    Sub-directory is `rust/` inside the tarball.
    resource("runtime").stage do
      (share/"mvl/runtime/#{version}").install "rust"
    end

    # 4. Wrap `mvl` so users don't have to export MVL_HOME manually.
    (bin/"mvl").write_env_script libexec/"mvl",
      MVL_HOME: "#{share}/mvl"
  end

  def caveats
    <<~EOS
      MVL is installed. The stdlib and runtime live under:
        #{share}/mvl

      MVL_HOME is set automatically by the wrapper in #{bin}/mvl.
      If you invoke the binary directly (#{libexec}/mvl), you must
      set MVL_HOME=#{share}/mvl yourself.

      Try it:
        echo 'fn main() -> Unit ! Console { println("hello, brew") }' | mvl check --stdin
    EOS
  end

  test do
    # 1. `--version` should print a semver-shaped string.
    assert_match version.to_s, shell_output("#{bin}/mvl --version")

    # 2. Type-check a trivial program via stdin.  Uses --stdin flag so we
    #    don't need to touch the filesystem.  Exit 0 = well-typed.
    (testpath/"hello.mvl").write <<~MVL
      fn main() -> Unit ! Console {
          println("hello, brew")
      }
    MVL

    # Use `mvl check` for the smoke test — `mvl run` requires a full Rust
    # toolchain which may not be present in the CI test environment.
    system bin/"mvl", "check", testpath/"hello.mvl"
  end
end
