# Seanime Docker

A simple, Docker image for [Seanime](https://seanime.rahim.app/).

Video transcoding via [FFmpeg](https://ffmpeg.org/) works out of the box.

## Usage

### Docker Compose

```yaml
services:
  seanime:
    image: umagistr/seanime
    container_name: seanime
    volumes:
      - /mnt/user/anime:/anime
      - /mnt/user/downloads:/downloads
      - ./seanime-config:/root/.config/Seanime
    ports:
      - 3211:43211
    restart: always
```

## Configuration

### Ports

`3211` - Seanime web interface.

### Volumes

`/anime` - Downloads and media files are stored here.

`/seanime-config` - This is where the configuration files for Seanime are
located.

`downloads` - Torrent downloads dir
