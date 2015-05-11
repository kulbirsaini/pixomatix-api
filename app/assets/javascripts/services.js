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

galleryServices.service('Settings', ['Gallery',
  function(Gallery){
    this.settings = {}

    this.reset = function(){
      this.settings = {};
    };

    this.setValue = function(variable, values){
      this.settings[variable] = values;
    };

    this.getValue = function(variable){
      return this.settings[variable];
    };
  }
]);
