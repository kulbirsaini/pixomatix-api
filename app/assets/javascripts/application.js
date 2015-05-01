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
//= require_tree .


var galleryApp = angular.module("GalleryApp", [
  'ngRoute',
  'galleryControllers',
  'galleryServices',
]);

galleryApp.config(['$routeProvider',
  function($routeProvider) {
    $routeProvider.
    when('/images', {
      templateUrl: 'gallery.html',
      controller: 'GalleryCtrl'
    }).
    when('/images/:id', {
      templateUrl: 'gallery.html',
      controller: 'GalleryCtrl'
    }).
    otherwise({
      redirectTo: '/images'
    });
  }
]);

jQuery(document).on('ready page:load', function(arguments) {
  angular.bootstrap(document.body, ['GalleryApp'])
});
