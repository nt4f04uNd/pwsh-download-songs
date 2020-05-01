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
         Write-Error "Album art asset not found for '$($_.Name)'.`nNote that only .png and .jpg/.jpeg are supported"
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
# SIG # Begin signature block
# MIIUTQYJKoZIhvcNAQcCoIIUPjCCFDoCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDkHaHb72M0PnB8
# 1A0i8KAnPzf6p3RgvweRIWkb/bD4I6CCDf8wggQUMIIC/KADAgECAgsEAAAAAAEv
# TuFS1zANBgkqhkiG9w0BAQUFADBXMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xv
# YmFsU2lnbiBudi1zYTEQMA4GA1UECxMHUm9vdCBDQTEbMBkGA1UEAxMSR2xvYmFs
# U2lnbiBSb290IENBMB4XDTExMDQxMzEwMDAwMFoXDTI4MDEyODEyMDAwMFowUjEL
# MAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExKDAmBgNVBAMT
# H0dsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gRzIwggEiMA0GCSqGSIb3DQEB
# AQUAA4IBDwAwggEKAoIBAQCU72X4tVefoFMNNAbrCR+3Rxhqy/Bb5P8npTTR94ka
# v56xzRJBbmbUgaCFi2RaRi+ZoI13seK8XN0i12pn0LvoynTei08NsFLlkFvrRw7x
# 55+cC5BlPheWMEVybTmhFzbKuaCMG08IGfaBMa1hFqRi5rRAnsP8+5X2+7UulYGY
# 4O/F69gCWXh396rjUmtQkSnF/PfNk2XSYGEi8gb7Mt0WUfoO/Yow8BcJp7vzBK6r
# kOds33qp9O/EYidfb5ltOHSqEYva38cUTOmFsuzCfUomj+dWuqbgz5JTgHT0A+xo
# smC8hCAAgxuh7rR0BcEpjmLQR7H68FPMGPkuO/lwfrQlAgMBAAGjgeUwgeIwDgYD
# VR0PAQH/BAQDAgEGMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFEbYPv/c
# 477/g+b0hZuw3WrWFKnBMEcGA1UdIARAMD4wPAYEVR0gADA0MDIGCCsGAQUFBwIB
# FiZodHRwczovL3d3dy5nbG9iYWxzaWduLmNvbS9yZXBvc2l0b3J5LzAzBgNVHR8E
# LDAqMCigJqAkhiJodHRwOi8vY3JsLmdsb2JhbHNpZ24ubmV0L3Jvb3QuY3JsMB8G
# A1UdIwQYMBaAFGB7ZhpFDZfKiVAvfQTNNKj//P1LMA0GCSqGSIb3DQEBBQUAA4IB
# AQBOXlaQHka02Ukx87sXOSgbwhbd/UHcCQUEm2+yoprWmS5AmQBVteo/pSB204Y0
# 1BfMVTrHgu7vqLq82AafFVDfzRZ7UjoC1xka/a/weFzgS8UY3zokHtqsuKlYBAIH
# MNuwEl7+Mb7wBEj08HD4Ol5Wg889+w289MXtl5251NulJ4TjOJuLpzWGRCCkO22k
# aguhg/0o69rvKPbMiF37CjsAq+Ah6+IvNWwPjjRFl+ui95kzNX7Lmoq7RU3nP5/C
# 2Yr6ZbJux35l/+iS4SwxovewJzZIjyZvO+5Ndh95w+V/ljW8LQ7MAbCOf/9RgICn
# ktSzREZkjIdPFmMHMUtjsN/zMIIEnzCCA4egAwIBAgISESHWmadklz7x+EJ+6RnM
# U0EUMA0GCSqGSIb3DQEBBQUAMFIxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9i
# YWxTaWduIG52LXNhMSgwJgYDVQQDEx9HbG9iYWxTaWduIFRpbWVzdGFtcGluZyBD
# QSAtIEcyMB4XDTE2MDUyNDAwMDAwMFoXDTI3MDYyNDAwMDAwMFowYDELMAkGA1UE
# BhMCU0cxHzAdBgNVBAoTFkdNTyBHbG9iYWxTaWduIFB0ZSBMdGQxMDAuBgNVBAMT
# J0dsb2JhbFNpZ24gVFNBIGZvciBNUyBBdXRoZW50aWNvZGUgLSBHMjCCASIwDQYJ
# KoZIhvcNAQEBBQADggEPADCCAQoCggEBALAXrqLTtgQwVh5YD7HtVaTWVMvY9nM6
# 7F1eqyX9NqX6hMNhQMVGtVlSO0KiLl8TYhCpW+Zz1pIlsX0j4wazhzoOQ/DXAIlT
# ohExUihuXUByPPIJd6dJkpfUbJCgdqf9uNyznfIHYCxPWJgAa9MVVOD63f+ALF8Y
# ppj/1KvsoUVZsi5vYl3g2Rmsi1ecqCYr2RelENJHCBpwLDOLf2iAKrWhXWvdjQIC
# KQOqfDe7uylOPVOTs6b6j9JYkxVMuS2rgKOjJfuv9whksHpED1wQ119hN6pOa9PS
# UyWdgnP6LPlysKkZOSpQ+qnQPDrK6Fvv9V9R9PkK2Zc13mqF5iMEQq8CAwEAAaOC
# AV8wggFbMA4GA1UdDwEB/wQEAwIHgDBMBgNVHSAERTBDMEEGCSsGAQQBoDIBHjA0
# MDIGCCsGAQUFBwIBFiZodHRwczovL3d3dy5nbG9iYWxzaWduLmNvbS9yZXBvc2l0
# b3J5LzAJBgNVHRMEAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMEIGA1UdHwQ7
# MDkwN6A1oDOGMWh0dHA6Ly9jcmwuZ2xvYmFsc2lnbi5jb20vZ3MvZ3N0aW1lc3Rh
# bXBpbmdnMi5jcmwwVAYIKwYBBQUHAQEESDBGMEQGCCsGAQUFBzAChjhodHRwOi8v
# c2VjdXJlLmdsb2JhbHNpZ24uY29tL2NhY2VydC9nc3RpbWVzdGFtcGluZ2cyLmNy
# dDAdBgNVHQ4EFgQU1KKESjhaGH+6TzBQvZ3VeofWCfcwHwYDVR0jBBgwFoAURtg+
# /9zjvv+D5vSFm7DdatYUqcEwDQYJKoZIhvcNAQEFBQADggEBAI+pGpFtBKY3IA6D
# lt4j02tuH27dZD1oISK1+Ec2aY7hpUXHJKIitykJzFRarsa8zWOOsz1QSOW0zK7N
# ko2eKIsTShGqvaPv07I2/LShcr9tl2N5jES8cC9+87zdglOrGvbr+hyXvLY3nKQc
# MLyrvC1HNt+SIAPoccZY9nUFmjTwC1lagkQ0qoDkL4T2R12WybbKyp23prrkUNPU
# N7i6IA7Q05IqW8RZu6Ft2zzORJ3BOCqt4429zQl3GhC+ZwoCNmSIubMbJu7nnmDE
# Rqi8YTNsz065nLlq8J83/rU9T5rTTf/eII5Ol6b9nwm8TcoYdsmwTYVQ8oDSHQb1
# WAQHsRgwggVAMIIDKKADAgECAhBrPtF6EkS3sEgQtchsbRn4MA0GCSqGSIb3DQEB
# CwUAMDgxEjAQBgNVBAMMCW50NGYwNHVOZDEiMCAGCSqGSIb3DQEJARYTbnQ0ZjA0
# dW5kQGdtYWlsLmNvbTAeFw0yMDA1MDExNjMwNDRaFw0yNTA1MDExNjQwNDJaMDgx
# EjAQBgNVBAMMCW50NGYwNHVOZDEiMCAGCSqGSIb3DQEJARYTbnQ0ZjA0dW5kQGdt
# YWlsLmNvbTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALg95/MUewLb
# PglnVtNCBXE3aW6O07rSCiAWD9hsYBlR3jtninrVtX2ICiEnMb4kaqATsBR18gOo
# dW04VUT/VtucMG8ivw7QQK6mS4YumQchscW2T4BwOzbWEc+SlSwGp5iVWFEL4teZ
# hJCrbTf3bnj1CoxV2HJbtLOiHDrkOpX9geOUjtfsvaYcVR0rI1lQx0URxcA6uaQD
# +nj3oD2JS2sVhKq211r9NY5pQWWiJFZgftzugMlrCnOyOLyLOmsBZI4t8IIP69I2
# EQ2Ot6kUzdb/+khRh4M8qbHXF0ABhVT9qeAQ9zYoxa27IlNnBfOGhFzNi7esJDU7
# eM4YI7V0OLRAyY6Ja8cvl045IRs/gKowhXdbh0T0LMli+6HGToGD64i6MA1H+oHX
# X+Y0Oxhi/IoJpctLuAOPQaRNE4ZwYug105fbu6/K+XFso/LOBFSk3x3i1JZBBUN7
# SK4RJ58c4Fi0hsiwejc5S4HkDDTSrjeKoZEIrExVrcYl5Xjr9jzHzj/L7DEFjQzk
# 6VrMdaj4K7eaxLmB+tL6B8MeNs3J57JOisysrJWrdI64lYy6+xo4TQKmrsoqfUxU
# WGQCij9J1iQaA6RQG+a5DfXstOtOvBP69PQAPTY0DnMNHkka5IUHT6T91FXVfxjd
# wzJhR25sUeWTEe426DpdI9yS4DdnoX0hAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIH
# gDATBgNVHSUEDDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQUTb3vtrm0+qP6ocdBdvPD
# qyn6ry0wDQYJKoZIhvcNAQELBQADggIBAC9/YvCnzW9j2lggujyNY8+21StYnRSd
# Vi/gkg5ZaG/czAa0kF63Loxs5gtpPuZyGBOVRasBaLQ1JrPU4AGkDzKsXLDTAkWf
# +WKdM+PDzJPyAxpv9DOjlgurTa8jgsLFAs/Xxgj9vrYgFGgg4f5zENzlFkL8fTDz
# ANQmzNZC80CLCrFAZnYrLJhoe1GraJrkaIMLCVtwUldQ9Di2RyBvshRG02od7vks
# +viN30b80To0tvTsETXlTZcixo+8w0Ym8bU6ZHtREQ+F/4x4p+P0POLRb9iai/Bo
# QNB+lEcRJkz//+IXp9/85D0mvp5Gt8u0QvW4ub7WS2bEgHedCOSxoCIezPSV8KQN
# jPJurBu5o0I3+3tWPBYVn4Qga/u+jDoeJCPELlGzY+tKdR9huWG4hHpBhD6fjIqJ
# tMzfwJ8UOn9IegzgpY3x/xqrBesT1D/I7q9H5RcmfhqQOXH2m1wjNFOGlY7C5v1a
# XSAhrcjcRg/V71rRd/HUrFqddb62TPf19Hcg/t7lms0jbx4/aOjIQnPz6CYmu4b/
# i2HtHxIjOFNWgWmuH7Gn8iIkgNo0jSLeX8KuH5tb+vnsbFCejZCassacD5VKy8OP
# DuHB836S9GtA72yOH3uzSV0x/mMVgJXQhezAtJnVH6snLrAWhMsyjunYxIfB1qnI
# yQ4HsbxUEM8aMYIFpDCCBaACAQEwTDA4MRIwEAYDVQQDDAludDRmMDR1TmQxIjAg
# BgkqhkiG9w0BCQEWE250NGYwNHVuZEBnbWFpbC5jb20CEGs+0XoSRLewSBC1yGxt
# GfgwDQYJYIZIAWUDBAIBBQCggYQwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZ
# BgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYB
# BAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgIlftavTn811qh2rrlsg1BNajYTW4EfYI
# VRMcyjh0SOswDQYJKoZIhvcNAQEBBQAEggIAR1qarN5KVmC6spsHN/mhdxRuLFUl
# u20LFUcqTA2xNlrFCyZy8eWlEWbhgajwpBcDzb7Iji9bKigiR80z3UWo3hPIKwWP
# WO6uJJ7cLmgua7m8a+434GysCgp16RvAMBfnVP14jVVBOuP7QLM8fIPQVJwjN1DV
# PZK18ihtOLNA3J6qisjI9jrOUx7M4hPq4kNnOJ0NVCgX13kVmePuEGHN+9nledkP
# n6FPTm/Xf3Fwpx2MciseZig29uttt3aOn49xA44M52HbOWEeKJK9GT5qsXU6R9uT
# 3K6Uh8lEWpl2guw6KbYKQhipGlJZuTnq0gpxS+xSTrZvfIy7rvUZ12nHFgZsaYm6
# ZGZu0YeDAKJVzfAZAjl0TQrOoY/CsSx74jZdcNVcSyHsMlaOtX3hdsWVcDlQCKU8
# G0z42DZDEHjlOJRwqyLEgIJRfKesSA5c/oc1B+NAY0nw/8TSj3AL1rM/iCMIuaOm
# kDwDxwmtRzjncudxzsEvHVHZumHymdI2NnJnV3qtPMM3MPJXNhYX7vp+U7it6fOF
# 3XZG4rPN41z1bd2YvVotCCs2wmBi1SpM0lCoq/2sR+2jrhLzOEs7Fvqk+IUIA6gb
# fFWu68nPmnzs+6MeRiDH6Q4fAUSouCE0C3LlgKCptT0rdsAVB8HyqGhka7pJDqfY
# pS0Ai7uqr8ZmwNahggKiMIICngYJKoZIhvcNAQkGMYICjzCCAosCAQEwaDBSMQsw
# CQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTEoMCYGA1UEAxMf
# R2xvYmFsU2lnbiBUaW1lc3RhbXBpbmcgQ0EgLSBHMgISESHWmadklz7x+EJ+6RnM
# U0EUMAkGBSsOAwIaBQCggf0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkq
# hkiG9w0BCQUxDxcNMjAwNTAxMTcwNzQ1WjAjBgkqhkiG9w0BCQQxFgQUDuJEGDak
# FUy+hSD9uKGcMiWD/nYwgZ0GCyqGSIb3DQEJEAIMMYGNMIGKMIGHMIGEBBRjuC+r
# YfWDkJaVBQsAJJxQKTPseTBsMFakVDBSMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQ
# R2xvYmFsU2lnbiBudi1zYTEoMCYGA1UEAxMfR2xvYmFsU2lnbiBUaW1lc3RhbXBp
# bmcgQ0EgLSBHMgISESHWmadklz7x+EJ+6RnMU0EUMA0GCSqGSIb3DQEBAQUABIIB
# AA+K04MhAvO3WXNH2r2oh/JouKaDfg2MyQbXupPqA2Dx21EN883gLRevrQxT2lW7
# foU4t8T5OHG5B0gkNo0Xy4lmPk4f2bVNtVl1F/IITt0IWqcqSInr4OAydWinx2WH
# SEsAR3bpevxhKuN+EHZOUJioz1JG1NjDHNSjgKqv1QKsWEqN8t6rBcEbaXpp2Y3T
# VpchPp3vuYikJo38Cx+HU8jcE5jNHWfiVfsSGKgCpqO105T9VgvchTq+2ci8Hv+x
# hapAsn+eqa6pqHKZXdtl1ex9f0Em5CSiQQWxPqvrn+sgvF/yue4iz2TOw8v7HQuT
# ayttfQ1ug+22C7ry4P2HXfQ=
# SIG # End signature block
