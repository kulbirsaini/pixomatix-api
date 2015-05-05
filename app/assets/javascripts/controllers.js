var galleryControllers = angular.module("galleryControllers", []);

galleryControllers.controller('GalleryCtrl', ['$scope', '$routeParams', '$filter', 'Gallery',
  function($scope, $routeParams, $filter, Gallery){
    $scope.initializeData = function(){
      $scope.galleries = [];
      $scope.parent_id = null;
    };

    $scope.filterEmptyGalleries = function(galleries){
      return $filter('filter')(galleries, function(item){ return item.has_galleries || item.has_images; });
    };

    $scope.appendToGalleries = function(galleries){
      galleries = $scope.filterEmptyGalleries(galleries);
      $scope.galleries = $scope.galleries.concat(galleries);
    };

    $scope.handleData = function(data){
      console.log('id: ', $routeParams.id, ' data: ', data, ' constructor: ', data.constructor === Array);
      $scope.initializeData();
      if (data.constructor === Array){
        $scope.appendToGalleries(data);
      } else {
        $scope.parent_id = data.parent_id;
        if (data.has_galleries){
          Gallery.getCollection({operation: 'galleries', id: data.id}, $scope.appendToGalleries);
        }
        if (data.has_images){
          $scope.galleries = $scope.galleries.concat({id:data.id,is_image:false,is_gallery:true,has_galleries:false,has_images:true,has_parent:true,parent_id:data.id,thumbnail_path:data.thumbnail_path});
        }
      }
    };

    $scope.initializeData();
    if (typeof($routeParams.id) == "undefined"){
      Gallery.query($scope.handleData);
    } else {
      Gallery.get({id: $routeParams.id}, $scope.handleData);
    }
  }
]);

galleryControllers.controller('SlideshowCtrl', ['$scope', '$routeParams', '$location', 'Gallery',
  function($scope, $routeParams, $location, Gallery){
    if (typeof($routeParams.image_id) == "undefined"){
      Gallery.getObject({ operation: 'image', id: $routeParams.id }, function(data){
        $location.path('/images/' + $routeParams.id + '/slideshow/' + data.id);
      });
    }
  }
]);

galleryControllers.controller('SlideshowNavigationCtrl', ['$scope', '$routeParams', '$location', 'Gallery', 'ImageService',
  function($scope, $routeParams, $location, Gallery, ImageService){
    $scope.initializeData = function(){
      $scope.gallery_id = $routeParams.id;
      $scope.image_id = $routeParams.image_id;
      $scope.parent_id = null;
      $scope.currentIndex = 0;
      $scope.currentAngle = 0;
      $scope.images = [];
      $scope.quality = 'hdtv_path';
    };

    $scope.rotateClockwise = function(){
      $scope.currentAngle = ($scope.currentAngle + 90) % 360;
    };

    $scope.rotateAntiClockwise = function(){
      $scope.currentAngle = ($scope.currentAngle - 90) % 360;
    };

    $scope.isOddAngleRotation = function(){
      return ($scope.currentAngle / 90) % 2 !== 0;
    };

    $scope.getNextIndex = function(){
      return ($scope.currentIndex === $scope.images.length - 1) ? $scope.currentIndex : $scope.currentIndex + 1;
    };

    $scope.getPreviousIndex = function(){
      return ($scope.currentIndex === 0) ? $scope.currentIndex : $scope.currentIndex - 1;
    };

    $scope.getImageAtIndex = function(index){
      var image = $scope.images[index];
      return (typeof(image) == "undefined") ? null : image;
    };

    $scope.getCurrentImage = function(){
      return $scope.getImageAtIndex($scope.currentIndex);
    };

    $scope.nextImage = function(){
      $scope.currentIndex = $scope.getNextIndex();
    };

    $scope.getNextImage = function(){
      return $scope.getImageAtIndex($scope.getNextIndex());
    };

    $scope.previousImage = function(){
      $scope.currentIndex = $scope.getPreviousIndex();
    };

    $scope.getPreviousImage = function(){
      return $scope.getImageAtIndex($scope.getPreviousIndex());
    };

    $scope.firstImage = function(){
      $scope.currentIndex = 0;
    };

    $scope.getFirstImage = function(){
      return $scope.images[0];
    };

    $scope.lastImage = function(){
      $scope.currentIndex = $scope.images.length - 1;
    };

    $scope.getLastImage = function(){
      return $scope.getImageAtIndex($scope.images.length - 1);
    };

    $scope.setIndexByImageId = function(image_id){
      angular.forEach($scope.images, function(value, key){
        if (value.id == image_id){ $scope.currentIndex = key; return; }
      });
    };

    $scope.appendToImages = function(images){
      ImageService.setImages(images);
      $scope.images = images;
      $scope.setIndexByImageId($scope.image_id);
    };

    $scope.redirectToParentGallery = function(){
      ImageService.resetData();
      $location.path('/images/' + $scope.parent_id);
    };

    //Handle Keypress
    $scope.$on('key.escape', function(event){ $scope.redirectToParentGallery(); });
    $scope.$on('key.up', function(event){ $scope.firstImage(); });
    $scope.$on('key.left', function(event){ $scope.previousImage(); });
    $scope.$on('key.right', function(event){ $scope.nextImage(); });
    $scope.$on('key.down', function(event){ $scope.lastImage(); });
    $scope.$watch("currentAngle", function(value){ $scope.transformStyle = "rotate(" + $scope.currentAngle + "deg)"; });
    $scope.$watch("currentIndex", function(value){ $scope.currentAngle = 0; });

    $scope.initializeData();
    if (ImageService.getImages().length === 0){
      console.log("Fetching!");
      Gallery.getObject({ operation: 'parent', id: $scope.gallery_id }, function(data){ $scope.parent_id = data.parent_id; ImageService.setParentId(data.parent_id); });
      Gallery.getCollection({ operation: 'images', id: $scope.gallery_id }, $scope.appendToImages)
    } else {
      console.log("Cached!");
      $scope.parent_id = ImageService.getParentId();
      $scope.images = ImageService.getImages();
      $scope.setIndexByImageId($scope.image_id);
    }
  }
]);
