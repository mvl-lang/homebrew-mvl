class MvlAT17 < Formula
  desc "Maximum Verifiable Language — compiler (v1.7.x line)"
  homepage "https://mvl-lang.org"
  license "Apache-2.0"

  # v1.7.x builds from source.  Track the highest patch in the 1.7
  # line — bump the URL/SHA/version fields when 1.7.1 lands.  Kept
  # as a keg-only versioned formula so it can coexist with the
  # current-line `mvl` formula.
  url "https://github.com/mvl-lang/mvl/archive/refs/tags/v1.7.0.tar.gz"
  sha256 "f558174ad29f3af9123e691f7969e01f075b861aef9a8ac7f6dedc622582ce75"
  version "1.7.0"

  keg_only :versioned_formula

  depends_on "rust" => :build
  depends_on "z3"

  def install
    runtime_version = File.read("runtime/rust/Cargo.toml")
                          .match(/^version\s*=\s*"([^"]+)"/)[1]

    libexec.install "target/release/mvl"

    stdlib_target = share/"mvl/toolchains/#{version}/std"
    stdlib_target.install Dir["std/*.mvl"], *Dir["std/*"].select { |p| File.directory?(p) }
    (stdlib_target/".version").write("#{version}\n")

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

    (bin/"mvl@1.6").write_env_script libexec/"mvl",
      MVL_HOME: "#{share}/mvl"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/mvl@1.6 --version")
  end
end