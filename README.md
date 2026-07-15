# homebrew-mvl

Homebrew tap for the [MVL (Maximum Verifiable Language)](https://mvl-lang.org) compiler.

## Install

```bash
brew tap mvl-lang/mvl
brew install mvl
```

Verify:

```bash
mvl --version    # → mvl 1.0.0
mvl --help
```

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

## What this tap installs

- `mvl` — the compiler binary (in `bin/`, wrapped so `MVL_HOME` is set automatically)
- Standard library — under `share/mvl/toolchains/<version>/std/`
- Rust FFI runtime — under `share/mvl/runtime/<version>/`

The wrapper in `bin/mvl` sets `MVL_HOME=<prefix>/share/mvl` so the compiler can locate the stdlib and runtime without any manual configuration.

## Platform support

| Platform | Status |
|----------|--------|
| macOS on Apple Silicon (arm64) | ✅ Prebuilt binary |
| macOS on Intel (x86_64) | ⏳ Not yet — build from source not wired up |
| Linux (x86_64) | ⏳ Not yet |
| Linux (aarch64) | ⏳ Not yet |
| Windows | Use WSL2 + Linux build once available |

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
