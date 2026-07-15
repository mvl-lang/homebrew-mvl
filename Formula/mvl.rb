class Mvl < Formula
  desc "Maximum Verifiable Language — compiler that verifies 11 properties"
  homepage "https://mvl-lang.org"
  license "Apache-2.0"

  # Build from source at every tagged release.  This is more resilient
  # than depending on prebuilt binary/stdlib/runtime tarballs being
  # attached to each GitHub release — a bare `git tag && push` gives
  # us an installable version, no separate publish pipeline required.
  #
  # Pre-built binary bottles can be layered on top later as a speed
  # optimization; the source path is the honest default.
  url "https://github.com/mvl-lang/mvl/archive/refs/tags/v1.3.3.tar.gz"
  sha256 "5b62cd7a1e113ef28df34dca594a19d0203e083cfc86530b1712204909d1113c"
  version "1.3.3"
  head "https://github.com/mvl-lang/mvl.git", branch: "main"

  # Build dependencies — needed only to compile MVL, not to run it.
  depends_on "rust" => :build

  # Runtime dependency — the built binary links against libz3 at
  # runtime for the refinement solver's z3-sys backend.  Homebrew's
  # z3 layout matches what mvl's .cargo/config.toml expects
  # (/opt/homebrew/include/z3.h + /opt/homebrew/lib/libz3.dylib).
  depends_on "z3"

  def install
    # 1. Build the compiler with default features (includes z3-sys).
    #    The mvl repo's .cargo/config.toml pre-configures the header
    #    and library paths for Homebrew's z3 install location, so no
    #    extra env vars are needed here.
    system "cargo", "build", "--release"

    # 2. Real binary goes to libexec; a wrapper in bin/ sets MVL_HOME.
    libexec.install "target/release/mvl"

    # 3. Stdlib.  Layout expected by the compiler at runtime:
    #      $MVL_HOME/toolchains/<compiler_version>/std/*.mvl
    stdlib_target = share/"mvl/toolchains/#{version}/std"
    stdlib_target.install Dir["std/*.mvl"], *Dir["std/*"].select { |p| File.directory?(p) }

    # 4. Runtime.  Two sibling directories under runtime/ — install
    #    both preserving their names, matching the pre-source
    #    tarball layout the compiler expects.
    (share/"mvl/runtime/#{version}/rust").install Dir["runtime/rust/*"]
    if File.directory?("runtime/rust-tokio")
      (share/"mvl/runtime/#{version}/rust-tokio").install Dir["runtime/rust-tokio/*"]
    end

    # 5. Wrap `mvl` so users don't have to export MVL_HOME manually.
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

    # 2. Type-check a trivial program via stdin.  Uses `check` so we
    #    don't need cargo at test time (`run`/`build` would).
    (testpath/"hello.mvl").write <<~MVL
      fn main() -> Unit ! Console {
          println("hello, brew")
      }
    MVL

    system bin/"mvl", "check", testpath/"hello.mvl"
  end
end
