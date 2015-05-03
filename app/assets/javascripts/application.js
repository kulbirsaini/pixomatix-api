// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require bootstrap-sprockets
//= require jquery_ujs
//= require turbolinks
//= require angular/angular
//= require angular-route/angular-route
//= require angular-resource/angular-resource
//= require angular-touch/angular-touch
//= require_tree .


var galleryApp = angular.module("GalleryApp", [
  'ngRoute',
  'ngTouch',
  'galleryControllers',
  'galleryServices',
]);

galleryApp.config(['$routeProvider',
  function($routeProvider){
    $routeProvider.
    when('/images', {
      templateUrl: 'gallery.html',
      controller: 'GalleryCtrl'
    }).
    when('/images/:id', {
      templateUrl: 'gallery.html',
      controller: 'GalleryCtrl'
    }).
    when('/images/:id/slideshow', {
      templateUrl: 'slideshow.html',
      controller: 'SlideshowCtrl'
    }).
    otherwise({
      redirectTo: '/images'
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
