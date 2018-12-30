# FolderExport.ps1
#
# Script export all folders from the "Virtual machines and Templates" section of a vCenter Server
# in this format: /Subfolder/Folder/RootFolder
# and dumps to file vmfolder.txt
#
# Note: script is not finished yest and needs to be converted to a function with parameters and errorhandling 

$array = Get-View -ViewType Folder | Where-Object { $_.childtype -like "VirtualMachine"} | select Name,Moref,Parent
$myouts = @()

$array | ForEach-Object {
    $myout = ""
    $folder =$_.Name
    $parent = $_.Parent

    while ($folder -ne "vm" -and $parent -notlike "Datacenter-datacenter*") {
        $myout = $myout+"/"+$folder
        # If we have a parent folder, we go recursive
        # $folder is now the parent folder
        # until we found the root folder vm
        $folder = ($array | Where-Object { $_.Moref -eq $parent}).Name
        $parent = ($array | Where-Object { $_.Moref -eq $parent}).Parent
    }
    $myouts += $myout    
}
$myouts > vmfolder.txt
