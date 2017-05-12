'use strict';

var dnscheck = angular.module('dnscheck',['pascalprecht.translate']);
dnscheck.config(['$locationProvider', function($locationProvider) {
  $locationProvider.html5Mode(true);
}]);

dnscheck.factory('customLoader', function ($http, $q, $timeout) {
  // return loaderFn
  return function (options) {
    var deferred = $q.defer(); 
    var data = {
    };
	var lang = options.key;
    $http.get('/lang/' + lang + '.json').success(function(interface_language_data){
		angular.extend(data, interface_language_data);
		$http.get('/faq?lang=' + lang ).success(function(faq){
			angular.extend(data, faq);
			deferred.resolve(data);
		});
    });
	
	return deferred.promise;  
  };
});

dnscheck.config(function($translateProvider) {
	$translateProvider.useLoader('customLoader');
	var lang;
		if (navigator.userLanguage) // Explorer
			lang = navigator.userLanguage.substring(0, 2);
		else if (navigator.language) // FF
			lang = navigator.languages ? navigator.languages[0].substring(0, 2) : (navigator.language.substring(0, 2) || navigator.userLanguage.substring(0, 2));
		else
			lang = "en";
		
	$translateProvider.preferredLanguage(lang);
});

dnscheck.filter("asDate", function () {
	return function (input) {
		if (typeof input ==='undefined') return new Date(); 
		var d = input.split(/[^0-9]/);
		var date = new Date(Date.UTC(d[0], d[1]-1, d[2], d[3], d[4], d[5]));
		return date;
	}
});

dnscheck.directive('lang',function(){

  return {
    restrict: 'E',
    scope: { lang: '@' },
    transclude: true,
    controller: ['$rootScope','$scope','$translate',function($rootScope,$scope, $translate){
      $scope.setLang = function(lang){
        $rootScope.language = lang;
        $translate.use(lang);
      };
    }],
    templateUrl: '/ang/lang'
  };
});

dnscheck.directive('navigation',function(){

  return {
    restrict: 'E',
    transclude: true,
    scope: { navId: '@', inverse: '@' },
    controller: ['$rootScope', '$scope', function($rootScope, $scope){
      var panes = $scope.panes = [];
      $scope.select = function(pane) {
        angular.forEach(panes, function(pane) {
          pane.selected = false;
        });
        pane.selected = true;
        $scope.currentTab = pane.tabId;
        $scope.$parent[$scope.navId+'_currentTab'] = pane.tabId;
      };
	  
      this.addPane = function(pane) {
        var c = 0;
        if (panes.length === c) {
          $scope.select(pane);
        }
        panes.push(pane);
		if ($scope.navId == 'main') {
			$rootScope.panes = panes;
		}
      };
    }],
    templateUrl: '/ang/navigation'
  };
});

dnscheck.directive('tab',function(){
  return {
    restrict: 'E',
    require: '^navigation',
    transclude: true,
    scope: { tabTitle: '@', tabId: '@' },
    link: function(scope, element, attrs, tabsCtrl) {
      tabsCtrl.addPane(scope);
    },
    templateUrl: '/ang/tab'
  };
});

dnscheck.directive('domainCheck',function(){
  return {
    restrict: 'E',
    transclude: true,
    scope : { inactive: '@'},
    controller: ['$rootScope', '$scope', '$window', '$location', function($rootScope, $scope, $window, $location){
        $scope.interval = 5000; // 5 sec retry
        $scope.form = {};
        $scope.form.ipv4 = true;
        $scope.form.ipv6 = true;
		$scope.form.profile = "default_profile";
        $scope.location = $window.location.href;
        var lang;
            if (navigator.userLanguage) // Explorer
                lang = navigator.userLanguage.substring(0, 2);
            else if (navigator.language) // FF
                lang = navigator.languages ? navigator.languages[0].substring(0, 2) : (navigator.language.substring(0, 2) || navigator.userLanguage.substring(0, 2));
            else
               lang = "en";
        if(typeof $rootScope.language === 'undefined') $rootScope.language = lang;

        if($scope.inactive) {
          $scope.contentUrl = '/ang/inactive_domain_check'
          $scope.ns_list = [{ns:"",ip:""}];
          //$scope.ds_list = [{algorithm:"", digest:""}];
          $scope.ds_list = [];
        }
        else $scope.contentUrl = '/ang/domain_check'

        $scope.fetchFromParent = function(){
          $.ajax('/parent',{
            data : $scope.form,
            dataType : 'json',
            success: function(data){
              $scope.$apply($scope.ns_list = data.result.ns_list);
              $scope.$apply($scope.ds_list = data.result.ds_list);
            },
            error: function(){
              alert('Can\'t get test history');
            }
          });
        };

        $scope.resolveNS = function(e,idx){
          var $ns = $(e.target).val();
          if($scope.ns_list[idx].ip !== '') return;
          $.ajax('/resolve',{
            data : {data:$ns},
            dataType : 'json',
            success: function(data){
              if(data.result.length == 1){
                $scope.$apply($scope.ns_list[idx].ip = data.result[0][$ns]);
              }
              else {
                $scope.$apply($scope.ns_list[idx].ip = data.result[0][$ns]);
                for(var i = 1; i< data.result.length; i++){
                  $scope.$apply($scope.ns_list.splice(idx,0,{ns:$ns,ip:data.result[i][$ns]}));
                }
              }
            },
            error: function(){
              alert('Can\'t resolve name');
            }
          });
        };

        $scope.exportFile = function(evt){
          var a = evt.target;
          var text = $('#adv_result').text();
          a.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(text));
        };

        $scope.exportHTML = function(evt){
          var a = evt.target;
          a.setAttribute('href', '/export?type=HTML&lang=' + $rootScope.language + '&test_id=' + $scope.job_id);
        };

		$scope.getModules = function(result){
          var modules = {};
          for( var item in result ){
            if( typeof modules[result[item].module] === 'undefined' ) modules[result[item].module] = 'check';
            if( result[item].level=='WARNING') modules[result[item].module] = 'warning';
            if( result[item].level=='ERROR') modules[result[item].module] = 'ban';
            if( result[item].level=='CRITICAL') modules[result[item].module] = 'ban';
          } 
          $scope.modules = modules;
          return Object.keys(modules);
        };

        $scope.getNS = function(result){
          var ns = {};
          for( var item in result ){
            if(typeof result[item].ns !== 'undefined') ns[result[item].ns] = 1;
          } 
          return Object.keys(ns);
        };

        $scope.getItems = function(result, module){
          var ret = [];
          for( var item in result ){
            if( result[item].module == module ) ret.push( result[item] );
          }
          return ret;
        };

        $scope.getItemsByNS = function(result, ns){
          var ret = [];
          for( var item in result ){
            if( result[item].ns == ns ) ret.push( result[item] );
          }
          return ret;
        };

        $scope.addNS = function(){
          $scope.ns_list.push({name:"",ip:""});
        };

        $scope.addDigest = function(){
          $scope.ds_list.push({keytag:"", algorithm:"", digtype: "", digest:""});
        };

        $scope.removeNS = function(idx){
          $scope.ns_list.splice(idx,1);
        };

        $scope.removeDigest = function(idx){
          $scope.ds_list.splice(idx,1);
        };

        $scope.showFAQ = function(idx){
			$rootScope.panes[1].selected = false;
			$rootScope.panes[2].selected = true;
			$rootScope.main_currentTab = 'faq';
			$location.hash('undelegated');
        };
		
        $scope.showResult = function(){
          $('.run-btn-icon').addClass('fa-play-circle-o').removeClass('loading');
          $.ajax('/result',{
            data : { id: $scope.job_id, language: $rootScope.language },
            dataType : 'json',
            success: function(data){
              $scope.test = { id: data.result.id, creation_time: data.result.creation_time};
              $scope.result = data.result.results;
              $scope.getModules(data.result.results);
              $scope.form = data.result.params;
              $scope.ns_list = data.result.params.nameservers;
              $scope.ds_list = data.result.params.ds_info;
              if (data.result.params.nameservers) {
                  $scope.contentUrl = '/ang/inactive_domain_check';
                  if ($rootScope.panes) {
                      $rootScope.panes[1].selected = true
                      $rootScope.panes[0].selected = false
                  }
              } else {
                  $scope.contentUrl = '/ang/domain_check';
                  if ($rootScope.panes) {
                      $rootScope.panes[0].selected = true
                      $rootScope.panes[1].selected = false
                  }
              }
              $scope.$apply();
              $.ajax('/history',{
                data : { data: JSON.stringify($scope.form) },
                dataType : 'json',
                success: function(data){
                  $scope.$apply($scope.history = data.result);
                },
                error: function(){
                  alert('Can\'t get test history');
                }
              });
            },
            error: function(){
              alert('Can\'t get test result');
            }
          });

          $.ajax('/history',{
            data : { data: JSON.stringify($scope.form) },
            dataType : 'json',
            success: function(data){
              $scope.$apply($scope.history = data.result);
            },
            error: function(){
              alert('Can\'t get test history');
            }
          });
        
        };
        $scope.progressCheck = function(){
          $.ajax('/progress',{
            data : { id: $scope.job_id },
            dataType : 'json',
            success: function(data){
              $scope.$apply($scope.progress = data.progress.toString());
	      $scope.$apply($scope.progressStyle = {"width" : data.progress.toString()+"%"});
              if(data.progress == 100){ $scope.showResult(); }
              else {
                setTimeout($scope.progressCheck, $scope.interval);
              }
            },
            error: function(){
              alert('Can\'t get test progress');
            }
          });
        };
        $scope.domainCheck = function(){
			if($scope.inactive) { 
				$scope.form.nameservers = $scope.ns_list;
				$scope.form.ds_info = $scope.ds_list;
			}
			
			$.ajax('/check_syntax',{
				data : { data: JSON.stringify($scope.form) },
				dataType : 'json',
				success: function(data){
					if(data.result.status === 'nok') {
						alert(data.result.message);
					}
					else {
						$scope.$apply($scope.startTest(data.result));
					}
				},
				error: function(){
					alert('Can\'t get syntax test result');
				}
			});

			$scope.startTest = function () {
				$scope.result = null;
				if( (typeof $scope.form.domain === 'undefined') || ($scope.form.domain === '') ){
					alert('Can\'t run test for unspecified domain name');
					return;
				}
				if( $scope.inactive && ($scope.ns_list.length == 0 || typeof $scope.ns_list[0].ns === 'undefined' ||$scope.ns_list[0].ns === '')  ){
					alert('Can\'t run test without at least one nameserver specified');
					return;
				}
				$location.path('/');
				$('.run-btn-icon').removeClass('fa-play-circle-o').addClass('loading');
				$.ajax('/run',{
					data : { data: JSON.stringify($scope.form) },
					type: 'post',
					dataType : 'json',
					success: function(data){
                                            $scope.job_id = data.job_id;
                                            $location.url('/test/' + data.job_id);
                                            $scope.location = $location.absUrl();
                                            $scope.progressCheck();
					},
					error: function(){
						alert('Can\'t run test');
					}
				});
			};
		};

        /* Disgusting hack, but better than passing data via Perl templates */
        var ppa = $location.path().split("/");
        if (ppa[1] == "test" && ppa[2] != undefined) {
            $scope.job_id = ppa[2];
            $scope.showResult();
        }
    }],
    template: '<div ng-include="contentUrl"></div>'
  };
});

dnscheck.directive('version',function(){
  return {
//    restrict: 'E',
    transclude: true,
    scope : true,
    controller: function($scope){
      $.ajax('/version',{
        data : {},
        dataType : 'json',
        success: function(data){
          $scope.version = data.result;
		  if (data.result.indexOf("Backend") > -1 && data.result.indexOf("Frontend") > -1 ) 
			$scope.color = 'red';
        },
        error: function(){
          alert('Can\'t get version');
        }
      });
    },
    template: '{{version}}'
  };
});
