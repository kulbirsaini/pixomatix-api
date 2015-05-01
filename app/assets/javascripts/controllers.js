var galleryControllers = angular.module("galleryControllers", []);

galleryControllers.controller('GalleryCtrl', ['$scope', '$http', '$window', '$routeParams', '$filter', 'Gallery',
  function($scope, $http, $window, $routeParams, $filter, Gallery){
    $scope.initializeData = function(){
      $scope.galleries = [];
      $scope.images = [];
      $scope.parent_id = null;
      $scope.current_index = 0;
    };

    $scope.resetCurrentGallery = function(){
      $scope.images = [];
      $scope.current_index = 0;
    };

    $scope.loadImagesForGallery = function(id){
      $scope.resetCurrentGallery();
      Gallery.getCollection({operation: 'images', id: id }, $scope.appendToImages);
    };

    $scope.nextImage = function(){
      if ($scope.current_index + 1 < $scope.images.length){ $scope.current_index +=1; }
    };

    $scope.previousImage = function(){
      if ($scope.current_index - 1 >= 0) { $scope.current_index -= 1; }
    };

    $scope.firstImage = function(){
      $scope.current_index = 0;
    };

    $scope.lastImage = function(){
      $scope.current_index = $scope.images.length - 1;
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
        $scope.galleries = $scope.filterEmptyGalleries(data);
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
