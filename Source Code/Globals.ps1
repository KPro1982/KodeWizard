#--------------------------------------------
# Declare Global Variables and Functions here
#--------------------------------------------


#Sample function that provides the location of the script
function Get-ScriptDirectory
{
<#
	.SYNOPSIS
		Get-ScriptDirectory returns the proper location of the script.

	.OUTPUTS
		System.String
	
	.NOTES
		Returns the correct path within a packaged executable.
#>
	[OutputType([string])]
	param ()
	if ($null -ne $hostinvocation)
	{
		Split-Path $hostinvocation.MyCommand.path
	}
	else
	{
		Split-Path $script:MyInvocation.MyCommand.Path
	}
}

#Sample variable that provides the location of the script
[string]$ScriptDirectory = Get-ScriptDirectory


function Start-Kodeindex
{
	[CmdletBinding()]
	param ()
	
	
	$indexpath = Get-HtmlFolder
	$indexpath = Add-Folder -Source $indexpath -Folder "index.html"
	Start-Process "$indexpath"
}

function Get-HtmlFolder
{
	[CmdletBinding()]
	[OutputType([string])]
	param ()
	
	$kodewizardf = Get-ScriptDirectory
	$curfolder = Read-FinalPathName -Source $kodewizardf
	if ($curfolder -eq "Source Code")
	{
		$kodewizardf = $kodewizardf.TrimEnd('Source Code')
		$kodewizardf = $kodewizardf.TrimEnd('\')
	}
	
	$htmlf = Add-Folder -Source $kodewizardf -Folder "Doxy\html"
	return $htmlf
}
function Read-FinalPathName
	{
		[CmdletBinding()]
		param
		(
			[string]$Source
		)
		
		$Source = $Source -replace '/', '\'
		$SourceArr = $Source.Split('\')
		$lasttoken = ""
		$lasttoken = $SourceArr.get($SourceArr.Length - 1)
		return $lasttoken
	}
	
	# Safely add new folder to path
	function Add-Folder
	{
		[CmdletBinding()]
		[OutputType([string])]
		param
		(
			[Parameter(Mandatory = $true)]
			[string]$Source,
			[Parameter(Mandatory = $true)]
			[string]$Folder
		)
		
		# check for terminal \
		$Source = $Source.TrimEnd('\')
		$Folder = $Folder.TrimStart('\')
		
		$newfolder = $Source + "\" + $Folder
		
		return $newfolder
}

function Start-dngrep
{
	[CmdletBinding()]
	param
	(
		[string]$path,
		[string]$searchFor
	)
	
	if (-not $path)
	{
		$path = Read-GlobalParam -key "dngreppath"
	}
	$searchfor = "-searchFor " + $searchFor
	$scriptfolder = Read-GlobalParam -key "scriptfolder"
	$searchfolder = "-folder " + $scriptfolder
	$params = $searchfolder, $searchfor
	Write-GlobalParam -key "searchfor" -value $searchfor
	Start-Process $path $params
}
function Get-Settings
{
	[CmdletBinding()]
	[OutputType([hashtable])]
	param
	(
		[string]$settingname,
		[string]$settingpath
	)
	
	if (-not $settingpath)
	{
		$settingpath = Get-ScriptDirectory
	}
	
	$fullsettingpath = Add-Folder -Source $settingpath -Folder "$settingname"
	
	$hashtable = @{ }
	
	if (-not (Test-Path -Path $fullsettingpath))
	{
		
		New-Item -Path $fullsettingpath -ItemType File
	}
	
	
	$json = Get-Content $fullsettingpath | Out-String
	
	if ($json)
	{
		(ConvertFrom-Json $json).psobject.properties | Foreach { $hashtable[$_.Name] = $_.Value }
	}
	
	
	
	
	Return $hashtable
}
function Set-Settings
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[string]$settingname,
		[Parameter(Mandatory = $true)]
		[string]$key,
		[Parameter(Mandatory = $true)]
		[AllowEmptyString()]
		[string]$value,
		[string]$settingpath
	)
	
	
	
	if ($settingpath)
	{
		if (-not (Test-Path -Path $settingpath))
		{
			New-Item -Path $settingpath -ItemType Directory
		}
		
		
	}
	else
	{
		$settingpath = Get-ScriptDirectory
		
	}
	$fullsettingpath = Add-Folder -Source $settingpath -Folder $settingname
	if (Test-Path -Path $fullsettingpath)
	{
		$hashtable = Get-Settings -settingpath $settingpath -settingname $settingname
	}
	else
	{
		$hashtable = @{ }
	}
	
	
	
	
	$hashtable[$key] = $value
	$hashtable | ConvertTo-Json | Set-Content $fullsettingpath
}

function Read-GlobalParam
{
	[CmdletBinding()]
	[OutputType([string])]
	param
	(
		[Parameter(Mandatory = $true)]
		[string]$key
	)
	
	$hashtable = Get-Settings -settingname "GlobalSettings.json"
	$value = $hashtable[$key]
	return $value
}
function Write-GlobalParam
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$key,
		[Parameter(Mandatory = $true)]
		[AllowEmptyString()]
		[string]$value
	)
	
	Set-Settings -settingname "GlobalSettings.json" -key $key -value $value
}

