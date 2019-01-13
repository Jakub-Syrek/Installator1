class Downloader
{


[string]$ip  ;
[string]$folder  ;
[string]$scriptFolder ;
[string]$remoteHost ;

[string]GetDesktopPath()
   { 
    [string]$path = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
     return $path ;
   }
[bool]CheckConnectionToDriverServer([string]$_)
   {
      [bool]$con = $false ;
      if (Test-Connection -ComputerName $_ -Quiet)  
        {
        $con = $true ;
        }
      return $con ;
    }
[bool]CheckIfPathExists([string]$_)
     {
       [bool]$pat = $false ;
       if(Test-Path -Path $_ )
         {
          $pat = $true ;
         }
       return $pat ;
     }
CreateFolder ([string]$_folderName,[string]$_scriptPath)
     {
      New-Item -Path $_scriptPath -Name $_folderName -ItemType "directory" -Force
     }
CopyFiles([string]$source , [string]$destin)
     {
         try 
          {
           Copy-Item $source -destination $destin -Force        
           Write-Host "Files copied succesfully"
          }
         catch
          {
           Write-Host $_.Exception.Message`n    
          }
     }
    
DecompressArchive([string]$arch , [string]$destin)
     {
        try 
         {
          Expand-Archive -Path $arch -DestinationPath $destin -Force ;
          Write-Host "Decompressed succesfully"
         }
        catch
         {
          Write-Host $_.Exception.Message`n
         }
      }
CompressArchive([string]$arch , [string]$destin)
     {
        try 
         {
          Compress-Archive -Path $arch -DestinationPath $destin -Force
          Write-Host "Compressed succesfully"
         }
        catch
         {
          Write-Host $_.Exception.Message`n
         }
      }
 }

 class Installator
{


[string]$program  ;
[string]$args ;

Install($program , [string]$args)
   {
    Write-Host $this.program
    Write-Host $this.args
     Invoke-Command  -ScriptBlock {
                                       Start-Process $this.program  -ArgumentList $this.args -Wait 
                                   }  
   }
Uninstall($program)
   {
     Invoke-Command -ScriptBlock {
                                  Install-Module ProgramManagement -Force
                                  Import-Module ProgramManagement -Force                             
                                  Write-Host "Uninstalling $program"
                                                                 
                                  }
    }    
[bool]CheckIfInstalled([string]$program)
   {
    $this.program ;
    $x86 = ((Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall") |
        Where-Object { $_.GetValue( "DisplayName" ) -like "*$program*" } ).Length -gt 0;

    $x64 = ((Get-ChildItem "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall") |
        Where-Object { $_.GetValue( "DisplayName" ) -like "*$program*" } ).Length -gt 0;

    return $x86 -or $x64; 
    }
}

if ($MyInvocation.MyCommand.CommandType -eq "ExternalScript")
{ $ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition }
else
{ $ScriptPath = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0]) 
    if (!$ScriptPath){ $ScriptPath = "." } }

function Restart-PowerShell-Elevated
{
$Script = $ScriptFol + "\InstallatorHCL.ps1"
$ConfirmPreference = “None”
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{   
$arguments = " -ExecutionPolicy UnRestricted  & '" + $Script + "'" 
Start-Process "$psHome\powershell.exe" -Verb "runAs" -ArgumentList $arguments
Break
}

}
Set-Alias -Name rpe -Value Restart-PowerShell-Elevated

rpe

#$ScriptFolder = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ScriptFolder = $ScriptPath + "\Data\"
$ScriptFolder

Function  UnblockComponents 
        {
         Get-ChildItem $ScriptFolder | Unblock-File 
        }



Function InstallDellModules 

        {

         if (Get-Module -ListAvailable -Name DellBIOSProvider) 

         {

           Write-Host "Module DellBIOSProvider exists"

           Write-Host "Skipping modules installation."

         } 

         else 

         {

          Write-Host "Module does not exist"

          Write-Host "Installing modules."

          Install-Module -Name DellBIOSProvider -RequiredVersion 2.0.0 ;

          $FileName = $ScriptFolder + "\" + "Systems-Management_Application_G25RF_WN_8.2.0_A00" ;

          Invoke-Command  -ScriptBlock {

                                       Start-Process $FileName  -ArgumentList '/s' -Wait 

                                      }

          Write-Host "OMCI Modules installed" ;

         }

         

         Import-Module DellBIOSProvider | Out-Null ;  

              

        }

Function ModifyBIOSvalues 
        {
         cd DellSmbios:\PowerManagement
         $dir = dir
         foreach ($a in $dir)
                {
                 if ($a.Attribute -eq 'BlockSleep' -and $a.CurrentValue -ne "Enabled" )
                   {
                    $listBox1.Items.Add($a.Attribute + " is " + $a.CurrentValue + ".Modifying to enabled...");
                    Write-Host $a.Attribute " is " $a.CurrentValue ".Modifying to enabled...";
                    Set-Item -Path DellSmbios:\PowerManagement\BlockSleep "Enabled";
                   } 
                 if ($a.Attribute -eq 'DeepSleepCtrl' -and $a.CurrentValue -ne "Disabled" )
                   {
                    $listBox1.Items.Add($a.Attribute + " is " + $a.CurrentValue + ".Modifying to disabled...");
                    Write-Host $a.Attribute " is " $a.CurrentValue ".Modifying to disabled...";
                    Set-Item -Path DellSmbios:\PowerManagement\DeepSleepCtrl "Disabled" ;
                   }
                 if ($a.Attribute -eq 'BlockSleep' -and $a.CurrentValue -eq "Enabled" )
                   {
                    $listBox1.Items.Add($a.Attribute + " is " + $a.CurrentValue);
                    Write-Host $a.Attribute " is " $a.CurrentValue "."    ;                
                   } 
                 if ($a.Attribute -eq 'DeepSleepCtrl' -and $a.CurrentValue -eq "Disabled" )
                   {
                    $listBox1.Items.Add($a.Attribute + " is " + $a.CurrentValue);
                    Write-Host $a.Attribute " is " $a.CurrentValue "."
                   }
                }
        }
     
          
      
Function SetTimeZone 
        {          
         $Global:TimeZone = (Get-TimeZone).Id
         if ($TimeZone -ne "Central European Standard Time" )
           {
            Set-TimeZone -Name "Central European Standard Time" -Verbose
            $TimeZone = (Get-TimeZone).Id
            Write-Output "Current Timezone is: $TimeZone";
            $listBox1.Items.Add("Current Timezone is:" + $TimeZone);
           }
         else
         {
          Write-Output "Current Timezone is: $TimeZone";
          $listBox1.Items.Add("Current Timezone is:" + $TimeZone);
         }
        }
Function UpdateBios 
        {
         $Model = $((Get-WmiObject -Class Win32_ComputerSystem).Model).Trim()     
         $BIOSVersion = (Get-WmiObject -Namespace root\DCIM\SYSMAN -Class DCIM_BIOSElement).Version


         if ($Model -eq "OptiPlex 7050")
         {          
          if ($BIOSVersion -ne '1.11.0' )
           {
             $FileName = $ScriptFolder + "\" + "OptiPlex_7050_1.11.0.exe"
             Invoke-Command  -ScriptBlock {
                                          Start-Process $FileName  -ArgumentList '/s /r' -Wait 
                                         }
            $BIOSVersion = (Get-WmiObject -Namespace root\DCIM\SYSMAN -Class DCIM_BIOSElement).Version
            Write-Output "Current BIOS version: $BIOSVersion "
            $listBox1.Items.Add("Current BIOS version:" + $BIOSVersion );
           }
           else
           {
            Write-Output "Current BIOS version: $BIOSVersion.No need to update "
            $listBox1.Items.Add("Current BIOS version:" + $BIOSVersion + ".No need to update ");
           }
         }
         if ($Model -eq "OptiPlex 3060")
         {          
          if ($BIOSVersion -ne '1.2.22' )
           {
            $FileName = $ScriptFolder + "\" + "OptiPlex_3060_1.2.22.exe"
            Invoke-Command  -ScriptBlock {
                                          Start-Process $FileName  -ArgumentList '/s /r' -Wait 
                                         }
            $BIOSVersion = (Get-WmiObject -Namespace root\DCIM\SYSMAN -Class DCIM_BIOSElement).Version
            Write-Output "Current BIOS version: $BIOSVersion "
            $listBox1.Items.Add("Current BIOS version:" + $BIOSVersion );
           }
           else
           {
            Write-Output "Current BIOS version: $BIOSVersion.No need to update "
            $listBox1.Items.Add("Current BIOS version:" + $BIOSVersion + ".No need to update ");
           }
         }
       }
Function InstallCitrix 
        {
         $FileName = $ScriptFolder + "\" + "CitrixReceiver.exe"
         Invoke-Command  -ScriptBlock {
                                       Start-Process $FileName  -ArgumentList '/silent' -Wait 
                                      }
         if ((Is-Installed("Citrix")) -eq $true )
            {
              Write-Output "Citrix is installed"
              $listBox1.Items.Add("Citrix is installed");
            }
        }
Function Install-SSL-Vpn 
        {
         $FileName = $ScriptFolder + "\" + "SslvpnClient.exe"
         Invoke-Command  -ScriptBlock {
                                       Start-Process $FileName  -ArgumentList '/silent /verysilent' -Wait 
                                      }
         if ((Is-Installed("FortiClient")) -eq $true )
            {
              Write-Output "FortiClient is installed"
              $listBox1.Items.Add("FortiClient is installed");
            }
        }
Function InstallAmazon 
        {
        
         $FileName = $ScriptFolder + "\" + "Amazon+WorkSpaces.msi"
         $FileName
         Invoke-Command  -ScriptBlock {
                                       Start-Process -FilePath msiexec -verb runas -ArgumentList /i, $FileName, /qn -Wait
                                      }
         if ((Is-Installed("Amazon")) -eq $true )
            {
              Write-Output "Amazon is installed"
              $listBox1.Items.Add("Amazon is installed");
            }

        }
        
Function InstallVMware
        {
         $FileName = $ScriptFolder + "\" + "VMware-Horizon-Client-4.7.0-7395453.exe"
         Invoke-Command  -ScriptBlock {
                                       Start-Process $FileName  -ArgumentList '/s /norestart' -Wait 
                                      }
        if (Is-Installed("VMware") -eq $true )
            {
              Write-Output "VMware is installed"
              $listBox1.Items.Add("VMware is installed");
            }
        }
Function InstallFirefox
        {
         if ((Is-Installed("Firefox")) -eq $false )
            {
             $FileName = $ScriptFolder + "\" + "Firefox Setup 64.0.2.exe"
             Invoke-Command  -ScriptBlock {
                                          $args = " -ms /install"
                                          Start-Process $FileName  -ArgumentList $args -Wait 
                                         }
            }

            if (Is-Installed("Firefox") -eq $true )
            {
              Write-Output "Firefox is installed"
              $listBox1.Items.Add("Firefox is installed");
            }
        }
Function InstallBoomgar
        {
         if ((Is-Installed("Bomgar")) -eq $false )
            {
             $FileName = $ScriptFolder + "\" + "bomgar-rep-installer.exe"
             Invoke-Command  -ScriptBlock {
                                          $args = " /S"
                                          Start-Process $FileName  -ArgumentList $args -Wait 
                                         }
            }

            if (Is-Installed("Bomgar") -eq $true )
            {
              Write-Output "Bomgar is installed"
              $listBox1.Items.Add("Bomgar is installed");
            }
        }
Function InstallBigIP
        {
         if ((Is-Installed("Big-IP")) -eq $false )
            {
             $FileName = $ScriptFolder + "\BIGIPEdgeClient-All.exe"
             Invoke-Command  -ScriptBlock {
                                          Start-Process $FileName -Wait -PassThru
                                         }
            }

            if (Is-Installed("Big-IP") -eq $true )
            {
              Write-Output "Big-IP is installed"
              $listBox1.Items.Add("Big-IP is installed");
            }
        }
Function InstallChrome 
        {
         if ((Is-Installed("Chrome")) -eq $false )
            {
             $FileName = $ScriptFolder + "\" + "ChromeSetup.exe"
             Invoke-Command  -ScriptBlock {
                                          Start-Process $FileName  -ArgumentList '/silent /install' -Wait 
                                         }
            }

            if (Is-Installed("Chrome") -eq $true )
            {
              Write-Output "Chrome is installed"
              $listBox1.Items.Add("Chrome is installed");
            }
        }
Function Install-QP 
        {
         if ((Is-Installed("QuikPop+")) -eq $false )
            {
             $FileName = $ScriptFolder + "\" + "InstallAGC_conditional.ps1" ;              
             $arguments1 = " -ExecutionPolicy UnRestricted & '" + $FileName + "'" 
             Start-Process "$psHome\powershell.exe" -Verb "runAs" -ArgumentList $arguments1 -Wait
             }
         
          if (Is-Installed("QuikPop+") -eq $true )
            {
             Write-Output "Quickpop is installed"
             $listBox1.Items.Add("Quickpop is installed");
            }
        
        }
Set-Alias -Name iq -Value Install-QP ;

Function Install-Verint 
        {
         if ((Is-Installed("Impact 360 Desktop Applications")) -eq $false )
            {
             $FileName = $ScriptFolder + "\" + "InstallVerint_conditional.ps1" ;              
             $arguments1 = " -ExecutionPolicy UnRestricted & '" + $FileName + "'" 
             Start-Process "$psHome\powershell.exe" -Verb "runAs" -ArgumentList $arguments1 -Wait
             }
         
          if (Is-Installed("Impact 360 Desktop Applications") -eq $true )
            {
             Write-Output "Impact 360 Desktop Applications is installed"
             $listBox1.Items.Add("Impact 360 Desktop Applications is installed");
            }
        
        }
Set-Alias -Name iv -Value Install-Verint ;
             
function Check-if-local-data-is-available
        {
           $d  = New-Object Downloader 
           $d.folder = $ScriptFolder + "\data"
           if ($d.CheckIfPathExists($d.folder) -ne $true)
              { 
               return $false
              }else{
              return $true
              }
        }
Set-Alias -Name cildia -Value Check-if-local-data-is-available ;




 function Is-Installed( $program ) {
    
    $x86 = ((Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall") |
        Where-Object { $_.GetValue( "DisplayName" ) -like "*$program*" } ).Length -gt 0;

    $x64 = ((Get-ChildItem "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall") |
        Where-Object { $_.GetValue( "DisplayName" ) -like "*$program*" } ).Length -gt 0;

    return $x86 -or $x64;
}       

function Get-Current-Status

{
 $listBox1.Items.Clear();
 [array]$status = @("Chrome","Citrix","VMware","Amazon","QuikPop+","Impact 360 Desktop Applications","FortiClient" , "Firefox") ;
 [array]$checboxes = @($checkBox1 , $checkBox2 , $checkBox3 , $checkBox6 , $checkBox7 , $checkBox8 , $checkBox9 , $checkBox10  ) ;

  for ($i = 0 ; $i -le $status.Count -1 ; $i++ )
  {
   if (Is-Installed $status[$i] )
    {
     $b = $($status[$i]) + " is already installed"
     $listBox1.Items.Add("$($b)");
     $a = $($checboxes[$i]) ;
     $($a).Checked = $true ;
    }
    else
    {
     $b = "$($status[$i]) is not installed"
     $listBox1.Items.Add($b);
    }
  }
}

function ProvideDataForScript
    {
      [bool]$dt = cildia
       if ( $dt -eq $false)
       {
        $d = New-Object Downloader ;
        $d.folder = "data" ;
        #$d.remoteHost = $remoteIP ;
        $d.scriptFolder = $ScriptFolder 
        $d.CreateFolder($d.folder,$d.scriptFolder)    
        #$d.CopyFiles($d.remoteHost,$d.folder)
        #$d.DecompressArchive($d.folder,$d.folder)
         if (cildia -eq $true)
          {
           Write-Host "Script data present locally"        
          }
       }
    }

ProvideDataForScript  
UnblockComponents
InstallDellModules

$Global:project = "" #InputProjectName


function GenerateForm {

[reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
[reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null

$form1 = New-Object System.Windows.Forms.Form 
$button1 = New-Object System.Windows.Forms.Button
$button2 = New-Object System.Windows.Forms.Button
$listBox1 = New-Object System.Windows.Forms.ListBox
$DropDownBox = New-Object System.Windows.Forms.ComboBox
$checkBox15 = New-Object System.Windows.Forms.CheckBox
$checkBox14 = New-Object System.Windows.Forms.CheckBox
$checkBox13 = New-Object System.Windows.Forms.CheckBox
$checkBox12 = New-Object System.Windows.Forms.CheckBox
$checkBox11 = New-Object System.Windows.Forms.CheckBox
$checkBox10 = New-Object System.Windows.Forms.CheckBox
$checkBox9 = New-Object System.Windows.Forms.CheckBox
$checkBox8 = New-Object System.Windows.Forms.CheckBox
$checkBox7 = New-Object System.Windows.Forms.CheckBox
$checkBox6 = New-Object System.Windows.Forms.CheckBox
$checkBox5 = New-Object System.Windows.Forms.CheckBox
$checkBox4 = New-Object System.Windows.Forms.CheckBox
$checkBox3 = New-Object System.Windows.Forms.CheckBox
$checkBox2 = New-Object System.Windows.Forms.CheckBox
$checkBox1 = New-Object System.Windows.Forms.CheckBox
$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState


#----------------------------------------------
#Generated Event Script Blocks
#----------------------------------------------

$handler_button1_Click= 
{
    #$listBox1.Items.Clear();    

    if ($checkBox1.Checked)
      {
          $listBox1.Items.Add( "Checkbox 1 is checked"  ) ;
          InstallChrome    ;  
      }

    if ($checkBox2.Checked)
      {
          $listBox1.Items.Add( "Checkbox 2 is checked"  ) ;
          InstallCitrix ;
      }

    if ($checkBox3.Checked)    
      {  
          $listBox1.Items.Add( "Checkbox 3 is checked"  ) ;
          InstallVMware ;
                
      }

    if ($checkBox4.Checked)
     {
          $listBox1.Items.Add( "Checkbox 4 is checked"  ) ;
          SetTimeZone ;
      }

    if ($checkBox5.Checked)
     {
          $listBox1.Items.Add( "Checkbox 5 is checked"  ) ;
          ModifyBIOSvalues ;

     }

    if ($checkBox6.Checked)
    {
         $listBox1.Items.Add( "Checkbox 6 is checked"  );
         InstallAmazon ;
    }
    if ($checkBox7.Checked)
    {
         $listBox1.Items.Add( "Checkbox 7 is checked"  );
         iq ;
    }
    if ($checkBox8.Checked)
    {
         $listBox1.Items.Add( "Checkbox 8 is checked"  );
         iv ;
    }
    if ($checkBox9.Checked)
    {
         $listBox1.Items.Add( "Checkbox 9 is checked"  );
         Install-SSL-Vpn ;
    }
    if ($checkBox10.Checked)
    {
         $listBox1.Items.Add( "Checkbox 10 is checked"  );
         InstallFirefox ;
    }
    if ($checkBox11.Checked)
    {
         $listBox1.Items.Add( "Checkbox 11 is checked"  );
         InstallBoomgar ;
    }
     if ($checkBox12.Checked)
    {
         $listBox1.Items.Add( "Checkbox 12 is checked"  );
         InstallBigIP ;
    }
     if ($checkBox13.Checked)
    {
         $listBox1.Items.Add( "Checkbox 13 is checked"  );
         
    }
     if ($checkBox14.Checked)
    {
         $listBox1.Items.Add( "Checkbox 14 is checked"  );         
    }


    if ($checkBox15.Checked)
    {
         $listBox1.Items.Add( "Checkbox 15 is checked"  );
         UpdateBios ;
    }

    if ( !$checkBox1.Checked -and !$checkBox2.Checked -and !$checkBox3.Checked -and !$checkBox4.Checked -and !$checkBox5.Checked -and !$checkBox6.Checked -and !$checkBox7.Checked -and !$checkBox8.Checked -and !$checkBox9.Checked -and !$checkBox10.Checked -and !$checkBox11.Checked -and !$checkBox12.Checked -and !$checkBox13.Checked -and !$checkBox14.Checked -and !$checkBox15.Checked )
     {   $listBox1.Items.Add("No CheckBox selected....")} 
}
$handler_button2_Click= 

{

 Get-Current-Status ;

}
$handler_DropDownBox_SelectedIndexChanged=
{

       if ($DropDownBox.Text.Length -gt 0)
    {
        $listBox1.Items.Add($DropDownBox.Text + " was selected");
        $Global:project = $DropDownBox.Text ;
        

        if ($Global:project -eq "Alstom")
  {
   $checkBox1.Checked = $true ;
   $checkBox2.Checked = $true ;
   $checkBox3.Checked = $false ;
   $checkBox4.Checked = $true ;
   $checkBox5.Checked = $true ;
   $checkBox6.Checked = $false ;
   $checkBox7.Checked = $false ;
   $checkBox8.Checked = $false ;
   $checkBox9.Checked = $false ;
   $checkBox10.Checked = $false ;
   $checkBox11.Checked = $false ;
   $checkBox12.Checked = $false ;
   $checkBox13.Checked = $false ;
   $checkBox14.Checked = $false ;
   $checkBox15.Checked = $true ;
   
   }

        if ($Global:project -eq "BD")
  {
   $checkBox1.Checked = $true ;
   $checkBox2.Checked = $true ;
   $checkBox3.Checked = $true ;
   $checkBox4.Checked = $true ;
   $checkBox5.Checked = $true ;
   $checkBox6.Checked = $false ;
   $checkBox7.Checked = $false ;
   $checkBox8.Checked = $false ;
   $checkBox9.Checked = $false ;
   $checkBox10.Checked = $false ;
   $checkBox11.Checked = $false ;
   $checkBox12.Checked = $false ;
   $checkBox13.Checked = $false ;
   $checkBox14.Checked = $false ;
   $checkBox15.Checked = $true ;
   }
 
   if ($Global:project -eq "DB")
  {
   $checkBox1.Checked = $true ;
   $checkBox2.Checked = $true ;
   $checkBox3.Checked = $false ;
   $checkBox4.Checked = $true ;
   $checkBox5.Checked = $true ;
   $checkBox6.Checked = $false ;
   $checkBox7.Checked = $true ;
   $checkBox8.Checked = $false ;
   $checkBox9.Checked = $false ;
   $checkBox10.Checked = $false ;
   $checkBox11.Checked = $false ;
   $checkBox12.Checked = $false ;
   $checkBox13.Checked = $false ;
   $checkBox14.Checked = $false ;
   $checkBox15.Checked = $true ;
   }
   if ($Global:project -eq "Havi")
  {
   $checkBox1.Checked = $true ;
   $checkBox2.Checked = $true ;
   $checkBox3.Checked = $false ;
   $checkBox4.Checked = $true ;
   $checkBox5.Checked = $true ;
   $checkBox6.Checked = $false ;
   $checkBox7.Checked = $false ;
   $checkBox8.Checked = $false ;
   $checkBox9.Checked = $false ;
   $checkBox10.Checked = $false ;
   $checkBox11.Checked = $false ;
   $checkBox12.Checked = $false ;
   $checkBox13.Checked = $false ;
   $checkBox14.Checked = $false ;
   $checkBox15.Checked = $true ;
   }
     if ($Global:project -eq "Sasol")
  {
   $checkBox1.Checked = $true ;
   $checkBox2.Checked = $true ;
   $checkBox3.Checked = $false ;
   $checkBox4.Checked = $true ;
   $checkBox5.Checked = $true ;
   $checkBox6.Checked = $false ;
   $checkBox7.Checked = $false ;
   $checkBox8.Checked = $false ;
   $checkBox9.Checked = $true ;
   $checkBox10.Checked = $false ;
   $checkBox11.Checked = $false ;
   $checkBox12.Checked = $false ;
   $checkBox13.Checked = $false ;
   $checkBox14.Checked = $false ;
   $checkBox15.Checked = $true ;
   }
  }  
 }


$OnLoadForm_StateCorrection=
{#Correct the initial state of the form to prevent the .Net maximized form issue
    $form1.WindowState = $InitialFormWindowState
}

#----------------------------------------------
#region Generated Form Code
$form1.Text = "Installator"
$form1.Name = "Installator"
$form1.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 550
$System_Drawing_Size.Height = 550
$form1.ClientSize = $System_Drawing_Size

$button1.TabIndex = 4
$button1.Name = "button1"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 100
$System_Drawing_Size.Height = 23
$button1.Size = $System_Drawing_Size
$button1.UseVisualStyleBackColor = $True
$button1.Text = "Run Script"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 27
$System_Drawing_Point.Y = 515
$button1.Location = $System_Drawing_Point
$button1.DataBindings.DefaultDataSourceUpdateMode = 0
$button1.add_Click($handler_button1_Click)
$form1.Controls.Add($button1)

$button2.TabIndex = 17
$button2.Name = "button2"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 120
$System_Drawing_Size.Height = 23
$button2.Size = $System_Drawing_Size
$button2.UseVisualStyleBackColor = $True
$button2.Text = "Check install status"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 128
$System_Drawing_Point.Y = 515
$button2.Location = $System_Drawing_Point
$button2.DataBindings.DefaultDataSourceUpdateMode = 0
$button2.add_Click($handler_button2_Click)
$form1.Controls.Add($button2)





$listBox1.FormattingEnabled = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 350
$System_Drawing_Size.Height = 400
$listBox1.Size = $System_Drawing_Size
$listBox1.DataBindings.DefaultDataSourceUpdateMode = 0
$listBox1.Name = "listBox1"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 147
$System_Drawing_Point.Y = 13
$listBox1.Location = $System_Drawing_Point
$listBox1.TabIndex = 3

$form1.Controls.Add($listBox1)

$DropDownBox.Location = New-Object System.Drawing.Size(24,484) 
$DropDownBox.Size = New-Object System.Drawing.Size(180,20) 
$DropDownBox.DropDownHeight = 200 


$Projects=@("Alstom","BD","DB" ,"Havi","Sasol")

foreach ($Project in $Projects) {
                      $DropDownBox.Items.Add($Project)
                              }     

$DropDownBox.add_SelectedIndexChanged($handler_DropDownBox_SelectedIndexChanged)
$form1.Controls.Add($DropDownBox)



$checkBox15.UseVisualStyleBackColor = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 104
$System_Drawing_Size.Height = 24
$checkBox15.Size = $System_Drawing_Size
$checkBox15.TabIndex = 16
$checkBox15.Text = "Update BIOS"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 27
$System_Drawing_Point.Y = 453
$checkBox15.Location = $System_Drawing_Point
$checkBox15.DataBindings.DefaultDataSourceUpdateMode = 0
$checkBox15.Name = "checkBox15"
$form1.Controls.Add($checkBox15)


$checkBox14.UseVisualStyleBackColor = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 104
$System_Drawing_Size.Height = 24
$checkBox14.Size = $System_Drawing_Size
$checkBox14.TabIndex = 15
$checkBox14.Text = "xxx"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 27
$System_Drawing_Point.Y = 422
$checkBox14.Location = $System_Drawing_Point
$checkBox14.DataBindings.DefaultDataSourceUpdateMode = 0
$checkBox14.Name = "checkBox14"
$form1.Controls.Add($checkBox14)


$checkBox13.UseVisualStyleBackColor = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 104
$System_Drawing_Size.Height = 24
$checkBox13.Size = $System_Drawing_Size
$checkBox13.TabIndex = 14
$checkBox13.Text = "xxx"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 27
$System_Drawing_Point.Y = 391
$checkBox13.Location = $System_Drawing_Point
$checkBox13.DataBindings.DefaultDataSourceUpdateMode = 0
$checkBox13.Name = "checkBox13"
$form1.Controls.Add($checkBox13)


$checkBox12.UseVisualStyleBackColor = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 104
$System_Drawing_Size.Height = 24
$checkBox12.Size = $System_Drawing_Size
$checkBox12.TabIndex = 13
$checkBox12.Text = "Install BigIP"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 27
$System_Drawing_Point.Y = 360
$checkBox12.Location = $System_Drawing_Point
$checkBox12.DataBindings.DefaultDataSourceUpdateMode = 0
$checkBox12.Name = "checkBox12"
$form1.Controls.Add($checkBox12)

$checkBox11.UseVisualStyleBackColor = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 104
$System_Drawing_Size.Height = 24
$checkBox11.Size = $System_Drawing_Size
$checkBox11.TabIndex = 12
$checkBox11.Text = "Install Bomgar"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 27
$System_Drawing_Point.Y = 329
$checkBox11.Location = $System_Drawing_Point
$checkBox11.DataBindings.DefaultDataSourceUpdateMode = 0
$checkBox11.Name = "checkBox11"
$form1.Controls.Add($checkBox11)

$checkBox10.UseVisualStyleBackColor = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 104
$System_Drawing_Size.Height = 24
$checkBox10.Size = $System_Drawing_Size
$checkBox10.TabIndex = 11
$checkBox10.Text = "Install Firefox"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 27
$System_Drawing_Point.Y = 298
$checkBox10.Location = $System_Drawing_Point
$checkBox10.DataBindings.DefaultDataSourceUpdateMode = 0
$checkBox10.Name = "checkBox10"
$form1.Controls.Add($checkBox10)

$checkBox9.UseVisualStyleBackColor = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 104
$System_Drawing_Size.Height = 24
$checkBox9.Size = $System_Drawing_Size
$checkBox9.TabIndex = 10
$checkBox9.Text = "Install SsLVpn"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 27
$System_Drawing_Point.Y = 267
$checkBox9.Location = $System_Drawing_Point
$checkBox9.DataBindings.DefaultDataSourceUpdateMode = 0
$checkBox9.Name = "checkBox9"
$form1.Controls.Add($checkBox9)

$checkBox8.UseVisualStyleBackColor = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 104
$System_Drawing_Size.Height = 24
$checkBox8.Size = $System_Drawing_Size
$checkBox8.TabIndex = 9
$checkBox8.Text = "Instal Verint"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 27
$System_Drawing_Point.Y = 235
$checkBox8.Location = $System_Drawing_Point
$checkBox8.DataBindings.DefaultDataSourceUpdateMode = 0
$checkBox8.Name = "checkBox8"

$form1.Controls.Add($checkBox8)




$checkBox7.UseVisualStyleBackColor = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 104
$System_Drawing_Size.Height = 24
$checkBox7.Size = $System_Drawing_Size
$checkBox7.TabIndex = 8
$checkBox7.Text = "Install QP"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 27
$System_Drawing_Point.Y = 204
$checkBox7.Location = $System_Drawing_Point
$checkBox7.DataBindings.DefaultDataSourceUpdateMode = 0
$checkBox7.Name = "checkBox7"

$form1.Controls.Add($checkBox7)


$checkBox6.UseVisualStyleBackColor = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 104
$System_Drawing_Size.Height = 24
$checkBox6.Size = $System_Drawing_Size
$checkBox6.TabIndex = 7
$checkBox6.Text = "InstallAmazon"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 27
$System_Drawing_Point.Y = 173
$checkBox6.Location = $System_Drawing_Point
$checkBox6.DataBindings.DefaultDataSourceUpdateMode = 0
$checkBox6.Name = "checkBox6"

$form1.Controls.Add($checkBox6)

$checkBox5.UseVisualStyleBackColor = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 104
$System_Drawing_Size.Height = 24
$checkBox5.Size = $System_Drawing_Size
$checkBox5.TabIndex = 6
$checkBox5.Text = "Modify BIOS"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 27
$System_Drawing_Point.Y = 137
$checkBox5.Location = $System_Drawing_Point
$checkBox5.DataBindings.DefaultDataSourceUpdateMode = 0
$checkBox5.Name = "checkBox5"

$form1.Controls.Add($checkBox5)

$checkBox4.UseVisualStyleBackColor = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 104
$System_Drawing_Size.Height = 24
$checkBox4.Size = $System_Drawing_Size
$checkBox4.TabIndex = 5
$checkBox4.Text = "Set timezone"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 27
$System_Drawing_Point.Y = 106
$checkBox4.Location = $System_Drawing_Point
$checkBox4.DataBindings.DefaultDataSourceUpdateMode = 0
$checkBox4.Name = "checkBox4"

$form1.Controls.Add($checkBox4)

$checkBox3.UseVisualStyleBackColor = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 104
$System_Drawing_Size.Height = 24
$checkBox3.Size = $System_Drawing_Size
$checkBox3.TabIndex = 2
$checkBox3.Text = "InstallVM"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 27
$System_Drawing_Point.Y = 75
$checkBox3.Location = $System_Drawing_Point
$checkBox3.DataBindings.DefaultDataSourceUpdateMode = 0
$checkBox3.Name = "checkBox3"

$form1.Controls.Add($checkBox3)


$checkBox2.UseVisualStyleBackColor = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 104
$System_Drawing_Size.Height = 24
$checkBox2.Size = $System_Drawing_Size
$checkBox2.TabIndex = 1
$checkBox2.Text = "Install Citrix"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 27
$System_Drawing_Point.Y = 44
$checkBox2.Location = $System_Drawing_Point
$checkBox2.DataBindings.DefaultDataSourceUpdateMode = 0
$checkBox2.Name = "checkBox2"

$form1.Controls.Add($checkBox2)


$checkBox1.UseVisualStyleBackColor = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 104
$System_Drawing_Size.Height = 24
$checkBox1.Size = $System_Drawing_Size
$checkBox1.TabIndex = 0
$checkBox1.Text = "Install Chrome"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 27
$System_Drawing_Point.Y = 13
$checkBox1.Location = $System_Drawing_Point
$checkBox1.DataBindings.DefaultDataSourceUpdateMode = 0
$checkBox1.Name = "checkBox1"

$form1.Controls.Add($checkBox1)


#Save the initial state of the form
$InitialFormWindowState = $form1.WindowState
#Init the OnLoad event to correct the initial state of the form
$form1.add_Load($OnLoadForm_StateCorrection)
#Show the Form
$form1.ShowDialog()| Out-Null

} #End Function

#Call the Function
GenerateForm
