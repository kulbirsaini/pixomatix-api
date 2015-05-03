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
    $scope.initializeData = function(){
      $scope.images = [];
      $scope.parent_id = null;
      $scope.currentIndex = 0;
      $scope.currentAngle = 0;
    };

    $scope.resetCurrentGallery = function(){
      $scope.images = [];
      $scope.currentIndex = 0;
      $scope.currentAngle = 0;
    };

    $scope.loadImages = function(){
      $scope.resetCurrentGallery();
      Gallery.getCollection({operation: 'images', id: $routeParams.id }, $scope.appendToImages);
    };

    $scope.setParentId = function(){
      Gallery.getParentId({ operation: 'parent', id: $routeParams.id }, function(data){ $scope.parent_id = data.parent_id; });
    };

    $scope.rotateClockwise = function(){
      $scope.currentAngle = ($scope.currentAngle + 90) % 360;
    };

    $scope.rotateAntiClockwise = function(){
      $scope.currentAngle = ($scope.currentAngle - 90) % 360;
    };

    $scope.isOddAngleRotation = function(){
      return ($scope.currentAngle % 90) / 2 !== 0;
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

    $scope.previousImage = function(){
      $scope.currentIndex = $scope.getPreviousIndex();
    };

    $scope.firstImage = function(){
      $scope.currentIndex = 0;
    };

    $scope.lastImage = function(){
      $scope.currentIndex = $scope.images.length - 1;
    };

    $scope.appendToImages = function(images){
      $scope.images = $scope.images.concat(images);
    };

    //Handle Keypress
    $scope.$on('key.escape', function(event){ $location.path('/images/' + $scope.parent_id); });
    $scope.$on('key.up', function(event){ $scope.firstImage(); });
    $scope.$on('key.left', function(event){ $scope.previousImage(); });
    $scope.$on('key.right', function(event){ $scope.nextImage(); });
    $scope.$on('key.down', function(event){ $scope.lastImage(); });
    $scope.$watch("currentAngle", function(value){ $scope.transformStyle = "rotate(" + $scope.currentAngle + "deg)"; });
    $scope.$watch("currentIndex", function(value){ $scope.currentAngle = 0; });

    $scope.initializeData();
    $scope.loadImages();
    $scope.setParentId();
  }
]);
