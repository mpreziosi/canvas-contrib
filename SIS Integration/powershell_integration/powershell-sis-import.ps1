$sourceDir = "c\canvas\" #this is source directory literal path
$outputPath = "c:\canvasoutput\" #output path for the zip file creation
$account_id = "1"
$token = "2435~B56Bqm2vmzy4IPX0OuCbl8IKjwNMWSlgL27bf5y54S3TxDgIydJJlb5ofvOrDlDc" # access_token
$domain = "neit.test.instructure.com"
$outputZip = "courses1.csv.zip" # name of the zip file to create

#################################################
###### Don't edit anything after this line ######
#################################################
$url = "https://$domain/api/v1/accounts/"+$account_id+"/sis_imports.json?import_type=instructure_csv"
$headers = @{"Authorization"="Bearer "+$token}

# Just in case $sourceDir doesn't end with a \, add it.
if(!($sourceDir.EndsWith('\'))){
    $sourceDir += "\"
    Write-Host "You sourceDir didn't end with a \ so I added one.  It really is important"
}
if($outputZip.Contains('\')){
    Write-Host "The outputZip should not contain backslashes.  You are warned"
}

###### Some functions

$contentType = "application/zip" # don't change
$InFile = $outputPath+$outputZip # don't change
write-zip -Path $sourceDir"*.csv" -OutputPath $InFile

$t = get-date -format M_d_y_h
$status_log_path = $outputPath+$t+"-status.log"
#Write-Host "infile:"$InFile
#Write-Host "contentType:"$contentType
#$results = invoke-RestMethod -Headers $headers -InFile $InFile -Method POST  -ContentType $contentType -uri $url -PassThru -OutFile $outputPath$t"-status.log"

$results1 = (Invoke-WebRequest -Headers $headers -InFile $InFile -Method POST -ContentType $contentType -Uri $url) #-PassThru -OutFile $outputPath$t"-status.log"
$results1.Content | Out-File $status_log_path
$results = ($results1.Content | ConvertFrom-Json)
#$results.id | Out-String
do{
  Write-Host $status_line
  $status_url = "https://$domain/api/v1/accounts/"+$account_id+"/sis_imports/"+$results.id
  $results1 = (Invoke-WebRequest -Headers $headers -Method GET -Uri $status_url) #-PassThru -OutFile $outputPath$t"-status.log"
  $results1.Content | Out-File -Append $status_log_path
  $results = ($results1.Content | ConvertFrom-Json)
  Start-Sleep -s 5
  #$results.id | Out-String
 if($results -eq $null){
    break
  }
}
while($results.progress -lt 100 -and $results.workflow_state -ne "failed_with_messages")
$results1.Content | Out-File -Append $status_log_path

# The sis import is done, you might do something else here like trigger course copies

Move-Item -Force $outputPath$outputZip $outputPath$t-$outputZip
Remove-Item $sourceDir*.csv
