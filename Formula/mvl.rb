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
  url "https://github.com/mvl-lang/mvl/archive/refs/tags/v1.6.0.tar.gz"
  sha256 "0349172041387efaabfa94459b68e37afbadee9edd3c376043aaf69f765cfe53"
  version "1.6.0"
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
    system "cargo", "build", "--release", "--workspace"

    # The runtime crates are versioned independently from the compiler
    # (see repo Makefile INSTALL_RUNTIME_VERSION).  The compiler binary
    # bakes `MVL_RUNTIME_VERSION` in via build.rs by reading
    # runtime/rust/Cargo.toml, so the installed runtime directory MUST
    # be keyed on that version — using `#{version}` (compiler version)
    # here made `mvl doctor` report every runtime artifact as missing
    # (mvl-lang/homebrew-mvl#1).
    runtime_version = File.read("runtime/rust/Cargo.toml")
                          .match(/^version\s*=\s*"([^"]+)"/)[1]

    # 2. Real binary goes to libexec; a wrapper in bin/ sets MVL_HOME.
    libexec.install "target/release/mvl"

    # 3. Stdlib.  Layout expected by the compiler at runtime:
    #      $MVL_HOME/toolchains/<compiler_version>/std/*.mvl
    #    Plus a `.version` marker that `mvl doctor` checks for as its
    #    "stdlib is present" signal — mirrors the repo's `make install`
    #    behaviour.
    stdlib_target = share/"mvl/toolchains/#{version}/std"
    stdlib_target.install Dir["std/*.mvl"], *Dir["std/*"].select { |p| File.directory?(p) }
    (stdlib_target/".version").write("#{version}\n")

    # 4. Runtime.  Three sibling directories under runtime/<runtime_version>/
    #    — rust (default), rust-tokio (async target), llvm (cdylib for the
    #    LLVM backend).  The LLVM cdylib is built by step 1 above and lives
    #    under target/release/ regardless of platform.
    rust_dst = share/"mvl/runtime/#{runtime_version}/rust"
    rust_dst.install Dir["runtime/rust/*"]

    if File.directory?("runtime/rust-tokio")
      tokio_dst = share/"mvl/runtime/#{runtime_version}/rust-tokio"
      tokio_dst.install Dir["runtime/rust-tokio/*"]
    end

    llvm_dst = share/"mvl/runtime/#{runtime_version}/llvm"
    llvm_dst.mkpath
    %w[
      target/release/libmvl_runtime_llvm.dylib
      target/release/libmvl_runtime_llvm.so
    ].each do |candidate|
      llvm_dst.install candidate if File.exist?(candidate)
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

    # 2. `mvl doctor` must report all artifacts present — this is the
    #    regression check for mvl-lang/homebrew-mvl#1 (stdlib .version
    #    marker + runtime keyed on MVL_RUNTIME_VERSION + LLVM cdylib).
    doctor_out = shell_output("#{bin}/mvl doctor")
    assert_match "All artifacts present", doctor_out

    # 3. Type-check a trivial program.  Uses `check` so we don't need
    #    cargo at test time (`run`/`build` would).
    (testpath/"hello.mvl").write <<~MVL
      fn main() -> Unit ! Console {
          println("hello, brew")
      }
    MVL

    system bin/"mvl", "check", testpath/"hello.mvl"
  end
end