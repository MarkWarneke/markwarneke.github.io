param(
    $Path = (Join-Path $PSScriptRoot "original"),
    $imageRootPath = $PSScriptRoot # expected same as location of script
)

$null = Test-Path -Path $Path

$Images = Get-ChildItem -Path $Path -Recurse -Include "*.jpg"

foreach ($Image in $Images) {
    
    $extension = [IO.Path]::GetExtension($images[0]) 
    $newImage = $image.Name -replace $extension , ".jpeg"
    
    magick $Image -quality 85 -strip -resize 1920x780 $newImage
}