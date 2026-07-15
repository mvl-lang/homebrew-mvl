# homebrew-mvl

Homebrew tap for the [MVL (Maximum Verifiable Language)](https://mvl-lang.org) compiler.

## Install

```bash
brew tap mvl-lang/mvl
brew trust mvl-lang/mvl    # Homebrew 6.x requires trusting third-party taps
brew install mvl
```

Verify:

```bash
mvl --version    # → mvl 1.3.3
mvl --help
```

**Note:** installing takes a few minutes — the formula builds MVL from source. This means every tagged release is installable without waiting for a separate binary publish pipeline. Prebuilt binary bottles will be added later as a speed optimization.

> **Why `brew trust`?** Homebrew 6.0 introduced a trust step for third-party taps to protect users from unreviewed formulae. This is a one-time step per tap. Skipping it and running `brew install mvl` produces an error message telling you exactly what to run.

## First program

```mvl
fn main() -> Unit ! Console {
    println("hello, mvl")
}
```

```bash
echo 'fn main() -> Unit ! Console { println("hello") }' | mvl check --stdin
```

For `mvl run` and `mvl build` you also need a working Rust toolchain (`brew install rust`), because MVL currently transpiles to Rust and invokes `cargo` under the hood.

## Installing a specific version line

The tap ships versioned formulas alongside the latest:

```bash
brew install mvl              # current (whatever we're calling latest — 1.3.3 today)
brew install mvl@1.0          # v1.0.x — prebuilt binary, ~1s install
brew install mvl@1.3          # v1.3.x — build from source
```

Versioned formulas are **keg-only** — they install to their own directory but don't symlink into `bin/` by default. Two use cases:

**Occasional invocation via full path:**

```bash
/opt/homebrew/opt/mvl@1.0/bin/mvl --version    # → mvl 1.0.0
```

**Swap the current PATH-linked version:**

```bash
brew unlink mvl && brew link mvl@1.0    # `mvl` in PATH is now 1.0.0
brew unlink mvl@1.0 && brew link mvl    # back to current
```

Bug fixes for a specific line ship as patch bumps of that versioned formula (e.g., `mvl@1.3` moves from 1.3.3 to 1.3.4 without touching the current `mvl` formula).

## What this tap installs

- `mvl` — the compiler binary (in `bin/`, wrapped so `MVL_HOME` is set automatically)
- Standard library — under `share/mvl/toolchains/<version>/std/`
- Rust FFI runtime — under `share/mvl/runtime/<version>/`

The wrapper in `bin/mvl` sets `MVL_HOME=<prefix>/share/mvl` so the compiler can locate the stdlib and runtime without any manual configuration.

## Platform support

The formula builds MVL from source on any platform Rust and Homebrew's `z3` package support. In practice:

| Platform | Status |
|----------|--------|
| macOS on Apple Silicon (arm64) | ✅ Supported |
| macOS on Intel (x86_64) | ✅ Supported (build-from-source) |
| Linux (x86_64) | ✅ Supported via Homebrew on Linux |
| Linux (aarch64) | ✅ Supported via Homebrew on Linux |
| Windows | Use WSL2 + Linux Homebrew |

More platforms are added as the upstream release pipeline in [`mvl-lang/mvl`](https://github.com/mvl-lang/mvl) publishes binaries for them.

## Alternatives

If you don't want Homebrew (CI, Docker, other package managers):

```bash
curl -fsSL https://mvl-lang.org/install.sh | sh
```

or grab the release tarball directly from [github.com/mvl-lang/mvl/releases](https://github.com/mvl-lang/mvl/releases).

## Updating the formula

Every new upstream release requires:

1. New `url` and `sha256` for the binary tarball (per platform)
2. New `sha256` for the stdlib and runtime resource tarballs
3. Version bump in the `version` line
4. Update this README's `mvl --version` example

Recompute SHAs with:

```bash
curl -sL <release-tarball-url> | shasum -a 256
```

Then run:

```bash
brew audit --strict Formula/mvl.rb
brew install --build-from-source ./Formula/mvl.rb
brew test mvl
```

before pushing.

## License

Apache-2.0. Matches the MVL compiler.

## Support

- MVL bugs → [mvl-lang/mvl](https://github.com/mvl-lang/mvl/issues)
- Tap / formula bugs → [mvl-lang/homebrew-mvl](https://github.com/mvl-lang/homebrew-mvl/issues)
