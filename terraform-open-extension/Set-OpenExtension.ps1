param (
    [Parameter(Mandatory=$true)]
    [string]$Type,

    [Parameter(Mandatory=$true)]
    [string]$ObjectId,

    [Parameter(Mandatory=$true)]
    [string]$Name,

    [Parameter(Mandatory=$true)]
    [string]$Values,

    [string]$Token
)

# If token is not provided, fetch from az cli
if([string]::IsNullOrEmpty($string)){
    $azToken = az account get-access-token --resource-type ms-graph --query accessToken -o tsv | ConvertTo-SecureString -AsPlainText
} else {
    $azToken = $Token | ConvertTo-SecureString -AsPlainText
}

# Create URL to call when retriving or updating a specific extension
$url_pattern_get = "https://graph.microsoft.com/v1.0/{0}/{1}/extensions/{2}"
$url_get = $url_pattern_get -f $Type, $ObjectId, $Name

# Create URL to call when creating a new extension
$url_pattern_create = "https://graph.microsoft.com/v1.0/{0}/{1}/extensions"
$url_create = $url_pattern_create  -f $Type, $ObjectId

# Create Body
$body = $Values | ConvertFrom-Json -AsHashtable
$body["extensionName"] = $Name
$body = $body | ConvertTo-Json -Depth 100

# Try to retrive existing extensions with the current id

$existingExtensions = Invoke-WebRequest $url_get -Method GET -ContentType 'application/json' -Authentication Bearer -Token $azToken -SkipHttpErrorCheck

# If no existing extension found, inserta new one, else update the existing one
if($existingExtensions.StatusCode -eq 404) {
    Invoke-RestMethod $url_create -Method POST -ContentType 'application/json' -Body $body -Authentication Bearer -Token $azToken | Out-Null
    Write-Output "Extension successfully created"
} else {
    Invoke-RestMethod $url_get -Method PATCH -ContentType 'application/json' -Body $body -Authentication Bearer -Token $azToken | Out-Null
    Write-Output "Extension successfully updated"
}


