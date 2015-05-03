var galleryControllers = angular.module("galleryControllers", []);

galleryControllers.controller('GalleryCtrl', ['$scope', '$http', '$window', '$routeParams', '$filter', 'Gallery',
  function($scope, $http, $window, $routeParams, $filter, Gallery){
    $scope.initializeData = function(){
      $scope.galleries = [];
      $scope.images = [];
      $scope.parent_id = null;
      $scope.currentIndex = 0;
    };

    $scope.resetCurrentGallery = function(){
      $scope.images = [];
      $scope.currentIndex = 0;
    };

    $scope.loadImagesForGallery = function(id){
      $scope.resetCurrentGallery();
      Gallery.getCollection({operation: 'images', id: id }, $scope.appendToImages);
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

    $scope.filterEmptyGalleries = function(galleries){
      return $filter('filter')(galleries, function(item){ return item.has_galleries || item.has_images; });
    };

    $scope.appendToGalleries = function(galleries){
      galleries = $scope.filterEmptyGalleries(galleries);
      console.log('Galleries: ', galleries);
      $scope.galleries = $scope.galleries.concat(galleries);
    };

    $scope.appendToImages = function(images){
      console.log('Images: ', images);
      $scope.images = $scope.images.concat(images);
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

    $scope.$on('keydown', function(msg, code){
      if (code == 38){ $scope.firstImage(); $scope.$apply(); }
      if (code == 37){ $scope.previousImage(); $scope.$apply(); }
      if (code == 39){ $scope.nextImage(); $scope.$apply(); }
      if (code == 40){ $scope.lastImage(); $scope.$apply(); }
    });

    $scope.initializeData();
    if (typeof($routeParams.id) == "undefined"){
      Gallery.query($scope.handleData);
    } else {
      Gallery.get({id: $routeParams.id}, $scope.handleData);
    }
  }
]);
