# ROS2 Windows Installer

## Humble Hawksbill - [Release](https://github.com/ros2/ros2/releases?q=humble+hawksbill)
- Tested on windows 10 and 11
- Installer based off of their [documentation](https://docs.ros.org/en/humble/Installation/Windows-Install-Binary.html).
#### To use, run this command inside an administrative Powershell:
`iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/scottcandy34/ros2_windows_install/main/ros2_humble.ps1'))`


## Colcon Errors:
If you encounter this kind of result in Windows, it is a bug in the notification display, just see Success, you can ignore it
````
Finished <<< simple_230215 [3.75s]

Summary: 1 package finished [4.20s]
  1 package had stderr output: simple_230215
WNDPROC return value cannot be converted to LRESULT
```
