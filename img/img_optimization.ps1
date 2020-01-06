param(
    $Path = (Join-Path $PSScriptRoot "original"),
    $imageRootPath = $PSScriptRoot, # expected same as location of script,
    $oldExtension = "*.jpg",
    $newExtension = ".jpeg",
    $size = "1920x780"
)

$null = Test-Path -Path $Path

$Images = Get-ChildItem -Path $Path -Recurse -Include $oldExtension

foreach ($Image in $Images) {
    
    $extension = [IO.Path]::GetExtension($images[0]) 
    $newImage = $image.Name -replace $extension , $newExtension
    
    magick $Image -quality 85 -strip -resize $size $newImage
}