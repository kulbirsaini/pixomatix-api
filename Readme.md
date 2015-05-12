## Pixomatix

Pixomatix is a Photo Gallery powered by [Ruby on Rails](http://rubyonrails.org/) (4.2.1) and [Angularjs](https://angularjs.org/) (1.3). It supports recursive scanning, thumbnail generation and resizing images to fit HDTV screens.

## Setup Instructions

1. Set `image_root` in `config/pixomatix.yml`.
2. Populate images using `rake` task `rake Pixomatix::ImageSync.new.populate_images`.
3. Generate thumbnails for all the images using task `rake Pixomatix::ImageSync.generate_thumbnails`.
4. Generate HDTV images using task `rake Pixomatix::ImageSync.generate_hdtv_images`

## API Endpoints

* `/images.json` => Array of gallery objects

```javascript
  [
    { "id":1,
      "caption":"AllPictures",
      "vertical":false,
      "is_image":false,
      "is_gallery":true,
      "has_galleries":true,
      "has_images":false,
      "has_parent":false,
      "thumbnail_path":"/images/1/thumbnail"
    },
    ...
  ]
```

* `/images/:id.json` => Gallery Object

```javascript
  { "id":2,
    "caption":"Paris, France",
    "vertical":false,
    "is_image":false,
    "is_gallery":true,
    "has_galleries":false,
    "has_images":true,
    "has_parent":true,
    "parent_id":1,
    "thumbnail_path":"/images/2/thumbnail"
  }
```

* `/images/:id/images.json` => Array of image objects in a gallery

```javascript
  [
    { "id":16345,
      "caption":null,
      "vertical":false,
      "is_image":true,
      "is_gallery":false,
      "has_galleries":false,
      "has_images":false,
      "has_parent":true,
      "parent_id":2,
      "thumbnail_path":"/images/16345/thumbnail",
      "hdtv_path":"/images/16345/hdtv",
      "original_path":"/images/16345/original"
    },
    ...
  ]
```

* `/images/:id/galleries.json` => Array of gallery objects in a gallery

```javascript
  [
    { "id":2,
      "caption":"Paris, France",
      "vertical":false,
      "is_image":false,
      "is_gallery":true,
      "has_galleries":false,
      "has_images":true,
      "has_parent":true,
      "parent_id":1,
      "thumbnail_path":"/images/2/thumbnail"
    },
    ...
  ]
```

* `/images/:id/image.json` => First image id in a gallery if present

```javascript
  {
    "id":null
  }
```

OR 

```javascript
  {
    "id":3
  }
```

* `/images/:id/parent.json` => Parent id which has galleries (may be parent of parent and so on)

```javascript
  {
    "parent_id":1
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
