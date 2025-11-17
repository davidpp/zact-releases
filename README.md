# ZACT Binary Releases

Pre-built binaries for ZACT v2 - Zero-Abstraction Code Tools.

## Installation

### macOS (One-line installer)
```bash
curl -fsSL https://raw.githubusercontent.com/davidpp/zact-releases/main/install.sh | bash
```

### Manual Installation

Download the appropriate binary for your system from the [latest release](https://github.com/davidpp/zact-releases/releases/latest):

- **Intel Macs (x86_64)**: `zact-macos-x86_64.tar.gz`
- **Apple Silicon (M1/M2/M3)**: `zact-macos-arm64.tar.gz`

Extract and install:
```bash
tar -xzf zact-macos-*.tar.gz
sudo mv zact-macos-* /usr/local/bin/zact
chmod +x /usr/local/bin/zact
```

## Supported Platforms

Currently supported:
- macOS (Intel and Apple Silicon)

Coming soon:
- Linux (x86_64, arm64)
- Windows (x86_64)

## Verification

All binaries include SHA256 checksums for verification. Download `checksums.txt` from the release and run:

```bash
shasum -a 256 -c checksums.txt
```

## Usage

After installation, verify it works:

```bash
zact --version
zact --help
```

## About ZACT

ZACT (Zero-Abstraction Code Tools) is a namespace-first AI agent framework built on llmz, designed for building composable, maintainable AI-powered development tools.

## License

MIT License - See [LICENSE](LICENSE) for details.
