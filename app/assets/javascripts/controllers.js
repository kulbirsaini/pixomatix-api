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

galleryControllers.controller('SlideshowNavigationCtrl', ['$scope', '$routeParams', '$location', '$timeout', 'Gallery', 'ImageService',
  function($scope, $routeParams, $location, $timeout, Gallery, ImageService){
    $scope.initializeData = function(){
      $scope.gallery_id = $routeParams.id;
      $scope.image_id = $routeParams.image_id;
      $scope.parent_id = null;
      $scope.currentIndex = -1;
      $scope.currentAngle = 0;
      $scope.images = [];
      $scope.quality = 'hdtv_path';
      $scope.circular = 'yes';
      $scope.animate = true;
      $scope.fadeOutTime = 300;
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

    $scope.getFirstIndex = function(){
      return 0;
    };

    $scope.getLastIndex = function(){
      return $scope.images.length - 1;
    };

    $scope.getNextIndex = function(){
      if ($scope.circular === "yes"){
        return ($scope.currentIndex === $scope.images.length - 1) ? 0 : $scope.currentIndex + 1;
      } else {
        return ($scope.currentIndex === $scope.images.length - 1) ? $scope.currentIndex : $scope.currentIndex + 1;
      }
    };

    $scope.getPreviousIndex = function(){
      if ($scope.circular === "yes"){
        return ($scope.currentIndex === 0) ? $scope.images.length - 1 : $scope.currentIndex - 1;
      } else {
        return ($scope.currentIndex === 0) ? $scope.currentIndex : $scope.currentIndex - 1;
      }
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

    $scope.getIndexByImageId = function(image_id){
      var index = null;
      angular.forEach($scope.images, function(value, key){
        if (value.id == image_id){ index = key; return; }
      });
      return index;
    };

    $scope.setIndexByImageId = function(image_id){
      var index = $scope.getIndexByImageId(image_id);
      $timeout(function(){ $scope.currentIndex = index; $scope.animate = true; }, 1);
    };

    $scope.appendToImages = function(images){
      ImageService.setValue('images', images);
      $scope.images = images;
      $scope.setIndexByImageId($scope.image_id);
    };

    $scope.redirectToParentGallery = function(){
      ImageService.resetData();
      $location.path('/images/' + $scope.parent_id);
    };

    $scope.goToImage = function(id){
      $scope.animate = false;
      $timeout(function(){ $location.path('/images/' + $scope.gallery_id + '/slideshow/' + id); }, $scope.fadeOutTime);
    };

    $scope.goToFirstImage = function(){
      $scope.goToImage($scope.getFirstImage().id);
    };

    $scope.goToLastImage = function(){
      $scope.goToImage($scope.getLastImage().id);
    };

    $scope.goToPreviousImage = function(){
      $scope.goToImage($scope.getPreviousImage().id);
    };

    $scope.goToNextImage = function(){
      $scope.goToImage($scope.getNextImage().id);
    };

    $scope.isFirstButtonDisabled = function(){
      return $scope.circular == "no" && $scope.getFirstIndex() == $scope.currentIndex;
    };

    $scope.isPreviousButtonDisabled = function(){
      return $scope.circular == "no" && $scope.getPreviousIndex() == $scope.currentIndex;
    };

    $scope.isNextButtonDisabled = function(){
      return $scope.circular == "no" && $scope.getNextIndex() == $scope.currentIndex;
    };

    $scope.isLastButtonDisabled = function(){
      return $scope.circular == "no" && $scope.getLastIndex() == $scope.currentIndex;
    };

    //Handle Keypress
    $scope.$on('key.escape', function(event){ $scope.redirectToParentGallery(); });
    $scope.$on('key.up', function(event){ $scope.goToFirstImage(); });
    $scope.$on('key.left', function(event){ $scope.goToPreviousImage(); });
    $scope.$on('key.right', function(event){ $scope.goToNextImage(); });
    $scope.$on('key.down', function(event){ $scope.goToLastImage(); });
    $scope.$watch("currentAngle", function(value){ $scope.transformStyle = "rotate(" + $scope.currentAngle + "deg)"; });
    $scope.$watch("currentIndex", function(value){ $scope.currentAngle = 0; });
    $scope.$watch("circular", function(value){ ImageService.setValue('circular', value); });
    $scope.$watch("quality", function(value){ ImageService.setValue('quality', value); });

    $scope.initializeData();
    if (typeof(ImageService.getValue('images')) === "undefined"){
      console.log("Fetching!");
      Gallery.getObject({ operation: 'parent', id: $scope.gallery_id }, function(data){ $scope.parent_id = data.parent_id; ImageService.setValue('parent_id', data.parent_id); });
      Gallery.getCollection({ operation: 'images', id: $scope.gallery_id }, $scope.appendToImages)
      ImageService.setValue('quality', $scope.quality);
      ImageService.setValue('circular', $scope.circular);
    } else {
      console.log("Cached!");
      $scope.parent_id = ImageService.getValue('parent_id');
      $scope.images = ImageService.getValue('images');
      $scope.setIndexByImageId($scope.image_id);
      $scope.circular = ImageService.getValue('circular');
      $scope.quality = ImageService.getValue('quality');
    }
  }
]);
