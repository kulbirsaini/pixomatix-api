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

galleryControllers.controller('SlideshowCtrl', ['$scope', '$route', '$routeParams', '$location', '$timeout', 'Gallery', 'Settings',
  function($scope, $route, $routeParams, $location, $timeout, Gallery, Settings){
    $scope.initializeData = function(){
      $scope.gallery_id = $routeParams.id;
      $scope.image_id = $routeParams.image_id;
      $scope.parent_id = null;
      $scope.currentIndex = -1;
      $scope.currentAngle = 0;
      $scope.rotatedWidth = null;
      $scope.images = [];
      $scope.quality = 'hdtv_path';
      $scope.circular = 'yes';
      $scope.fadeOutTime = 300;
      $scope.leftOffset = '0px';
      $scope.lastRoute = $route.current;
      $scope.thumbnail_width = 105; //with margin/padding
      $scope.slide_height_padding = 150; //with margin/padding
    };

    $scope.getBodyWidth = function(){
      return jQuery(window).width();
    };

    $scope.getBodyHeight = function(){
      return jQuery(window).height();
    };

    $scope.setSlideHeightPadding = function(){
      if ($scope.getBodyWidth() < 992){
        $scope.slide_height_padding = 45;
      } else {
        $scope.slide_height_padding = 150;
      }
    };

    $scope.setRotatedWidth = function(){
      if ($scope.isOddAngleRotation()){
        $scope.rotatedWidth = ($scope.getBodyHeight() - $scope.slide_height_padding) + 'px';
      } else {
        $scope.rotatedWidth = null;
      }
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

    $scope.getIndexByImageId = function(image_id){
      var index = null;
      angular.forEach($scope.images, function(value, key){
        if (value.id == image_id){ index = key; return; }
      });
      return index;
    };

    $scope.setIndexByImageId = function(image_id){
      if (image_id === null){
        $scope.currentIndex = $scope.getFirstIndex();
        return;
      }
      var index = $scope.getIndexByImageId(image_id);
      if (index === null){
        $scope.currentIndex = $scope.getFirstIndex();
      } else {
        $scope.currentIndex = index;
      }
    };

    $scope.appendToImages = function(images){
      $scope.images = images;
      $scope.setIndexByImageId($scope.image_id);
      $scope.goToImageAtIndex($scope.currentIndex);
    };

    $scope.redirectToParentGallery = function(){
      $location.path('/images/' + $scope.parent_id);
    };

    $scope.goToImage = function(id){
      $scope.setIndexByImageId(id);
      $location.path('/images/' + $scope.gallery_id + '/slideshow/' + id);
    };

    $scope.goToImageAtIndex = function(index){
      var image = $scope.getImageAtIndex(index);
      if (image !== null && image.id !== null){
        $scope.goToImage(image.id);
      }
    };

    $scope.setLeftOffset = function(){
      var bodyWidth = $scope.getBodyWidth(), numThumbs = parseInt(bodyWidth / $scope.thumbnail_width);
      var maxLeft = 0, minLeft = bodyWidth / 2 - ($scope.images.length - numThumbs / 2) * $scope.thumbnail_width;
      var left = parseInt(bodyWidth / 2 - ($scope.currentIndex + 1) * $scope.thumbnail_width);
      if (minLeft >= 0){ minLeft = 0; }
      if (left > maxLeft) { left = maxLeft; }
      if (left < minLeft) { left = minLeft; }
      $scope.leftOffset = left + 'px';
    };

    $scope.getCurrentImage = function(){
      return $scope.getImageAtIndex($scope.currentIndex);
    };

    $scope.getNextImage = function(){
      return $scope.getImageAtIndex($scope.getNextIndex());
    };

    $scope.getPreviousImage = function(){
      return $scope.getImageAtIndex($scope.getPreviousIndex());
    };

    $scope.getFirstImage = function(){
      return $scope.getImageAtIndex($scope.getFirstIndex());
    };

    $scope.getLastImage = function(){
      return $scope.getImageAtIndex($scope.getLastIndex());
    };

    $scope.goToCurrentImage = function(){
      $scope.goToImageAtIndex($scope.currentIndex);
    };

    $scope.goToFirstImage = function(){
      $scope.goToImageAtIndex($scope.getFirstIndex());
    };

    $scope.goToLastImage = function(){
      $scope.goToImageAtIndex($scope.getLastIndex());
    };

    $scope.goToPreviousImage = function(){
      $scope.goToImageAtIndex($scope.getPreviousIndex());
    };

    $scope.goToNextImage = function(){
      $scope.goToImageAtIndex($scope.getNextIndex());
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

    // Watch variables
    $scope.$watch("currentAngle", function(value){
      $scope.transformStyle = "rotate(" + $scope.currentAngle + "deg)";
      $scope.setSlideHeightPadding();
      $scope.setRotatedWidth();
    });
    $scope.$watch("currentIndex", function(value){ $scope.currentAngle = 0; $scope.setLeftOffset(); });
    $scope.$watch("circular", function(value){ Settings.setValue('circular', value); });
    $scope.$watch("quality", function(value){ Settings.setValue('quality', value); });

    // Monitor window resize
    jQuery(window).on('resize.doResize', function(){
      $scope.$apply(function(){
        $scope.setSlideHeightPadding();
        $scope.setRotatedWidth();
        $scope.setLeftOffset();
      })
    });
    $scope.$on("$destroy", function(){ jQuery(window).off('resize.doResize'); });

    // Change URL without reloading controller
    $scope.$on("$locationChangeSuccess", function(event){ if ($route.current.$$route.controller == 'SlideshowCtrl'){ $route.current = $scope.lastRoute; } });

    $scope.initializeData();
    Gallery.getObject({ operation: 'parent', id: $scope.gallery_id }, function(data){ $scope.parent_id = data.parent_id; });
    Gallery.getCollection({ operation: 'images', id: $scope.gallery_id }, $scope.appendToImages)
    if (typeof(Settings.getValue('quality')) !== "undefined"){
      $scope.circular = Settings.getValue('circular');
      $scope.quality = Settings.getValue('quality');
    }
  }
]);
