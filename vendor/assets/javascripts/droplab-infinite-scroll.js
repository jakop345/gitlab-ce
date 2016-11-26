(function(f){if(typeof exports==="object"&&typeof module!=="undefined"){module.exports=f()}else if(typeof define==="function"&&define.amd){define([],f)}else{var g;if(typeof window!=="undefined"){g=window}else if(typeof global!=="undefined"){g=global}else if(typeof self!=="undefined"){g=self}else{g=this}g=(g.droplab||(g.droplab = {}));g=(g.ajax||(g.ajax = {}));g=(g.datasource||(g.datasource = {}));g.js = f()}})(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
/* global droplab */
droplab.plugin(function init(DropLab) {
  var TIMEOUT;
  var LOADING = false;

  var NON_CHARACTER_KEYS = [16, 17, 18, 20, 37, 38, 39, 40, 91, 93];

  var buildParams = function buildParams(searchValue, config) {
    var params = config.params;
    var paramsArray = Object.keys(params).map(function(param) {
      return param + '=' + (params[param] || '');
    });
    return '?' + config.searchKey + '=' + searchValue + '&' + paramsArray.join('&')
  };

  var requestCallback = function requestCallback(data, req) {
    var config = droplab.config[this.id];
    if (data.length === 0) config.params[config.paginationKey]--;
    LOADING = false;
    appendLoadingUI.call(this, data, req);
  };

  var loadNextPage = function loadNextPage(e) {
    LOADING = true;

    var target = e.target;
    var shouldNotLoad = target.scrollTop < target.scrollHeight - target.offsetHeight;

    if (!this.list.list.querySelector('#dl-infinite-scroll-loading-element')) appendLoadingUI.call(this);

    if (shouldNotLoad) return;

    var config = droplab.config[this.id];
    var searchValue = this.trigger.value;
    if (!config.append) config.append = true;

    config.params[config.paginationKey]++;

    if (!config.endpoint) return; // TODO: Accept an array instead of endpoint.

    droplab.addData(config.trigger, config.endpoint + buildParams(searchValue, config), requestCallback.bind(this));
  };

  var debounceScroll = function debounceScroll(e) {
    if (TIMEOUT) clearTimeout(TIMEOUT);
    if (LOADING) return;
    TIMEOUT = setTimeout(loadNextPage.bind(this, e), 200);
  };

  var disableParentScroll = function disableParentScroll() {
    document.body.style.overflow = 'hidden';
    document.documentElement.style.overflow = 'hidden';
  };

  var enableParentScroll = function enableParentScroll() {
    document.body.style.overflow = '';
    document.documentElement.style.overflow = '';
  };

  var appendLoadingUI = function appendLoadingUI(data, req, overwriteList) {
    var currentContainer = this.list.list.querySelector('#dl-infinite-scroll-loading-element');
    if (currentContainer) currentContainer.remove();

    var container = document.createElement('li');
    container.id = 'dl-infinite-scroll-loading-element';

    var config = droplab.config[this.id];

    var loadingElement = typeof config.loadingHTML === 'function' ? config.loadingHTML.call(this, data, req, config) : config.loadingHTML;
    container.appendChild(loadingElement);

    overwriteList ? this.list.list.innerHTML = container.outerHTML : this.list.list.appendChild(container);
  };

  var resetPagination = function resetPagination(e) {
    var keycode = e.detail.which || e.detail.keyCode;
    if (NON_CHARACTER_KEYS.indexOf(keycode) > -1) return;
    var config = droplab.config[this.id];
    config.params[config.paginationKey] = 1;
  };

  droplab.hooks.forEach(function(hook) {
    hook.list.list.addEventListener('scroll', debounceScroll.bind(hook));
    hook.list.list.addEventListener('mouseenter', disableParentScroll);
    hook.list.list.addEventListener('mouseleave', enableParentScroll);
    hook.trigger.addEventListener('focus', appendLoadingUI.bind(hook, null, null, true));
    hook.trigger.addEventListener('keydown.dl', resetPagination.bind(hook));
  });
});

},{}]},{},[1])(1)
});
