# lo

`lo` is the command-line client of myvcs, a version control system where history lives on a server. This repository holds its releases; the source is developed elsewhere.

## Install

Linux and macOS:

```sh
curl -fsSL https://github.com/AdhishaInd/lo-releases/releases/latest/download/install.sh | sh
```

Windows (PowerShell):

```powershell
irm https://github.com/AdhishaInd/lo-releases/releases/latest/download/install.ps1 | iex
```

Later, `lo upgrade` moves to the latest release.

The scripts install for your user only, and check each download against the release's `SHA256SUMS`. Set `LO_INSTALL_DIR` to pick the directory, or `LO_VERSION` to pick a release.

## Builds

| System | Architectures |
|---|---|
| Linux (static, any distribution) | x86-64, arm64 |
| macOS | x86-64, Apple Silicon |
| Windows | x86-64 (also runs on Windows on Arm) |

Linux releases also carry `myvcsd`, the server.

Builds aren't signed yet. Installing with the commands above avoids most warnings; a browser download on macOS or Windows will warn until signing is set up.

## Checking a build

Each binary has a build provenance attestation:

```sh
gh attestation verify lo-x86_64-unknown-linux-musl -R AdhishaInd/lo-releases
```

## First use

```sh
lo login https://your.server
lo get https://your.server/project
cd project
# edit files, then:
lo save -m "Work in progress"
lo commit -m "Done"
```

`lo --help` has the rest.
