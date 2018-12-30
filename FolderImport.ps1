# FolderImport.ps1
#
# Script works best on a clean system
# script cannot handle already existing folders WITH subfolders
# So clean all folders except "Discovered virtual machine" folder
# or make sure existing folders do not need any subfolders!!!! 
#
# Note: script must be cleaned and still contains lot of Write-Host
#
# Usage: First create export, using script FolderExport, this will create file vmfolder.txt
# Then connect to desired vCenter Server (Connect-VIServer) and run the script.

# Create new Object to store folder structure
function New-Parent {
    New-Object PSObject -Property @{
        Level = ''
        Folder = ''
        Parent = ''
    }
}

# Parse data
$parents = @()
# First record for root folder vm
$parent = New-Parent
$parent.Level  = 0
$parent.Folder = "vm"
$parent.Parent = (Get-View -ViewType Folder | Where-Object { $_.childtype -like "VirtualMachine" -and $_.Name -eq "vm"}).MoRef
$parents += $parent

# Read input file and start loop
foreach($line in Get-Content vmfolder.txt) {
    Write-Host "### Working on line: " $line   
    
    # The first $myParentid is the MoRef of the root folder "vm" which is stored as parent
    $myparentid = ($parents | Where-Object {$_.Level -eq "0" -and $_.Folder -eq "vm"}).Parent
    $i = 0
    
    # Level 1 folder, we work from right to left. The last item is level 1
    $folder = $line.split("/")[$i-1]
    do {
        Write-Host "Working on folder: " $folder
        if (Get-View -ViewType Folder | Where-Object { $_.childtype -like "VirtualMachine" -and $_.Name -eq $folder -and $_.Parent -eq $myparentid}) {
            Write-Host $folder "folder already exist" }
        else {
            # Create new folder
            Write-Host "Create folder: " $folder
            New-Folder -Name $folder -Location(Get-Folder -Id $myparentid)
            # Create new object
            Write-Host "Create a new object for: " $folder
            $parent = New-Parent
            $parent.Level  = $i-1
            $parent.Folder = $folder
            # $parent.Parent points to the ID of the current parent folder 
            $parent.Parent = $myparentid
            $parents += $parent
        }
        # No changes below this line        
        # Now parent becomes the current folder       
        $myparentid = (Get-View -ViewType Folder | Where-Object { $_.childtype -like "VirtualMachine" -and $_.Name -eq $folder -and $_.Parent -eq $myparentid }).MoRef 
        Write-Host "New Parentid is now" $myparentid
        
        # Set $i for the next level, remember we count 0, -1, -2, -3 etc. 
        $i--
        # and grap the next folder in the line
        $folder = $line.split("/")[$i-1]
        Write-Host "### Next folder in line is:" $folder
    }until ($folder -eq "") # Stop when we reach left of the first /
    
    Write-Host "### ### Next Line of input"
}

Write-Host "Parents" $parents
Write-Host "What Get-View shows"
Get-View -ViewType Folder | Where-Object { $_.childtype -like "VirtualMachine"} | select Name,Moref,Parent | ft
