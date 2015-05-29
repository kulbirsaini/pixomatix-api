## Pixomatix-Api

[Pixomatix-Api](https://github.com/kulbirsaini/pixomatix-api) is a Photo Gallery API powered by [Ruby on Rails](http://rubyonrails.org/) (4.2.1). It supports recursive scanning, thumbnail generation and resizing images to fit HDTV screens.

**Demo** : [api.pixomatix.com](http://api.pixomatix.com/)

## Front End Implementations

- AngularJS : [Pixomatix-Angular](https://github.com/kulbirsaini/pixomatix-angular) ([Demo](http://angular.pixomatix.com/))


## <a name="contents"></a>Contents

* [Configuration](#configuration)
  * [App Configuration](#app_configuration)
  * [AWS Configuration](#aws_configuration)
* [Rake Tasks](#rake_tasks)
* [API](#api)
  * [API Guidelines](#api_guidelines)
  * [API Endpoints](#api_endpoints)
    * [Authentication](#api_authentication)
    * [Images](#api_images)
* [Credits](#credits)
* [About Me](#about_me)
* [License](#license)



## <a name="configuration"></a>Configuration [&uarr;](#contents)

### <a name="app_configuration"></a>App Configuration [&uarr;](#contents)

Config File : `config/pixomatix.yml`

```ruby
default: &default
  thumbnail_width: 200
  thumbnail_height: 200
  hdtv_height: 1080
  image_cache_dir: 'public/cache/' # relative path inside Rails.root
  image_prefix: 'KSC' # Image name prefix used for renaming images if opted
  thumbnail_path_regex: !ruby/regexp /(^[0-9]+)_([0-9]+)x([0-9]+)\.([a-z0-9]+)/i
  hdtv_path_regex: !ruby/regexp /(^[0-9]+)_([0-9]+)\.([a-z0-9]+)/i
  use_aws: false # If AWS is to be used for images. See config/aws.yml for configuration.

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

### <a name="aws_configuration"></a>AWS Configuration [&uarr;](#contents)

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

## <a name="rake_tasks"></a>Rake Tasks [&uarr;](#contents)

###### Rename Images

**WARNING**: Make sure you have a backup of your images before doing this. There is absolutely no guarantee it'll work as expected.

Running this task is completely optional.

You can rename images in a directory in a continuous sequence with filesnames like `PREFIX_YYYYMMDD_HHMMSS_NNNN.jpg` where `NNNN` is zero padded sequence, time is taken from Image's EXIF data and `PREFIX` is as set in `config/pixomatix.yml`.

```ruby
rake pixomatix:rename_images
```

###### Populate Images

Recursively scan `image_root` directories specified in `config/pixomatix.yml` and populate database.

```ruby
rake pixomatix:populate_images
```

###### Generate Thumbnails

Generate thumbnails for all the populated images as per the specifications mentioned in `config/pixomatix.yml`. It won't generate thumbnails which exist already.

```ruby
rake pixomatix:generate_thumbnails
```

###### Generate HDTV Images

Generate HDTV images by scaling images (preserving aspect ratio) as per HDTV height mentioned in `config/pixomatix.yml`. It'll also skip images which already have generated HDTV images.

```ruby
rake pixomatix:generate_hdtv_images
```

###### Optimize Cache

Reclaim disk space by removing thumbnails/HDTV images which are no longer required.

```ruby
rake pixomatix:optimize_cache
```

###### Sync Thumbnails To AWS S3

Sync generated thumbnails to AWS S3

```ruby
rake pixomatix:sync_thumbnails
```

###### Sync HDTV Images To AWS S3

Sync generated HDTV images to AWS S3

```ruby
rake pixomatix:sync_hdtv_images
```

###### Sync Everything To AWS S3

This is basically a combined task for above mentioned two AWS S3 sync tasks. It'll sync thumbnails and HDTV images to AWS S3.

```ruby
rake pixomatix:aws_sync
```

## <a name="api"></a>API [&uarr;](#contents)

API URL : [http://api.pixomatix.com/](http://api.pixomatix.com/)

API Version : v1 (default)


### <a name="api_guidelines"></a>General Guidelines for API Usage [&uarr;](#contents)

Response format is always `JSON` whether you specify it or not. Following fields should not be passed via GET/POST parameters and must be passed on via HTTP headers only.

* API version using HTTP header as `Accept: application/vnd.pixomatix.v1`.
* Authentication token as `X-Access-Token: 3086ed853a7336bc33c29e0dd674535c`.
* User email as `X-Access-Email: test@example.com`. Can be passed as POST parameters only when registering a new user.
* Locale as `Accept-Language: en-US`.
* Reset password token as `X-Access-Reset-Password-Token: 3086ed853a7336bc33c29e0dd674535c`.
* Unlock token as `X-Access-Unlock-Token: 3086ed853a7336bc33c29e0dd674535c`.
* Confirmation token as `X-Access-Confirmation-Token: 3086ed853a7336bc33c29e0dd674535c`.
* Response format as `Content-Type: application/json`.


## <a name="api_endpoints"></a>API Endpoints [&uarr;](#contents)

#### <a name="api_authentication"></a>Authentication [&uarr;](#contents)

- **[`POST /api/auth/register`](#auth_register)**
- **[`POST /api/auth/login`](#auth_login)**
- **[`GET /api/auth/user`](#auth_user)**
- **[`GET /api/auth/validate`](#auth_validate)**
- **[`DELETE /api/auth/logout`](#auth_logout)**
- **[`GET /api/auth/reset_password`](#auth_reset_password_instructions)**
- **[`POST /api/auth/reset_password`](#auth_reset_password)**
- **[`GET /api/auth/unlock`](#auth_unlock_instructions)**
- **[`POST /api/auth/unlock`](#auth_unlock)**
- **[`GET /api/auth/confirm`](#auth_confirmation_instructions)**
- **[`POST /api/auth/confirm`](#auth_confirm)**
- **[`PUT /api/users`](#users_update)**
- **[`PATCH /api/users`](#users_update)**
- **[`DELETE /api/users`](#users_cancel)**

#### <a name="api_images"></a>Images [&uarr;](#contents)

- **[`GET /api/galleries`](#images_index)**
- **[`GET /api/galleries/:id`](#images_show)**
- **[`GET /api/galleries/:id/photos`](#images_photos)**
- **[`GET /api/galleries/:id/galleries`](#images_galleries)**
- **[`GET /api/galleries/:id/photo`](#images_photo)**
- **[`GET /api/galleries/:id/parent`](#images_parent)**

## Authentication API [&uarr;](#contents)

#### <a name="auth_register"></a>Register a new user : `POST /api/auth/register` [&uarr; API](#api_endpoints)


###### Request

```javascript
curl -H 'Accept: application/vnd.pixomatix.v1' \
     -H 'Content-Type: application/json' \
     -H 'Accept-Language: en-US' \
     -w '\nResponse Code: %{http_code}\n' \
     -d '{"user":{"email":"test@example.com","password":"1234568","password_confirmation":"1234568","name":"Kulbir Saini"}}' \
     -X POST http://api.pixomatix.com/api/auth/register
```

###### Response when registered successfully

```javascript
{"user":{"name":"Kulbir Saini","email":"test@example.com"},"notice":"User registered successfully"}
Response Code: 200
```

###### Response when registered already but not confimred yet

```javascript
{"notice":"User already registered but not confirmed. Check your email to confirm account"}
Response Code: 401
```

###### Otherwise

```javascript
{"error":["Password confirmation doesn't match Password", ...],"notice":"User registration failed"}
Response Code: 422
```


#### <a name="auth_login"></a>Login : `POST /api/auth/login` [&uarr; API](#api_endpoints)


###### Request

```javascript
curl -H 'Accept: application/vnd.pixomatix.v1' \
     -H 'Content-Type: application/json' \
     -H 'Accept-Language: en-US' \
     -w '\nResponse Code: %{http_code}\n' \
     -d '{"user":{"email":"test@example.com","password":"1234568"}}' \
     -X POST http://api.pixomatix.com/api/auth/login
```

###### Response when user is locked

```javascript
{"notice":"User account is locked","location":"/api/auth/unlock"}
Response Code: 401
```

###### Response when user not confirmed

```javascript
{"notice":"User account is not confimred. Please check confirmation email for instructions","location":"/api/auth/login"}
Response Code: 401
```

###### Response when invalid email or password

```javascript
{"notice":"Invalid email or password"}
Response Code: 401
```

###### Response when login successful

```javascript
{"user":{"name":"Kulbir Saini","email":"test@example.com"},"token":"5a0dd200dccc9a87f83fcad30e1ae78b","notice":"Logged in successfully"}
Response Code: 200
```


#### <a name="auth_user"></a>Get current user : `GET /api/auth/user` [&uarr; API](#api_endpoints)

###### Request

```javascript
curl -H 'Accept: application/vnd.pixomatix.v1' \
     -H 'Content-Type: application/json' \
     -H 'Accept-Language: en-US' \
     -H 'X-Access-Token: 5a0dd200dccc9a87f83fcad30e1ae78b' \
     -H 'X-Access-Email: test@example.com' \
     -w '\nResponse Code: %{http_code}\n' \
     -X GET http://api.pixomatix.com/api/auth/user
```


#### <a name="auth_validate"></a>Validate authentication token : `GET /api/auth/validate` [&uarr; API](#api_endpoints)


###### Request

```javascript
curl -H 'Accept: application/vnd.pixomatix.v1' \
     -H 'Content-Type: application/json' \
     -H 'Accept-Language: en-US' \
     -H 'X-Access-Token: 5a0dd200dccc9a87f83fcad30e1ae78b' \
     -H 'X-Access-Email: test@example.com' \
     -w '\nResponse Code: %{http_code}\n' \
     -X GET http://api.pixomatix.com/api/auth/validate
```


#### <a name="auth_logout"></a>Logout user : `DELETE /api/auth/logout` [&uarr; API](#api_endpoints)


###### Request

```javascript
curl -H 'Accept: application/vnd.pixomatix.v1' \
     -H 'Content-Type: application/json' \
     -H 'Accept-Language: en-US' \
     -H 'X-Access-Token: 5a0dd200dccc9a87f83fcad30e1ae78b' \
     -H 'X-Access-Email: test@example.com' \
     -w '\nResponse Code: %{http_code}\n' \
     -X DELETE http://api.pixomatix.com/api/auth/logout
```


#### <a name="auth_reset_password_instructions"></a>Get reset password instructions : `GET /api/auth/reset_password` [&uarr; API](#api_endpoints)


###### Request

```javascript
curl -H 'Accept: application/vnd.pixomatix.v1' \
     -H 'Content-Type: application/json' \
     -H 'Accept-Language: en-US' \
     -H 'X-Access-Email: test@example.com' \
     -w '\nResponse Code: %{http_code}\n' \
     -X GET http://api.pixomatix.com/api/auth/reset_password
```


#### <a name="auth_reset_password"></a>Reset password using issued token : `POST /api/auth/reset_password` [&uarr; API](#api_endpoints)


###### Request

```javascript
curl -H 'Accept: application/vnd.pixomatix.v1' \
     -H 'Content-Type: application/json' \
     -H 'Accept-Language: en-US' \
     -H 'X-Access-Email: test@example.com' \
     -H 'X-Access-Reset-Password-Token: 31b4aa71ea72c8ae3d9a37245e8569f1' \
     -w '\nResponse Code: %{http_code}\n' \
     -d '{"user":{"password":"1234568","password_confirmation":"1234568"}}' \
     -X POST http://api.pixomatix.com/api/auth/reset_password
```


#### <a name="auth_unlock_instructions"></a>Get unlock instructions : `GET /api/auth/unlock` [&uarr; API](#api_endpoints)


###### Request

```javascript
curl -H 'Accept: application/vnd.pixomatix.v1' \
     -H 'Content-Type: application/json' \
     -H 'Accept-Language: en-US' \
     -H 'X-Access-Email: test@example.com' \
     -w '\nResponse Code: %{http_code}\n' \
     -X GET http://api.pixomatix.com/api/auth/unlock
```


#### <a name="auth_unlock"></a>Unlock user using issued token : `POST /api/auth/unlock` [&uarr; API](#api_endpoints)


###### Request

```javascript
curl -H 'Accept: application/vnd.pixomatix.v1' \
     -H 'Content-Type: application/json' \
     -H 'Accept-Language: en-US' \
     -H 'X-Access-Email: test@example.com' \
     -H 'X-Access-Unlock-Token: 14fa864af566d03e7a35ef6c6e1e4bcf' \
     -w '\nResponse Code: %{http_code}\n' \
     -X POST http://api.pixomatix.com/api/auth/unlock
```


#### <a name="auth_confirmation_instructions"></a>Get confirmation instructions : `GET /api/auth/confirm` [&uarr; API](#api_endpoints)


###### Request

```javascript
curl -H 'Accept: application/vnd.pixomatix.v1' \
     -H 'Content-Type: application/json' \
     -H 'Accept-Language: en-US' \
     -H 'X-Access-Email: test@example.com' \
     -w '\nResponse Code: %{http_code}\n' \
     -X GET http://api.pixomatix.com/api/auth/confirm
```


#### <a name="auth_confirm"></a>Confirm account using issued token : `POST /api/auth/confirm` [&uarr; API](#api_endpoints)


###### Request

```javascript
curl -H 'Accept: application/vnd.pixomatix.v1' \
     -H 'Content-Type: application/json' \
     -H 'Accept-Language: en-US' \
     -H 'X-Access-Email: test@example.com' \
     -H 'X-Access-Confirmation-Token: f5884aec88d513c2b3b2ef16b41210b8' \
     -w '\nResponse Code: %{http_code}\n' \
     -X POST http://api.pixomatix.com/api/auth/confirm
```


#### <a name="users_update"></a>Update user data : `PUT /api/users` OR `PATCH /api/users` [&uarr; API](#api_endpoints)

**WARNING:** Email can not be updated.


###### Request

```javascript
curl -H 'Accept: application/vnd.pixomatix.v1' \
     -H 'Content-Type: application/json' \
     -H 'Accept-Language: en-US' \
     -H 'X-Access-Email: test@example.com' \
     -H 'X-Access-Token: a4c4e6734f5050e6460ed91c608fc147' \
     -w '\nResponse Code: %{http_code}\n' \
     -d '{"user":{"password":"1234568","password_confirmation":"1234568","name":"Yo Test!"}}' \
     -X PUT http://api.pixomatix.com/api/users
```


#### <a name="users_cancel"></a>Cancel registration : `DELETE /api/users` [&uarr; API](#api_endpoints)


###### Request

```javascript
curl -H 'Accept: application/vnd.pixomatix.v1' \
     -H 'Content-Type: application/json' \
     -H 'Accept-Language: en-US' \
     -H 'X-Access-Email: test@example.com' \
     -H 'X-Access-Token: ff7c0ee84d6b08c2edfd1938776865cc' \
     -w '\nResponse Code: %{http_code}\n' \
     -X DELETE http://api.pixomatix.com/api/users
```


## Images API

#### <a name="images_index"></a>Array of gallery objects : `GET /api/galleries` [&uarr; API](#api_endpoints)

###### Request

```javascript
curl -H 'Accept: application/vnd.pixomatix.v1' \
     -H 'Content-Type: application/json' \
     -H 'Accept-Language: en-US' \
     -w '\nResponse Code: %{http_code}\n' \
     -X GET http://api.pixomatix.com/api/galleries
```

###### Response

```javascript
  [
    {
      "id":"3086ed853a7336bc",
      "caption":"All Pictures",
      "vertical":false,
      "is_photo":false,
      "is_gallery":true,
      "has_galleries":true,
      "has_photos":false,
      "has_parent":false,
      "thumbnail_url":"http://api.pixomatix.com/cache/ccdce535cf8cfdfd/f9882cb22f0453fc_200x200.jpg"
    },
    ...
  ]
  Response Code: 200
```

#### <a name="images_show"></a>Gallery Object : `GET /api/galleries/:id` [&uarr; API](#api_endpoints)

###### Request

```javascript
curl -H 'Accept: application/vnd.pixomatix.v1' \
     -H 'Content-Type: application/json' \
     -H 'Accept-Language: en-US' \
     -w '\nResponse Code: %{http_code}\n' \
     -X GET http://api.pixomatix.com/api/galleries/3086ed853a7336bc
```

###### Response

```javascript
  {
    "id":"3086ed853a7336bc",
    "caption":"All Pictures",
    "vertical":false,
    "is_photo":false,
    "is_gallery":true,
    "has_galleries":true,
    "has_photos":false,
    "has_parent":false,
    "thumbnail_url":"http://api.pixomatix.com/cache/ccdce535cf8cfdfd/f2e992a6cc8b8576_200x200.jpg"
  }
  Response Code: 200
```

#### <a name="images_photos"></a>Array of image objects in a gallery : `GET /api/galleries/:id/photos` [&uarr; API](#api_endpoints)

###### Request

```javascript
curl -H 'Accept: application/vnd.pixomatix.v1' \
     -H 'Content-Type: application/json' \
     -H 'Accept-Language: en-US' \
     -w '\nResponse Code: %{http_code}\n' \
     -X GET http://api.pixomatix.com/api/galleries/1d0946693f029960/photos
```

###### Response

```javascript
  [
    {
      "id":"c256005c010b3996",
      "caption":null,
      "vertical":true,
      "is_photo":true,
      "is_gallery":false,
      "has_galleries":false,
      "has_photos":false,
      "has_parent":true,
      "parent_id":"1d0946693f029960",
      "thumbnail_url":"http://api.pixomatix.com/cache/1d0946693f029960/c256005c010b3996_200x200.jpg",
      "hdtv_url":"http://api.pixomatix.com/cache/1d0946693f029960/c256005c010b3996_1080.jpg",
      "original_url":"http://api.pixomatix.com/images/c256005c010b3996/original",
      "download_url":"http://api.pixomatix.com/images/c256005c010b3996/download"
    },
    ...
  ]
  Response Code: 200
```

#### <a name="images_galleries"></a>Array of gallery objects in a gallery : `GET /api/galleries/:id/galleries` [&uarr; API](#api_endpoints)

###### Request

```javascript
curl -H 'Accept: application/vnd.pixomatix.v1' \
     -H 'Content-Type: application/json' \
     -H 'Accept-Language: en-US' \
     -w '\nResponse Code: %{http_code}\n' \
     -X GET http://api.pixomatix.com/api/galleries/3086ed853a7336bc/galleries
```

###### Response

```javascript
  [
    {
      "id":"ccdce535cf8cfdfd",
      "caption":"Mc D, Hyderabad Central",
      "vertical":false,
      "is_photo":false,
      "is_gallery":true,
      "has_galleries":false,
      "has_photos":true,
      "has_parent":true,
      "parent_id":"3086ed853a7336bc",
      "thumbnail_url":"http://api.pixomatix.com/cache/ccdce535cf8cfdfd/4807869cde3ab130_200x200.jpg"
    },
    ...
  ]
  Response Code: 200
```

#### <a name="images_photo"></a>First photo id in a gallery if present : `GET /api/galleries/:id/photo` [&uarr; API](#api_endpoints)

###### Request

```javascript
curl -H 'Accept: application/vnd.pixomatix.v1' \
     -H 'Content-Type: application/json' \
     -H 'Accept-Language: en-US' \
     -w '\nResponse Code: %{http_code}\n' \
     -X GET http://api.pixomatix.com/api/galleries/ccdce535cf8cfdfd/photo
```

###### Response

```javascript
  {
    "id":null
  }
  Response Code: 200
```

OR

```javascript
  {
    "id":"5cf976e90781546b"
  }
  Response Code: 200
```

#### <a name="images_parent"></a>Parent id which has galleries (may be parent of parent and so on) : `GET /api/galleries/:id/parent` [&uarr; API](#api_endpoints)

###### Request

```javascript
curl -H 'Accept: application/vnd.pixomatix.v1' \
     -H 'Content-Type: application/json' \
     -H 'Accept-Language: en-US' \
     -w '\nResponse Code: %{http_code}\n' \
     -X GET http://api.pixomatix.com/api/galleries/ccdce535cf8cfdfd/parent
```

###### Response


```javascript
  {
    "parent_id":"3086ed853a7336bc"
  }
  Response Code: 200
```


## <a name="credits"></a>Credits [&uarr;](#contents)

- Code for API constraints - [RADD](https://github.com/jesalg/RADD)



## <a name="about_me"></a>About Me [&uarr;](#contents)
[Kulbir Saini](http://saini.co.in/),
Senior Developer / Programmer,
Hyderabad, India

## Contact Me
Kulbir Saini - contact [AT] saini.co.in / [@_kulbir](https://twitter.com/_kulbir)

## <a name="license"></a>License [&uarr;](#contents)
Copyright (c) 2015 Kulbir Saini

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
