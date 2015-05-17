var galleryApp = angular.module("GalleryApp", [
  'ngRoute',
  'ngTouch',
  'galleryControllers',
  'galleryServices',
  'galleryDirectives',
]);

galleryApp.config(['$routeProvider',
  function($routeProvider){
    $routeProvider.
    when('/gallery/:id/slideshow/:image_id', {
      templateUrl: 'slideshow.html',
      controller: 'SlideshowCtrl'
    }).
    when('/gallery/:id/slideshow', {
      templateUrl: 'slideshow.html',
      controller: 'SlideshowCtrl'
    }).
    when('/gallery/:id', {
      templateUrl: 'gallery.html',
      controller: 'GalleryCtrl'
    }).
    when('/', {
      templateUrl: 'gallery.html',
      controller: 'GalleryCtrl'
    }).
    otherwise({
      redirectTo: '/'
    });
  }
]);

galleryApp.run(['$rootScope', '$document',
  function($rootScope, $document){
    var handleKeyDown = function(event){
      $rootScope.$apply(function(){
        switch(event.which){
          case 27:
            $rootScope.$broadcast('key.escape');
            break;
          case 37:
            $rootScope.$broadcast('key.left');
            break;
          case 38:
            $rootScope.$broadcast('key.up');
            break;
          case 39:
            $rootScope.$broadcast('key.right');
            break;
          case 40:
            $rootScope.$broadcast('key.down');
            break;
          default:
            break;
        };
      });
    };

    angular.element($document).bind('keydown', handleKeyDown);
    $rootScope.$on('destroy', function(){
      angular.element($document).unbind('keydown', handleKeyDown);
    });
  }
]);

jQuery(document).on('ready page:load', function(arguments){
  angular.bootstrap(document.body, ['GalleryApp'])
});
