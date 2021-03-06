# Powershell Songs Download

[Читать на русском](./README_RU.md)

This is simple powershell utility to easily grab and download songs and playlists
from popular websites.  

It automatically inserts metadata to files and embeds cool squared album arts (if there are so and source file is one of the followings: `.mp3, .m4a, .m4b, .m4p, .m4v, .mp4`, which is true in most cases).

![demo](https://github.com/nt4f04uNd/pwsh-download-songs/blob/master/demo.gif?raw=true)

## Installation

Run the following command to install dependencies (you'll need the `choco`)

```powershell
choco install youtube-dl ffmpeg imagemagick.app atomicparsley -y
```

Then install the powershell module itself

```powershell
install-module -name pwsh-download-songs
```

Note that you probably won't be able to use the module because it's self-signed and considered untrusted. There're two options here:

1. Run

```powershell
(get-module pwsh-download-songs).path
```

Then go to this path (for me it is `C:\dev\projects\pwsh\pwsh-download-songs\pwsh-download-songs.psm1`), open the properties of the `pwsh-download-songs.psm1`, click on "Digital signatures" tab and make the certificate trusted.

2. Or, to allow running untrusted powershell scripts and modules, for that change the execution policy by running

```powershell
Set-ExecutionPolicy RemoteSigned
```

## Usage

To see the help from console, use the following command in powershell

```powershell
get-help download-songs -full
```

### **Syntax**

`download-songs [-url] <String[]> [[-format] <String[]>] [-noPlaylist] [-saveThumbs] [-seeFormats] [<CommonParameters>]`

### **Parameters description**

**-url <String[]>** - the url to save songs from.

**-format <String[]>** - the requested format. Use -seeFormats parameter to check without downloading anything what formats are available.
Passed to youtube-dl, so check its -f parameter and [its doc](https://github.com/ytdl-org/youtube-dl/blob/master/README.md#format-selection).
Defaults to `"m4a/mp3/bestaudio"`.

**-noPlaylist** - whether to download only the song/video, if the URL refers to a song/video and a playlist. Defaults to `$false`. See youtube-dl --no-playlist param.

**-saveThumbs** - whether to save the song thumb image files after the download process. Defaults to `$false`.

**-seeFormats** - if true, the songs/videos won't be downloaded, but the command will output the available formats. Defaults to `$false`.

### **Examples**

Download the single song [**Yxngxr1 - Falling 4 U**](https://music.youtube.com/watch?v=jCcGMtGRw5s&list=PLv5tSVP9eg2nkbqapepgxXYGCESsfLcu9) in default `.m4a` format from the YouTube Music playlist

```powershell
 download-songs -noPlaylist "https://music.youtube.com/watch?v=jCcGMtGRw5s&list=PLv5tSVP9eg2nkbqapepgxXYGCESsfLcu9"
```

Check all the available formats for the single song [**Psycho**](https://www.youtube.com/watch?v=3ITW3pWaoWQ&list=OLAK5uy_mmO6QLOUTnk7GWFp_CVKH7B0gDgpGJI1A&index=2) from the YouTube Music album [**Yxngxr1 - I Don't Suit Hats**](https://music.youtube.com/playlist?list=OLAK5uy_mmO6QLOUTnk7GWFp_CVKH7B0gDgpGJI1A)

```powershell
download-songs -seeFormats -noPlaylist "https://www.youtube.com/watch?v=3ITW3pWaoWQ&list=OLAK5uy_mmO6QLOUTnk7GWFp_CVKH7B0gDgpGJI1A&index=2"
```

Download the whole playlist [**Yxngxr1**](https://music.youtube.com/playlist?list=PLv5tSVP9eg2nkbqapepgxXYGCESsfLcu9) from YouTube Music (despite the url points on a track) and save all its thumbs

```powershell
 download-songs -saveThumbs "https://music.youtube.com/watch?v=jCcGMtGRw5s&list=PLv5tSVP9eg2nkbqapepgxXYGCESsfLcu9"
```

## Removal

Respectively

```powershell
choco uninstall youtube-dl ffmpeg imagemagick.app atomicparsley -y
```

```powershell
remove-module -name pwsh-download-songs
```

## Related links

* [pwsh-download-songs package](https://www.powershellgallery.com/packages/pwsh-download-songs/)
* [youtube-dl github repo](https://github.com/ytdl-org/youtube-dl)
