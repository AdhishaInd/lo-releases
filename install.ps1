# Installs lo, the myvcs client, for this user:
#   irm -MaximumRedirection 0 https://raw.githubusercontent.com/AdhishaInd/lo-releases/main/install.ps1 | iex
# $env:LO_INSTALL_DIR picks the directory (default %LOCALAPPDATA%\Programs\lo),
# $env:LO_VERSION a release (default latest).
# In a scope of its own: `iex` would leave its settings and functions in the user's session.
& {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    $releases = if ($env:LO_RELEASES_URL) { $env:LO_RELEASES_URL } else { 'https://github.com/AdhishaInd/lo-releases/releases' }
    $dir = if ($env:LO_INSTALL_DIR) { $env:LO_INSTALL_DIR } else { Join-Path $env:LOCALAPPDATA 'Programs\lo' }
    # What's downloaded is run, and its checksum comes from the same place.
    # The parsed host counts, not how the URL starts: http://localhost:a@evil.example is evil.example.
    function Test-Secure($url) {
        $u = $null
        if (-not [Uri]::TryCreate($url, [UriKind]::Absolute, [ref]$u)) { return $false }
        if ($u.Scheme -eq 'https') { return $true }
        return ($u.Scheme -eq 'http') -and ($u.Host -eq '127.0.0.1' -or $u.Host -eq 'localhost')
    }

    # Windows PowerShell follows a redirect from https to http with no way to forbid it, so
    # redirects are followed here, each one checked.
    function Save-Download($url, $file) {
        for ($hop = 0; $hop -lt 10; $hop++) {
            if (-not (Test-Secure $url)) { throw "not downloading a program from ${url}: it has to be https" }
            $request = [Net.WebRequest]::Create($url)
            $request.AllowAutoRedirect = $false
            $request.UserAgent = 'lo-install'
            try {
                $response = $request.GetResponse()
            } catch [Net.WebException] {
                $response = $_.Exception.Response
                if (-not $response) { throw }
            }
            try {
                $status = [int]$response.StatusCode
                if ($status -ge 300 -and $status -lt 400) {
                    $location = $response.Headers['Location']
                    if (-not $location) { throw "$url redirects nowhere" }
                    $url = (New-Object Uri ([Uri]$url), $location).AbsoluteUri
                    continue
                }
                if ($status -ne 200) { throw "$url answered $status" }
                $out = [IO.File]::Create($file)
                try { $response.GetResponseStream().CopyTo($out) } finally { $out.Dispose() }
                return
            } finally {
                $response.Dispose()
            }
        }
        throw "$url redirects too many times"
    }

    if (-not (Test-Secure $releases)) {
        throw "not downloading a program from ${releases}: it has to be https"
    }
    # The x64 build also runs on Windows on Arm.
    $asset = 'lo-x86_64-pc-windows-msvc.exe'

    if (-not $env:LO_VERSION -or $env:LO_VERSION -eq 'latest') {
        $from = "$releases/latest/download"
    } elseif ($env:LO_VERSION.StartsWith('v')) {
        $from = "$releases/download/$($env:LO_VERSION)"
    } else {
        $from = "$releases/download/v$($env:LO_VERSION)"
    }

    $tmp = Join-Path ([IO.Path]::GetTempPath()) ("lo-install-" + [Guid]::NewGuid())
    New-Item -ItemType Directory -Path $tmp | Out-Null
    try {
        $new = Join-Path $tmp 'lo.exe'
        $sums = Join-Path $tmp 'SHA256SUMS'
        Write-Host "Downloading $asset from $from"
        Save-Download "$from/$asset" $new
        Save-Download "$from/SHA256SUMS" $sums

        $want = $null
        foreach ($line in Get-Content $sums) {
            $parts = $line -split '\s+'
            if ($parts.Count -ge 2 -and $parts[1].TrimStart('*') -eq $asset) { $want = $parts[0] }
        }
        if (-not $want) { throw "the release lists no checksum for $asset" }
        $got = (Get-FileHash -Algorithm SHA256 $new).Hash
        if ($got -ine $want) { throw "checksum mismatch for ${asset}: got $got, expected $want" }

        $version = & $new --version
        if ($LASTEXITCODE -ne 0) { throw "the downloaded lo doesn't run on this system" }

        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        $target = Join-Path $dir 'lo.exe'
        # Beside the target first: from there, moving it can't run out of space.
        $staged = Join-Path $dir ".lo-new-$PID.exe"
        Move-Item -Force $new $staged
        # A running program can be renamed, not overwritten.
        $old = $null
        if (Test-Path $target) {
            Get-ChildItem -Force $dir -Filter '.lo-old-*' | Remove-Item -Force -ErrorAction SilentlyContinue
            $old = Join-Path $dir ".lo-old-$PID.exe"
            Move-Item -Force $target $old
        }
        try {
            Move-Item -Force $staged $target
        } catch {
            if ($old) { Move-Item -Force $old $target }
            Remove-Item -Force $staged -ErrorAction SilentlyContinue
            throw
        }
        Write-Host "Installed $version to $target"

        $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        if (-not (($userPath -split ';') -contains $dir)) {
            [Environment]::SetEnvironmentVariable('Path', ($(if ($userPath) { "$userPath;" } else { '' }) + $dir), 'User')
            $env:Path = "$env:Path;$dir"
            Write-Host "Added $dir to your PATH. Terminals already open need restarting."
        }
    } finally {
        Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    }
}
