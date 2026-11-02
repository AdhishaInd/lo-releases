# lo

`lo` is the command-line client of myvcs, a version control system where history lives on a server. This repository holds its releases; the source is developed elsewhere.

## Install

Linux and macOS:

```sh
curl --proto '=https' -fsSL https://github.com/AdhishaInd/lo-releases/releases/latest/download/install.sh | sh
```

In a script, or to check the installer before running it, keep the steps apart: the pipe above reports `sh`'s result, so a failed download can still count as success.

```sh
curl --proto '=https' -fsSLO https://github.com/AdhishaInd/lo-releases/releases/latest/download/install.sh &&
  gh attestation verify install.sh -R AdhishaInd/lo-releases &&
  sh install.sh
```

Windows (PowerShell):

```powershell
irm -MaximumRedirection 0 https://raw.githubusercontent.com/AdhishaInd/lo-releases/main/install.ps1 | iex
```

This address answers without a redirect, and the command refuses any, so nothing can move the download off https. The script checks everything it fetches itself.

In a script, or to check the installer's build provenance before running it:

```powershell
curl.exe --proto '=https' -fsSLO https://github.com/AdhishaInd/lo-releases/releases/latest/download/install.ps1
if (-not $?) { throw "the download failed" }
gh attestation verify install.ps1 -R AdhishaInd/lo-releases
if (-not $?) { throw "the installer couldn't be verified" }
powershell -ExecutionPolicy Bypass -File install.ps1
if (-not $?) { throw "installing failed" }
```

Later, `lo upgrade` moves to the latest release.

The scripts install for your user only, and check each download against the release's `SHA256SUMS`. Set `LO_INSTALL_DIR` to pick the directory, or `LO_VERSION` to pick a release.

## Builds

| System | Architectures |
|---|---|
| Linux (static, any distribution) | x86-64, arm64 |
| macOS | x86-64, Apple Silicon |
| Windows | x86-64 (also runs on Windows on Arm) |

Linux and Windows releases also carry `myvcsd`, the server. On Windows, keep its data on a local NTFS disk.

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
