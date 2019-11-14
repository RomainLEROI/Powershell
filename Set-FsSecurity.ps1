
Param ( 

    [Parameter(Mandatory = $true)]
    [String] $Path,

    [Parameter(Mandatory = $true)]
    # BUILTIN\Administrateurs, AUTORITE NT\Système, BUILTIN\Utilisateurs, <Domain>\<Group>, <Domain>\<User>, <Computer>\<User>...
    [ValidatePattern("[a-zA-Z]\\[a-zA-Z0-9]")]
    [String] $Identity,

    [Parameter(Mandatory = $true)]
    [ValidateSet('FullControl', 'Modify', 'ReadAndExecute', 'Read', 'Write')]
    [String[]] $Permissions,

    [Parameter(Mandatory = $false)]
    [String] $ComputerName = $env:COMPUTERNAME
  
)



Function Is-Online {

    Param (

        [Parameter(Mandatory = $true)]
        [String] $ComputerName

    )

    Try {


        [Bool] $Result = Test-Connection -ComputerName $Computername -Count 1 -Quiet -ErrorAction SilentlyContinue

        Return $Result


    } Catch {


        Return $false


    }


}


Function Is-LocalHost {

    Param (

        [Parameter(Mandatory = $true)]
        [String] $ComputerName

    
    )

    switch ($true) {

        ($ComputerName -eq $env:COMPUTERNAME) {

            Return $true

        } ($ComputerName -eq 'localhost') {

            Return $true

        } ($ComputerName -eq '.') {

            Return $true

        } Default {

            Return $false

        }

    }

}


if (([Security.Principal.WindowsPrincipal]::New([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {


    if ((Is-LocalHost -ComputerName $ComputerName) -or (Is-Online -ComputerName $ComputerName)) {


        [Hashtable] $PermissionTable = @{
                 
            FullControl = [Security.AccessControl.FileSystemRights]::FullControl
            Modify = [Security.AccessControl.FileSystemRights]::Modify
            ReadAndExecute = [Security.AccessControl.FileSystemRights]::ReadAndExecute
            Read = [Security.AccessControl.FileSystemRights]::Read
            Write = [Security.AccessControl.FileSystemRights]::Write
        
        }

     
        [Int] $AccessMask = 0

        foreach ($Permission in $Permissions) {

            $AccessMask += $PermissionTable[$Permission]

        }

        if (!(Is-LocalHost -ComputerName $ComputerName) -and ($Path -match "^[a-zA-Z]:\\")) {

            $Path = "\\$ComputerName\$($Path.Replace(":", "$"))"

        }


        if (Test-Path -Path $Path) {

            

            [Int] $PropagationFlag = [Security.AccessControl.PropagationFlags]::None 

            [Int] $AccessControlType = [Security.AccessControl.AccessControlType]::Allow 


            if ((Get-Item -Path $Path).PSIsContainer) {

                [Int] $InheritanceFlag = [Security.AccessControl.InheritanceFlags]::ContainerInherit + [Security.AccessControl.InheritanceFlags]::ObjectInherit
         
                [Security.AccessControl.FileSystemAccessRule] $Ace = [Security.AccessControl.FileSystemAccessRule]::new($Identity, $AccessMask, $InheritanceFlag, $PropagationFlag, $AccessControlType)

                [Security.AccessControl.DirectorySecurity] $Acl = [IO.Directory]::GetAccessControl($path)

                $Acl.AddAccessRule($Ace)

                [IO.Directory]::SetAccessControl($Path, $Acl)


            } else {

                [Int] $InheritanceFlag = [Security.AccessControl.InheritanceFlags]::None
         
                [Security.AccessControl.FileSystemAccessRule] $Ace = [Security.AccessControl.FileSystemAccessRule]::new($Identity, $AccessMask, $InheritanceFlag, $PropagationFlag, $AccessControlType)

                [Security.AccessControl.FileSecurity] $Acl = [IO.File]::GetAccessControl($path)

                $Acl.AddAccessRule($Ace)

                [IO.File]::SetAccessControl($Path, $Acl)

            }

        } else {

            Write-Output -InputObject "Path not found not found"

        }

    }  else {

        Write-Output -InputObject "$ComputerName is not online"

    }
   
} else {

    Write-Output -InputObject "The requested operation requires elevation"

}
