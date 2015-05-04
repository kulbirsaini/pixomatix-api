var galleryServices = angular.module("galleryServices", ['ngResource']);

galleryServices.factory("Gallery", ["$resource", "$routeParams",
  function($resouce, $routeParams){
    var resource = $resouce("/images/:id/:operation.json", { id: '@id' }, {
      get: { method: 'GET', isArray: false },
      query: { method: 'GET', isArray: true }
    });

    resource.getCollection = function(params, success, failure){
      return this.query({ operation: params.operation, id: params.id }, success, failure);
    };

    resource.getObject = function(params, success, failure){
      return this.get({ operation: params.operation, id: params.id }, success, failure);
    };

    return resource;
  }
]);

galleryServices.service('ImageService', ['Gallery',
  function(Gallery){
    this.images = [];
    this.parent_id = null;

    this.resetData = function(){
      this.images = [];
      this.parent_id = null;
    };

    this.setImages = function(images){
      this.images = images;
    };

    this.getImages = function(){
      return this.images;
    };

    this.setParentId = function(parent_id){
      this.parent_id = parent_id;
    };

    this.getParentId = function(){
      return this.parent_id;
    };
  }
]);
