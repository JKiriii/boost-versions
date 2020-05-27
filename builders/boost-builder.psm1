class BoostBuilder {
    <#
    .SYNOPSIS
    Base Boost builder class.

    .DESCRIPTION
    Base Boost builder class that contains general builder methods.

    .PARAMETER Version
    The version of Boost that should be built.

    .PARAMETER Platform
    The platform of Boost that should be built.

    .PARAMETER Architecture
    The architecture with which Boost should be built.

    .PARAMETER TempFolderLocation
    The location of temporary files that will be used during Boost package generation. Using system BUILD_STAGINGDIRECTORY variable value.

    .PARAMETER ArtifactLocation
    The location of generated Boost artifact. Using system environment BUILD_BINARIESDIRECTORY variable value.

    .PARAMETER InstallationTemplatesLocation
    The location of installation script template. Using "installers" folder from current repository.

    #>

    [version] $Version
    [string] $Platform
    [string] $Architecture
    [string] $Toolset
    [string] $TempFolderLocation
    [string] $WorkFolderLocation
    [string] $ArtifactFolderLocation
    [string] $InstallationTemplatesLocation

    BoostBuilder ([version] $version, [string] $platform, [string] $architecture, [string] $toolset) {
        $this.Version = $version
        $this.Platform = $platform
        $this.Architecture = $architecture
        $this.Toolset = $toolset

        $this.TempFolderLocation = [IO.Path]::GetTempPath()
        $this.WorkFolderLocation = $env:BUILD_BINARIESDIRECTORY
        $this.ArtifactFolderLocation = $env:BUILD_STAGINGDIRECTORY

        $this.InstallationTemplatesLocation = Join-Path -Path $PSScriptRoot -ChildPath "../installers"
    }

    [void] Download() {
        <#
        .SYNOPSIS
        Download Boost source code.
        #>

        $gitArguments = @(
            "clone"
            "https://github.com/boostorg/boost.git",
            $this.WorkFolderLocation,
            "--branch", "boost-$($this.Version)",
            "--single-branch",
            "--recursive"
        ) -join " "
        Execute-Command "git $gitArguments"

        Write-Host "Removing .git subfolder to reduce artifact size..."
        $gitFolder = Join-Path $this.WorkFolderLocation ".git"
        Remove-Item $gitFolder -Recurse -Force
    }

    [void] Build() {
        <#
        .SYNOPSIS
        Generates Boost artifact from downloaded binaries.
        #>

        Write-Host "Download Boost $($this.Version) source code..."
        $this.Download()

        Write-Host "Build source code..."
        $this.Make()

        Write-Host "Create installation script..."
        $this.CreateInstallationScript()

        Write-Host "Archive artifact..."
        $this.ArchiveArtifact()
    }
}