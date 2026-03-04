using namespace System.Collections.Generic

<#
.SYNOPSIS
    This will build the local jekyll docs using 'bundle' and then host on localhost with live reload
.NOTES
    Set $Jekyll_BuildCfg.DocsRoot and the rest should run off of defaults and _config.yml

    Example directory layout from git clone:

        > pushd 'H:/data/2023/my_git'
        > gh repo clone GitLogging/GitLoggerDocs
        > pushd 'GitLoggerDocs'
        > . ./Start-StartDocsLocalhost.ps1
#>
if(-not (gcm 'bundle' -ea ignore)) {
    # $Env:PATH += ([IO.Path]::PathSeparator), (gi -ea stop 'C:\Ruby34-x64\bin') -join ''
    $Env:Path = $Env:Path, 'C:\Ruby34-x64\bin' -join ([IO.Path]::PathSeparator)
}


$Jekyll_BuildCfg = @{
    LiveReload = $true
    AutoOpen   = $True
    DocsRoot = gi $PSScriptRoot #'H:/data/2023/my_git/GitLoggerDocs' # base dir for jekyll source
    # current filepath: H:/data/2023/my_git/GitLoggerDocs/Start-StartDocsLocalhost.ps1
    Watch = $true
    IncrementalBuild = $true
    JekyllEnv = 'development' # 'production'
    Host = 'localhost'
    Port = '4000'
    StartingUrlPath = 'http://localhost:4000/GitLogger-Metrics'
}

"Using `$Jekyll_BuildCfg in `"$PSCommandPath`"" | write-verbose -verb
$Jekyll_BuildCfg | ft -auto

$BinBundle = Get-Command -CommandType Application -Name 'bundle' -ea 'stop' -TotalCount 1
if( ! $binBundle ) {
    throw 'Ruby binary "bundle" was not found in $Env:Path !'
}
if( ! (Test-Path $Jekyll_BuildCfg.DocsRoot)) {
    throw ( 'Directory $Jekyll_BuildCfg.DocsRoot did not exist, `$Jekyll_BuildCfg.DocsRoot = {0}.' -f @(
        $Jekyll_BuildCfg.DocsRoot ))
}
$Jekyll_BuildCfg.StaticSiteRoot = gi -ea 'stop' (Join-Path $Jekyll_BuildCfg.DocsRoot 'docs')
if(-not (Test-Path $Jekyll_BuildCfg.StaticSiteRoot)) {
    mkdir -Path $Jekyll_BuildCfg.StaticSiteRoot
}

# Pushd -stack 'jekyll'
Push-Location -stack 'jekyll' $Jekyll_BuildCfg.StaticSiteRoot

# others: '--incremental'
if ($Jekyll_BuildCfg.AutoOpen) {
    sleep -Seconds 7
    try {
        Start-Process -FilePath 'http://localhost:4000' -ErrorAction Stop
    }
    catch {
        Write-Warning ("Unable to auto-open browser: {0}" -f $_.Exception.Message)
    }
}

'Jekyll "bundle" Build Options: <https://jekyllrb.com/docs/configuration/options/>' | write-verbose -verbose
# build site, defaults to live reload 2023-10-01
[List[Object]]$binArgs = @()

#  function GLDocs.Jekyll.BuildArgs {
    $binArgs.AddRange(@(
        'exec', 'jekyll', 'serve' ))

    if( $Jekyll_BuildCfg.LiveReload) {
         $binArgs.AddRange(@(
            '--livereload' ))
    }
    if ($Jekyll_BuildCfg.Watch) {
        $binArgs.Add('--watch')
    }
    else {
        $binArgs.Add('--no-watch')
    }

    $PortArg = if ([string]::IsNullOrWhiteSpace($Jekyll_BuildCfg.Port)) { '4000' } else { [string]$Jekyll_BuildCfg.Port }
    $HostArg = if ([string]::IsNullOrWhiteSpace($Jekyll_BuildCfg.Host)) { 'localhost' } else { [string]$Jekyll_BuildCfg.Host }
    $binArgs.AddRange(@(
        '--port', $PortArg,
        '--host', $HostArg
    ))

    if($Jekyll_BuildCfg.IncrementalBuild) {
        $binArgs.AddRange(@(
            '--incremental' ))
    }

# $binArgs | Join-String -sep ' ' -op 'bundleArgs: ' | Dotils.Write-DimText | Infa
Write-Verbose ("InvokeNativeCommand: bundle => {0}" -f ($binArgs -join ' ')) -Verbose

& $BinBundle @binArgs



Pop-Location -stack 'jekyll'
