# Powershell Songs Download

[Read this in English](./README.md)

Это простой модуль для powershell, позволяющий легко скачивать песни и плейлисты с популярных сайтов.

При скачивании в файлы автоматически будет вставлены все доступные метаданные (альбом, исполнитель, название, год выпуска и т.д.), а также обрезанная до квадрата обложка альбома (если доступны форматы `.png` или `.jpg/.jpeg`, а скачиваемый сорс-файл одного из форматов: `.mp3, .m4a, .m4b, .m4p, .m4v, .mp4` - что является правдой в большинстве случаев)

![demo](https://github.com/nt4f04uNd/pwsh-download-songs/blob/master/demo.gif?raw=true)

## Установка

Запустите следующую команду для установки зависимостей (вам понадобится `choco`)

```powershell
choco install youtube-dl ffmpeg imagemagick.app atomicparsley -y
```

Затем установите сам модуль

```powershell
install-module -name pwsh-download-songs
```

Скорее всего, вы не сможете пользоваться модулем, так как он имеет самоподписанный сертификат, который считается недоверенным. Чтобы позволить запускать недоверенные скрипты и модули, пропишите следующую команду, которая изменит Execution Policy

```powershell
Set-ExecutionPolicy RemoteSigned
```

## Использование

Чтобы посмотреть помощь из консоли, используйте следующую команду powershell

```powershell
get-help download-songs -full
```

### **Синтаксис**

`download-songs [-url] <String[]> [[-format] <String[]>] [-noPlaylist] [-saveThumbs] [-seeFormats] [<CommonParameters>]`

### **Описание параметров**

**-url <String[]>** - url, откуда скачивать.

**-format <String[]>** - запрашиваемый формат. Используйте параметр -seeFormats для того, чтобы посмотреть, какие форматы доступны, ничего не скачивая
Этот есть в youtube-dl, поэтому смотрите -f параметр и [его документацию](https://github.com/ytdl-org/youtube-dl/blob/master/README.md#format-selection).
По умолчанию `"m4a/mp3/bestaudio"`.

**-noPlaylist** - скачивать ли песню/видео, если URL указывает одновременно и на песню/видео, и на плейлист. По умолчанию `$false`. Смотрите youtube-dl --no-playlist параметр.

**-saveThumbs** - сохранять ли скачанные картинки альбомов после завершения команды. По умолчанию `$false`.

**-seeFormats** - если `$true`, то ничего не будет скачиваться, а команда покажет для загрузки доступные форматы. По умолчанию `$false`.

### **Примеры**

Скачать песню [**Yxngxr1 - Falling 4 U**](https://music.youtube.com/watch?v=jCcGMtGRw5s&list=PLv5tSVP9eg2nkbqapepgxXYGCESsfLcu9) в стандартном формате `.m4a` из плейлиста на YouTube Music

```powershell
 download-songs -noPlaylist "https://music.youtube.com/watch?v=jCcGMtGRw5s&list=PLv5tSVP9eg2nkbqapepgxXYGCESsfLcu9"
```

Вывести все доступные форматы для песни [**Psycho**](https://www.youtube.com/watch?v=3ITW3pWaoWQ&list=OLAK5uy_mmO6QLOUTnk7GWFp_CVKH7B0gDgpGJI1A&index=2) из альбома [**Yxngxr1 - I Don't Suit Hats**](https://music.youtube.com/playlist?list=OLAK5uy_mmO6QLOUTnk7GWFp_CVKH7B0gDgpGJI1A) на YouTube Music

```powershell
download-songs -seeFormats -noPlaylist "https://www.youtube.com/watch?v=3ITW3pWaoWQ&list=OLAK5uy_mmO6QLOUTnk7GWFp_CVKH7B0gDgpGJI1A&index=2"
```

Скачать весь плейлист [**Yxngxr1**](https://music.youtube.com/playlist?list=PLv5tSVP9eg2nkbqapepgxXYGCESsfLcu9) на YouTube Music (несмотря на то, что url также указывает на трек), а также сохранить обложки альбомов всех песен

```powershell
 download-songs -saveThumbs "https://music.youtube.com/watch?v=jCcGMtGRw5s&list=PLv5tSVP9eg2nkbqapepgxXYGCESsfLcu9"
```

## Удаление

Соответственно

```powershell
choco uninstall youtube-dl ffmpeg imagemagick.app atomicparsley -y
```

```powershell
remove-module -Name pwsh-download-songs
```

## Ссылки

* [pwsh-download-songs package](https://www.powershellgallery.com/packages/pwsh-download-songs/)
* [youtube-dl github repo](https://github.com/ytdl-org/youtube-dl)
