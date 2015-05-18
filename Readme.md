## Pixomatix-Api

[Pixomatix-Api](https://github.com/kulbirsaini/pixomatix-api) is a Photo Gallery API powered by [Ruby on Rails](http://rubyonrails.org/) (4.2.1). It supports recursive scanning, thumbnail generation and resizing images to fit HDTV screens.

**Demo** : [api.pixomatix.com](http://api.pixomatix.com/)

## Front End Implementations

- AngularJS : [Pixomatix-Angular](https://github.com/kulbirsaini/pixomatix-angular) ([Demo](http://angular.pixomatix.com/))


## Configuration

### App Configuration

Config File : `config/pixomatix.yml`

```ruby
default: &default
  thumbnail_width: 200
  thumbnail_height: 200
  hdtv_height: 1080
  image_cache_dir: 'public/cache/' # relative path inside Rails.root
  image_prefix: 'KSC' # Used for renaming images if opted
  thumbnail_path_regex: !ruby/regexp /(^[0-9]+)_([0-9]+)x([0-9]+)\.([a-z0-9]+)/i
  hdtv_path_regex: !ruby/regexp /(^[0-9]+)_([0-9]+)\.([a-z0-9]+)/i
  use_aws: false # If AWS is to be used for images

development:
  <<: *default
  image_root: ['/path/to/your/pics/dir/', '/vacation/pics/'] # Can be multiple directories with sub-directories
  use_aws: false

test:
  <<: *default
  image_root: []

stage:
  <<: *default
  image_root: []

production:
  <<: *default
  image_root: []
```

### AWS Configuration

Config File: `config/aws.yml`

```ruby
default: &default
  access_key_id: 'AWS S3 Access Key'
  secret_access_key: 'AWS S3 Secret'
  region: 'S3 Region code from http://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region'
  s3_bucket: 'AWS S3 Bucket Name'

development:
  <<: *default

test:
  <<: *default

stage:
  <<: *default

production:
  <<: *default
```

## Rake Tasks

#### Rename Images

**WARNING**: Make sure you have a backup of your images before doing this. There is absolutely no guarantee it'll work as expected. 

Running this task is completely optional.

You can rename images in a directory in a continuous sequence with filesnames like `PREFIX_YYYYMMDD_HHMMSS_NNNN.jpg` where `NNNN` is zero padded sequence, time is taken from Image's EXIF data and `PREFIX` is as set in `config/pixomatix.yml`.

```ruby
rake pixomatix:rename_images
```

#### Populate Images

Recursively scan `image_root` directories specified in `config/pixomatix.yml` and populate database.

```ruby
rake pixomatix:populate_images
```

#### Generate Thumbnails

Generate thumbnails for all the populated images as per the specifications mentioned in `config/pixomatix.yml`. It won't generate thumbnails which exist already.

```ruby
rake pixomatix:generate_thumbnails
```

#### Generate HDTV Images

Generate HDTV images by scaling images (preserving aspect ratio) as per HDTV heing mentioned in `config/pixomatix.yml`. It'll also skip images which already have generated HDTV images.

```ruby
rake pixomatix:generate_hdtv_images
```

#### Optimize Cache

Reclaim disk space by removing thumbnails/HDTV images which are no longer required.

```ruby
rake pixomatix:optimize_cache
```

#### Sync Thumbnails To AWS S3

Sync generated thumbnails to AWS S3

```ruby
rake pixomatix:sync_thumbnails
```

#### Sync HDTV Images To AWS S3

Sync generated HDTV images to AWS S3

```ruby
rake pixomatix:sync_hdtv_images
```

#### Sync Everything To AWS S3

This is basically a combined task for above mentioned two AWS S3 sync tasks. It'll sync thumbnails and HDTV images to AWS S3.

```ruby
rake pixomatix:aws_sync
```

## API

**URL** : http://demo/pixomatix.com/api/

**Current Version** : v1


## API Endpoints

* `/api/images.json` => Array of gallery objects

```javascript
  [
    { "id":28aa708183ae9d042e3231df5d02b7ee,
      "caption":"AllPictures",
      "vertical":false,
      "is_image":false,
      "is_gallery":true,
      "has_galleries":true,
      "has_images":false,
      "has_parent":false,
      "thumbnail_path":"/images/28aa708183ae9d042e3231df5d02b7ee/thumbnail"
    },
    ...
  ]
```

* `/api/images/:id.json` => Gallery Object

```javascript
  { "id":28aa708183ae9d042e3231df5d02b7ee,
    "caption":"Paris, France",
    "vertical":false,
    "is_image":false,
    "is_gallery":true,
    "has_galleries":false,
    "has_images":true,
    "has_parent":true,
    "parent_id":28aa708183ae9d042e3231df5d02b7ee,
    "thumbnail_path":"/images/28aa708183ae9d042e3231df5d02b7ee/thumbnail"
  }
```

* `/api/images/:id/images.json` => Array of image objects in a gallery

```javascript
  [
    { "id":28aa708183ae9d042e3231df5d02b7ee,
      "caption":null,
      "vertical":false,
      "is_image":true,
      "is_gallery":false,
      "has_galleries":false,
      "has_images":false,
      "has_parent":true,
      "parent_id":"28aa708183ae9d042e3231df5d02b7ee",
      "thumbnail_path":"/images/28aa708183ae9d042e3231df5d02b7ee/thumbnail",
      "hdtv_path":"/images/28aa708183ae9d042e3231df5d02b7ee/hdtv",
      "original_path":"/images/28aa708183ae9d042e3231df5d02b7ee/original"
    },
    ...
  ]
```

* `/api/images/:id/galleries.json` => Array of gallery objects in a gallery

```javascript
  [
    { "id":"28aa708183ae9d042e3231df5d02b7ee",
      "caption":"Paris, France",
      "vertical":false,
      "is_image":false,
      "is_gallery":true,
      "has_galleries":false,
      "has_images":true,
      "has_parent":true,
      "parent_id":"28aa708183ae9d042e3231df5d02b7ee",
      "thumbnail_path":"/images/2/thumbnail"
    },
    ...
  ]
```

* `/api/images/:id/image.json` => First image id in a gallery if present

```javascript
  {
    "id":null
  }
```

OR 

```javascript
  {
    "id":"28aa708183ae9d042e3231df5d02b7ee"
  }
```

* `/api/images/:id/parent.json` => Parent id which has galleries (may be parent of parent and so on)

```javascript
  {
    "parent_id":"28aa708183ae9d042e3231df5d02b7ee"
  }
```

## About Me
Senior Developer / Programmer,
Hyderabad, India

## Contact Me
Kulbir Saini - contact [AT] saini.co.in / [@_kulbir](https://twitter.com/_kulbir)

## License
Copyright (c) 2015 Kulbir Saini

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
