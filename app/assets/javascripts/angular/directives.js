var galleryDirectives = angular.module('galleryDirectives', []);

galleryDirectives.directive('imageonload', function(){
  return {
    restrict: 'A',
    link: function(scope, element, attrs){
      element.bind('load', function(){
        scope.$apply(attrs.imageonload);
      });
    }
  };
});
