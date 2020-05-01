#---------------------------------------------------------------------------------------------
#  Copyright (c) nt4f04und. All rights reserved.
#  Licensed under the BSD-style license. See LICENSE in the project root for license information.
#---------------------------------------------------------------------------------------------

<#
 .Synopsis
  Downloads audio/video files from popular sites like youtube, and treats them, so they look nice.

 .Description
  Downloads audio/video files from popular sites like youtube, and treats them so they look nice.
  Inserts metadata to files and embeds squared album arts (if .png or .jpg/.jpeg format is available 
  and source file is one of the followings: .mp3, .m4a, .m4b, .m4p, .m4v, .mp4).

  For its work this function requires some dependencies
  See https://github.com/nt4f04und/pwsh-download-songs for installation instructions.

  For full list of available sites see youtube-dl supported sites
  https://ytdl-org.github.io/youtube-dl/supportedsites.html

  .LINK
  youtube-dl docs - https://ytdl-org.github.io/youtube-dl
  github repo with installation instructions - https://github.com/nt4f04und/pwsh-download-songs

 .Parameter url
  The url to save songs from. 
  Mandatory.

 .Parameter format
  The requested format. Use -seeFormats paramater to check what formats are available. 
  Passed to youtube-dl, so check its -f parameter and [its doc](https://github.com/ytdl-org/youtube-dl/blob/master/README.md#format-selection).
  "m4a/mp3/bestaudio" by defalt.
  
 .Parameter noPlaylist
  Whether to download only the song/video, if the URL refers to a song/video and a playlist. 
  False by default. 
  See youtube-dl --no-playlist param.

 .Parameter saveThumbs
  Whether to erase the song thumb image files after the download process.
  False by default.

 .Parameter seeFormats
  If true, the the songs/videos won't be downloaded, but the command will output the available formats.
  False by default.

 .Example
   Download single song "Yxngxr1 - Falling 4 U" in default .m4a format from the YouTube Music playlist
   download-songs -noPlaylist "https://music.youtube.com/watch?v=jCcGMtGRw5s&list=PLv5tSVP9eg2nkbqapepgxXYGCESsfLcu9"

 .Example
   Check all available formats for a single song "Psycho" from the YouTube Music album "Yxngxr1 - I Don't Suit Hats"
   download-songs -seeFormats -noPlaylist "https://www.youtube.com/watch?v=3ITW3pWaoWQ&list=OLAK5uy_mmO6QLOUTnk7GWFp_CVKH7B0gDgpGJI1A&index=2"

 .Example
   Download the whole playlist "Yxngxr1" from YouTube Music (despite the url points on a track) and save its thumbs
   download-songs -saveThumbs "https://music.youtube.com/watch?v=jCcGMtGRw5s&list=PLv5tSVP9eg2nkbqapepgxXYGCESsfLcu9"
#>
function download-songs {
   Param
   (
      [Parameter(Mandatory)]
      [string[]]$url,
      [string[]]$format = "m4a/mp3/bestaudio",
      [switch]$noPlaylist,
      [switch]$saveThumbs,
      [switch]$seeFormats
   )

   $ERROR_MESSAGE = "- command doesn't exists. See https://github.com/nt4f04und/pwsh-download-songs to install needed dependencies."

   # Checks if command exists
   function Check-Command($cmdname)
   {
      return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
   }

   if (!$(Check-Command -cmdname 'ffmpeg')) {
      throw "ffmpeg $ERROR_MESSAGE"
   }
   if (!$(Check-Command -cmdname 'youtube-dl')) {
      throw "youtube-dl $ERROR_MESSAGE"
   }

   $PREFIX = "[ STAGE ]"
   if ($seeFormats) {
      Write-Output "$PREFIX Checking the available formats..." `n
   }
   else {
      Write-Output "$PREFIX Downloading songs and album arts..." `n
   }

   if ($seeFormats) {
      if ($noPlaylist) {
         youtube-dl -F "$url" --console-title --no-playlist
      }
      else {
         youtube-dl -F "$url" --console-title
      }
      return
   }
   else {
      #lowercase letters/numbers only id
      $BASE_FOLDER = "songs_load_" + -join ((48..57) + (97..122) | Get-Random -Count 20 | ForEach-Object { [char]$_ })
      mkdir $BASE_FOLDER
   
      if ($noPlaylist) {
         youtube-dl -f "$format" "$url" --console-title -o "$BASE_FOLDER\%(creator)s - %(title)s.%(ext)s" --write-thumbnail --add-metadata --no-playlist
      }
      else {
         youtube-dl -f "$format" "$url" --console-title -o "$BASE_FOLDER\%(creator)s - %(title)s.%(ext)s" --write-thumbnail --add-metadata
      }
   }

   # Autimatically removes NA from song and image names
   Get-ChildItem $BASE_FOLDER\*.* | Move-Item -Force -Path { "$BASE_FOLDER\$($_.Name)" } -Destination { "$BASE_FOLDER\$($_.Name -replace 'NA - ', '')" }

   if (!$(Check-Command -cmdname 'magick')) {
      throw "magick $ERROR_MESSAGE"
   }
   Write-Output `n"$PREFIX Cropping album arts to squares..." `n
   magick mogrify -quality 100 -set option:distort:viewport "%[fx:w>h?h:w]x%[fx:w>h?h:w]+%[fx:w>h?(w-h)/2:0]+%[fx:w>h?0:(h-w)/2]" -filter point -distort SRT 0 +repage "$BASE_FOLDER\*.jpg" 

   Write-Output `n"$PREFIX Inserting album arts into songs... (only for .mp3, .m4a, .m4b, .m4p, .m4v and .mp4 files)" `n
   Get-ChildItem ".\$BASE_FOLDER\*" -Include `
      *.mp3, *.m4a, *.m4b, *.m4p, *.m4v, *.mp4 `
   | Foreach-Object { 
      $name = [io.path]::GetFileNameWithoutExtension($_.Name)
      $ext = [io.path]::GetExtension($_.Name)
 
      $imgSearch = @(Get-ChildItem "$BASE_FOLDER\$name.jpg")
      if ($imgSearch.length -eq 0) {
         $imgSearch = @(Get-ChildItem "$BASE_FOLDER\$name.png")
      }
      if ($imgSearch.length -eq 0) {
         $imgSearch = @(Get-ChildItem "$BASE_FOLDER\$name.jpeg")
      }
      if ($imgSearch.length -eq 0) {
         Write-Throw "Album art asset not found for $($_.Name).`nNote that only .png and .jpg/.jpeg are supported)"
         return
      }

      if ($ext -eq ".mp3") {
         ffmpeg -y -i "$BASE_FOLDER\$($_.Name)" -i "$BASE_FOLDER\$($imgSearch[0].Name)" -map 0 -map 1 -c copy -id3v2_version 3 -metadata:s:v title="Album cover" -metadata:s:v comment="Cover (front)" "$BASE_FOLDER\$($name)_temp.mp3"
         # ffmpeg can't write to the same file, so rename the output
         Get-ChildItem "$BASE_FOLDER\$($name)_temp.mp3" | Move-Item -Force -Path { "$BASE_FOLDER\$($_.Name)" } -Destination { "$BASE_FOLDER\$($_.Name -replace '_temp', '')" }
      }
      else {
         if (!$(Check-Command -cmdname 'AtomicParsley')){
            throw "AtomicParsley $ERROR_MESSAGE"
         }
         AtomicParsley "$BASE_FOLDER\$($_.Name)" --artwork "$BASE_FOLDER\$($imgSearch[0].Name)" --overWrite 
      }
   }

   if (!$saveThumbs) {
      Remove-Item $BASE_FOLDER\*.jpeg
      Remove-Item $BASE_FOLDER\*.jpg
      Remove-Item $BASE_FOLDER\*.png
      Remove-Item $BASE_FOLDER\*.png
      Remove-Item $BASE_FOLDER\*.gif
      Remove-Item $BASE_FOLDER\*.webp
      Remove-Item $BASE_FOLDER\*.bmp
   }

}
Export-ModuleMember -Function download-songs