*ChiaMiniPlotter.ps1  by  JIRI HERNIK*

Need help setting up your own plotting machine?
    Contact me on on rammi.cz@gmail.com        

Powershell script to make chia plotting on Windows more enjoyable.

*Quick start guide:*

1. Make sure you have the powershell installed:
https://github.com/PowerShell/PowerShell/tags

2. Run powershell console as administrator and run the following command:
    Set-ExecutionPolicy RemoteSigned
    Select "yes to all" as answer.

3. Download the files ChiaMiniPlotter.ps1 and ChiaMiniPlotter.json to the same directory on your pc.
    Eg on your desktop

4. Edit the ChiaMiniPlotter.json file to suit your computer's drives. Do not forget to double check the path to your chia plotter

5. Right click on ChiaMiniPlotter.ps1 and select Run with powershell

6. Wait until all your drives are full of chia plots.


*Details on config file*
 - "ssd" : letter of the disk which will be used primarily for this plotter (UPPERCASE)
 - "ssd2" : optional field specifying the letter of the second temp location (UPPERCASE)

*More details of inner working*
 - Plotters are spinned up on each SSD with the minimal time difference of "spinupMinutes".
 - The settings in the .json file are reloaded periodically, so you don't need to restart the script for changing the settings.
 - After the space left on the target is less than 1TB, ploting will continue on the next available target from the config.
 - When there will be less than 1TB space left on each available target, plotting will end
 - You can use network path as a target (\\computer\share), but there will be no check for empty space, you need to watch it for yourself.
