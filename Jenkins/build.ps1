#Requires -Version 5.0

param
(
    [Parameter()]
    [String[]] $TaskList = @("RestorePackages", "Build", "CopyArtifacts"),
	
    # Also add following parameters: 
    #   Configuration
    #   Platform
    #   OutputPath
    # And use these parameters inside BuildSolution function while calling for MSBuild.
    # Use /p swith to pass the parameter. For example:
    #   MSBuild.exe src/Solution.sln /p:Configuration=$Configuration
    # More info here: https://docs.microsoft.com/en-us/visualstudio/msbuild/common-msbuild-project-properties?view=vs-2017
	
    [Parameter()]
    [String] $BuildArtifactsFolder,
	
	[Parameter()]
    [String] $BuildDLLSFolder = "src/PhpTravels.UITests/bin/Debug/",
	
	[Parameter()]
    [String] $OutputPath = "src/PhpTravels.UITests.sln",
    
	[ValidateSet("Debug", "Release")]
    [String] $Configuration = "Debug",
	
	[ValidateSet("Any CPU", "x86", "x64")]
	[String] $Platform = "Any CPU"
)

$NugetUrl = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
$NugetExe = Join-Path $PSScriptRoot "nuget.exe"
# Define additional variables here (MSBuild path, etc.)

$Solution = Join-Path $PSScriptRoot $OutputPath
$MSBuildPath = "C:/Program Files (x86)/Microsoft Visual Studio/2017/Community/MSBuild/15.0/Bin/MSBuild.exe"

Function DownloadNuGet()
{
    if (-Not (Test-Path $NugetExe)) 
    {
        Write-Output "Installing NuGet from $NugetUrl..."
        Invoke-WebRequest $NugetUrl -OutFile $NugetExe -ErrorAction Stop
    }
}

Function RestoreNuGetPackages()
{
    DownloadNuGet
    Write-Output 'Restoring NuGet packages...'
	Write-Output "Restoring NuGet packages from $Solution..."
    # NuGet.exe call here
	
	# & is the call operator which allows you to execute a command, a script, or a function
    & $NugetExe restore $Solution
}

Function BuildSolution()
{
    Write-Output "Building $Solution solution..."
	Write-Output "MSBuild.exe path $MSBuildPath..."
    # MSBuild.exe call here
	
	& $MSBuildPath $Solution /p:Configuration=$Configuration /p:Platform=$Platform #/p:OutputPath=$BuildArtifactsFolder
}

Function CopyBuildArtifacts()
{
    param
    (
        [Parameter(Mandatory)]
        [String] $SourceFolder,
        [Parameter(Mandatory)]
        [String] $DestinationFolder
    )
	
	$error.clear()
	
	if(Test-Path $DestinationFolder)
	{
		Write-Output "Directory $DestinationFolder exist..."
		Write-Output "Files in $DestinationFolder deleted..."
		
		Remove-Item (Join-Path $DestinationFolder "*")
	}
	else
	{
		Write-Output "Directory $DestinationFolder not exist..."
		Write-Output "Directory $DestinationFolder created..."
		
		New-Item -ItemType "directory" -Path $DestinationFolder
	}
	
	Copy-Item -Path (Join-Path $SourceFolder "*") -Destination $DestinationFolder

    # Copy all files from $SourceFolder to $DestinationFolder
    #
    # Useful commands:
    #   Test-Path - check if path exists
    #   Remove-Item - remove folders/files
    #   New-Item - create folder/file
    #   Get-ChildItem - gets items from specified path
    #   Copy-Item - copies item into destination folder
    #
    #     NOTE: you can chain methods using pipe (|) symbol. For example:
    #           Get-ChildItem ... | Copy-Item ...
    #
    #           which will get items (Get-ChildItem) and will copy them (Copy-Item) to the target folder
}

foreach ($Task in $TaskList) {
    if ($Task.ToLower() -eq 'restorepackages')
    {
        $error.clear()
		RestoreNuGetPackages
		if($error)
		{
			Throw "An error occured while restore NuGet packages."
		}
    }
    if ($Task.ToLower() -eq 'build')
    {
        $error.clear()
		BuildSolution
		if($error)
		{
			Throw "An error occured while copying build solution."
		}
    }
    if ($Task.ToLower() -eq 'copyartifacts')
    {
        $error.clear()
		CopyBuildArtifacts $BuildDLLSFolder $BuildArtifactsFolder
		if($error)
		{
			Throw "An error occured while copying build artifacts."
		}
    }
}