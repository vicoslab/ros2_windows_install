﻿# Gain Admin permissions
if(!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
 Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList "-File `"$($MyInvocation.MyCommand.Path)`"  `"$($MyInvocation.MyCommand.UnboundArguments)`""
 Exit
}

$DownloadDir = ($env:TEMP + "\ros2_install")
if (-not(Test-Path -Path $DownloadDir)) {
    New-Item -ItemType Directory -Path $DownloadDir
}

# Functions
function Set-Env {
    param (
        $Name,
        $Value
    )
    [Environment]::SetEnvironmentVariable($Name, $Value, "Machine")
}

function Set-Path {
    param (
        $NewPath
    )
    $PATH = $env:Path
    if (-not($PATH.Contains($NewPath))) {
      Set-Env -Name "PATH" -Value ($PATH + ";" + $NewPath)
    }
}

function Download-File {
    param (
        $Uri,
        $OutFile
    )
    if (-not(Test-Path -Path ($DownloadDir + "\" + $OutFile) -PathType Leaf)) {
        Invoke-WebRequest -Uri $Uri -OutFile ($DownloadDir + "\" + $OutFile)
    }
}

function Extract-File { 
    param (
        $File,
        $Dir
    )
    if (-not(Test-Path -Path $Dir)) {
        Expand-Archive -Path ($DownloadDir + "\" + $File) -DestinationPath $Dir
    }
}

# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Python
choco install -y python --version 3.8.3

# Install Visual C++ Redistributables
choco install -y vcredist2013 vcredist140

# Install OpenSSL
choco install -y openssl

# Install Visual Studio Community
$CONFIG = '{
  "version": "1.0",
  "components": [
    "Microsoft.VisualStudio.Component.CoreEditor",
    "Microsoft.VisualStudio.Workload.CoreEditor",
    "Microsoft.VisualStudio.Component.NuGet",
    "Microsoft.VisualStudio.Component.Roslyn.Compiler",
    "Microsoft.VisualStudio.Component.Roslyn.LanguageServices",
    "Microsoft.VisualStudio.ComponentGroup.WebToolsExtensions",
    "Microsoft.VisualStudio.Component.TypeScript.4.3",
    "Microsoft.VisualStudio.Component.JavaScript.TypeScript",
    "Microsoft.Component.MSBuild",
    "Microsoft.VisualStudio.Component.TextTemplating",
    "Microsoft.VisualStudio.Component.Debugger.JustInTime",
    "Component.Microsoft.VisualStudio.LiveShare",
    "Microsoft.VisualStudio.Component.IntelliCode",
    "Microsoft.VisualStudio.Component.VC.CoreIde",
    "Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
    "Microsoft.VisualStudio.Component.Graphics.Tools",
    "Microsoft.VisualStudio.Component.VC.DiagnosticTools",
    "Microsoft.VisualStudio.Component.Windows10SDK.19041",
    "Microsoft.VisualStudio.Component.VC.Redist.14.Latest",
    "Microsoft.VisualStudio.ComponentGroup.NativeDesktop.Core",
    "Microsoft.VisualStudio.Component.VC.ATL",
    "Microsoft.VisualStudio.Component.VC.TestAdapterForBoostTest",
    "Microsoft.VisualStudio.Component.VC.TestAdapterForGoogleTest",
    "Microsoft.VisualStudio.Component.VC.ASAN",
    "Microsoft.VisualStudio.Workload.NativeDesktop"
  ]
}'
Set-Content -Path ($DownloadDir + "\vs_2019_ros2.vsconfig") -Value $CONFIG
if (Test-Path -Path "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community") {
    Start-Process -FilePath 'C:\Program Files (x86)\Microsoft Visual Studio\Installer\vs_installershell.exe' -ArgumentList ("modify --passive --norestart --force --installpath 'C:\Program Files (x86)\Microsoft Visual Studio\2019\Community' --config " + $DownloadDir + "\vs_2019_ros2.vsconfig --remove Microsoft.VisualStudio.ComponentGroup.WebToolsExtensions.CMake --remove Microsoft.VisualStudio.Component.VC.CMake.Project")
} else {
    choco install -y visualstudio2019community  --package-parameters ("--passive --config " + $DownloadDir + "\vs_2019_ros2.vsconfig")
}

# Install OpenCV
$URL = “https://github.com/ros2/ros2/releases/download/opencv-archives/opencv-3.4.6-vc16.VS2019.zip”
$FILE = ”opencv-3.4.6-vc16.VS2019.zip”
$OPENCV_DIR = "C:\"
Download-File -Uri $URL -OutFile $FILE
Extract-File -File $FILE -Dir $OPENCV_DIR
Set-Env -Name "OpenCV_DIR" -Value ($OPENCV_DIR + "opencv")
Set-Path -NewPath "C:\opencv\x64\vc16\bin"

# Install CMake
choco install -y cmake
Set-Path -NewPath "C:\Program Files\CMake\bin"

# Install Dependencies
$baseUri = 'https://github.com/ros2/choco-packages/releases/download/2020-02-24'
$files = @(
    @{
        Uri = "$baseUri/asio.1.12.1.nupkg"
        OutFile = 'asio.1.12.1.nupkg'
    },
    @{
        Uri = "$baseUri/bullet.2.89.0.nupkg"
        OutFile = 'bullet.2.89.0.nupkg'
    },
    @{
        Uri = "$baseUri/cunit.2.1.3.nupkg"
        OutFile = 'cunit.2.1.3.nupkg'
    },
    @{
        Uri = "$baseUri/eigen.3.3.4.nupkg"
        OutFile = 'eigen.3.3.4.nupkg'
    },
    @{
        Uri = "$baseUri/tinyxml-usestl.2.6.2.nupkg"
        OutFile = 'tinyxml-usestl.2.6.2.nupkg'
    },
    @{
        Uri = "$baseUri/tinyxml2.6.0.0.nupkg"
        OutFile = 'tinyxml2.6.0.0.nupkg'
    },
    @{
        Uri = "$baseUri/log4cxx.0.10.0.nupkg"
        OutFile = 'log4cxx.0.10.0.nupkg'
    }
)

foreach ($file in $files) {
    Download-File @file
}
choco install -y -s $DownloadDir asio cunit eigen tinyxml-usestl tinyxml2 log4cxx bullet

python -m pip install -U catkin_pkg cryptography empy ifcfg lark-parser lxml netifaces numpy opencv-python pyparsing==2.4.7 pyyaml setuptools==59.6.0 rosdistro

# Install RQt Dependencies
python -m pip install -U pydot PyQt5
choco install -y graphviz
Set-Path -NewPath "C:\Program Files\Graphviz\bin"

# Install ROS2
$URL = “https://github.com/ros2/ros2/releases/download/release-foxy-20230620/ros2-foxy-20230620-windows-release-amd64.zip”
$FILE = ”ros2-foxy-20230620-windows-release-amd64.zip”
$ROS_DIR = "C:\dev"
$ROS_START = ($ROS_DIR + "\ros2_foxy\local_setup.ps1")
Download-File -Uri $URL -OutFile $FILE
Extract-File -File $FILE -Dir $ROS_DIR
if (Test-Path -Path ($ROS_DIR + "\ros2-windows")) {
    Rename-Item -NewName "ros2_foxy" -Path ($ROS_DIR + "ros2-windows") -Force
}

# Creating Desktop Shortcut
$Link = ([Environment]::GetFolderPath("Desktop") + "\ros2_terminal.lnk")
Remove-Item -Path $Link
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($Link)
$Shortcut.TargetPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
$Shortcut.Arguments = "-ExecutionPolicy Bypass -NoExit -File `"" + $ROS_START + "`""
$Shortcut.Save()

# Optional add to powershell startup
$Documents = ([Environment]::GetFolderPath("MyDocuments") + "\WindowsPowerShell")
$title    = 'Add ROS2 to your powershell startup so you can call ROS2 at anytime without loading the script or launching the shortcut.'
$question = 'Are you sure you want to proceed?'
$choices  = '&Yes', '&No'

$decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
if ($decision -eq 0) {
    Write-Host 'Adding to Powershell'

    if (-not(Test-Path -Path $Documents)) {
        New-Item -ItemType Directory -Path $Documents
    }

    $ProfileFile = ($Documents + "\Microsoft.PowerShell_profile.ps1")
    if (Test-Path -Path $ProfileFile -PathType Leaf) {
        $SEL = Select-String -Path $ProfileFile -Pattern $ROS_START -SimpleMatch

        if ($SEL -eq $null)
        {
            Add-Content -Path $ProfileFile -Value $ROS_START
        }
    } else {
        Set-Content -Path $ProfileFile -Value $ROS_START
    }
}