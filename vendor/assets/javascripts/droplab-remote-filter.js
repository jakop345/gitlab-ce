(function(f){if(typeof exports==="object"&&typeof module!=="undefined"){module.exports=f()}else if(typeof define==="function"&&define.amd){define([],f)}else{var g;if(typeof window!=="undefined"){g=window}else if(typeof global!=="undefined"){g=global}else if(typeof self!=="undefined"){g=self}else{g=this}g=(g.droplab||(g.droplab = {}));g=(g.ajax||(g.ajax = {}));g=(g.datasource||(g.datasource = {}));g.js = f()}})(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
/* global droplab */
droplab.plugin(function init(DropLab) {
  var TIMEOUT;
  var LAST_SEARCH_VALUE;
  var LOADING = false;

  var NON_CHARACTER_KEYS = [16, 17, 18, 20, 37, 38, 39, 40, 91, 93];

  var buildParams = function buildParams(searchValue, config) {
    var params = config.params;
    var paramsArray = Object.keys(params).map(function(param) {
      return param + '=' + (params[param] || '');
    });
    return '?' + config.searchKey + '=' + searchValue + '&' + paramsArray.join('&')
  };

  var requestCallback = function requestCallback() {
    LOADING = false;
  };

  var trigger = function trigger() {
    var config = droplab.config[this.id];
    var searchValue = this.trigger.value;
    if (searchValue === LAST_SEARCH_VALUE) return this.list.show();
    LAST_SEARCH_VALUE = searchValue;
    LOADING = true;
    this.list.setData([]);
    droplab.addData(config.trigger, config.endpoint + buildParams(searchValue, config), requestCallback.bind(this));
  };

  var debounceTrigger = function debounceTrigger(e) {
    if (NON_CHARACTER_KEYS.indexOf(e.detail.which || e.detail.keyCode) > -1) return;
    if (TIMEOUT) clearTimeout(TIMEOUT);
    if (LOADING) return;
    TIMEOUT = setTimeout(trigger.bind(e.detail.hook || this), 200);
  };

  window.addEventListener('keydown.dl', debounceTrigger);
  droplab.hooks.forEach(function(hook) {
    hook.trigger.addEventListener('focus', debounceTrigger.bind(hook));
  });
});

},{}]},{},[1])(1)
});
