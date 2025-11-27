/*
* ----------------------------------------------------------------------------
* PO Files Manipulation - Text-PO/share/gettext.js
* Version v0.4.0
* Copyright(c) 2021-2023 DEGUEST Pte. Ltd.
* Author: Jacques Deguest <jack@deguest.jp>
* Created 2021/06/29
* Modified 2024/12/22
* All rights reserved
* 
* This program is free software; you can redistribute  it  and/or  modify  it
* under the same terms as Perl itself.
* ----------------------------------------------------------------------------
* Use perldoc gettext.js to see the inline documentation for this library
*/
// 'use strict';

// XXX Promise polyfill if necessary
;(function()
{
    /*!
     * @overview es6-promise - a tiny implementation of Promises/A+.
     * @copyright Copyright (c) 2014 Yehuda Katz, Tom Dale, Stefan Penner and contributors (Conversion to ES6 API by Jake Archibald)
     * @license   Licensed under MIT license
     *            See https://raw.githubusercontent.com/stefanpenner/es6-promise/master/LICENSE
     * @version   v4.2.8+1e68dce6
     */
    
    (function (global, factory) {
        typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory() :
        typeof define === 'function' && define.amd ? define(factory) :
        (global.ES6Promise = factory());
    }(this, (function () { 'use strict';
    
    function objectOrFunction(x) {
      var type = typeof x;
      return x !== null && (type === 'object' || type === 'function');
    }
    
    function isFunction(x) {
      return typeof x === 'function';
    }
    
    
    
    var _isArray = void 0;
    if (Array.isArray) {
      _isArray = Array.isArray;
    } else {
      _isArray = function (x) {
        return Object.prototype.toString.call(x) === '[object Array]';
      };
    }
    
    var isArray = _isArray;
    
    var len = 0;
    var vertxNext = void 0;
    var customSchedulerFn = void 0;
    
    var asap = function asap(callback, arg) {
      queue[len] = callback;
      queue[len + 1] = arg;
      len += 2;
      if (len === 2) {
        // If len is 2, that means that we need to schedule an async flush.
        // If additional callbacks are queued before the queue is flushed, they
        // will be processed by this flush that we are scheduling.
        if (customSchedulerFn) {
          customSchedulerFn(flush);
        } else {
          scheduleFlush();
        }
      }
    };
    
    function setScheduler(scheduleFn) {
      customSchedulerFn = scheduleFn;
    }
    
    function setAsap(asapFn) {
      asap = asapFn;
    }
    
    var browserWindow = typeof window !== 'undefined' ? window : undefined;
    var browserGlobal = browserWindow || {};
    var BrowserMutationObserver = browserGlobal.MutationObserver || browserGlobal.WebKitMutationObserver;
    var isNode = typeof self === 'undefined' && typeof process !== 'undefined' && {}.toString.call(process) === '[object process]';
    
    // test for web worker but not in IE10
    var isWorker = typeof Uint8ClampedArray !== 'undefined' && typeof importScripts !== 'undefined' && typeof MessageChannel !== 'undefined';
    
    // node
    function useNextTick() {
      // node version 0.10.x displays a deprecation warning when nextTick is used recursively
      // see https://github.com/cujojs/when/issues/410 for details
      return function () {
        return process.nextTick(flush);
      };
    }
    
    // vertx
    function useVertxTimer() {
      if (typeof vertxNext !== 'undefined') {
        return function () {
          vertxNext(flush);
        };
      }
    
      return useSetTimeout();
    }
    
    function useMutationObserver() {
      var iterations = 0;
      var observer = new BrowserMutationObserver(flush);
      var node = document.createTextNode('');
      observer.observe(node, { characterData: true });
    
      return function () {
        node.data = iterations = ++iterations % 2;
      };
    }
    
    // web worker
    function useMessageChannel() {
      var channel = new MessageChannel();
      channel.port1.onmessage = flush;
      return function () {
        return channel.port2.postMessage(0);
      };
    }
    
    function useSetTimeout() {
      // Store setTimeout reference so es6-promise will be unaffected by
      // other code modifying setTimeout (like sinon.useFakeTimers())
      var globalSetTimeout = setTimeout;
      return function () {
        return globalSetTimeout(flush, 1);
      };
    }
    
    var queue = new Array(1000);
    function flush() {
      for (var i = 0; i < len; i += 2) {
        var callback = queue[i];
        var arg = queue[i + 1];
    
        callback(arg);
    
        queue[i] = undefined;
        queue[i + 1] = undefined;
      }
    
      len = 0;
    }
    
    function attemptVertx() {
      try {
        var vertx = Function('return this')().require('vertx');
        vertxNext = vertx.runOnLoop || vertx.runOnContext;
        return useVertxTimer();
      } catch (e) {
        return useSetTimeout();
      }
    }
    
    var scheduleFlush = void 0;
    // Decide what async method to use to triggering processing of queued callbacks:
    if (isNode) {
      scheduleFlush = useNextTick();
    } else if (BrowserMutationObserver) {
      scheduleFlush = useMutationObserver();
    } else if (isWorker) {
      scheduleFlush = useMessageChannel();
    } else if (browserWindow === undefined && typeof require === 'function') {
      scheduleFlush = attemptVertx();
    } else {
      scheduleFlush = useSetTimeout();
    }
    
    function then(onFulfillment, onRejection) {
      var parent = this;
    
      var child = new this.constructor(noop);
    
      if (child[PROMISE_ID] === undefined) {
        makePromise(child);
      }
    
      var _state = parent._state;
    
    
      if (_state) {
        var callback = arguments[_state - 1];
        asap(function () {
          return invokeCallback(_state, child, callback, parent._result);
        });
      } else {
        subscribe(parent, child, onFulfillment, onRejection);
      }
    
      return child;
    }
    
    /**
      `Promise.resolve` returns a promise that will become resolved with the
      passed `value`. It is shorthand for the following:
    
      ```javascript
      let promise = new Promise(function(resolve, reject){
        resolve(1);
      });
    
      promise.then(function(value){
        // value === 1
      });
      ```
    
      Instead of writing the above, your code now simply becomes the following:
    
      ```javascript
      let promise = Promise.resolve(1);
    
      promise.then(function(value){
        // value === 1
      });
      ```
    
      @method resolve
      @static
      @param {Any} value value that the returned promise will be resolved with
      Useful for tooling.
      @return {Promise} a promise that will become fulfilled with the given
      `value`
    */
    function resolve$1(object) {
      /*jshint validthis:true */
      var Constructor = this;
    
      if (object && typeof object === 'object' && object.constructor === Constructor) {
        return object;
      }
    
      var promise = new Constructor(noop);
      resolve(promise, object);
      return promise;
    }
    
    var PROMISE_ID = Math.random().toString(36).substring(2);
    
    function noop() {}
    
    var PENDING = void 0;
    var FULFILLED = 1;
    var REJECTED = 2;
    
    function selfFulfillment() {
      return new TypeError("You cannot resolve a promise with itself");
    }
    
    function cannotReturnOwn() {
      return new TypeError('A promises callback cannot return that same promise.');
    }
    
    function tryThen(then$$1, value, fulfillmentHandler, rejectionHandler) {
      try {
        then$$1.call(value, fulfillmentHandler, rejectionHandler);
      } catch (e) {
        return e;
      }
    }
    
    function handleForeignThenable(promise, thenable, then$$1) {
      asap(function (promise) {
        var sealed = false;
        var error = tryThen(then$$1, thenable, function (value) {
          if (sealed) {
            return;
          }
          sealed = true;
          if (thenable !== value) {
            resolve(promise, value);
          } else {
            fulfill(promise, value);
          }
        }, function (reason) {
          if (sealed) {
            return;
          }
          sealed = true;
    
          reject(promise, reason);
        }, 'Settle: ' + (promise._label || ' unknown promise'));
    
        if (!sealed && error) {
          sealed = true;
          reject(promise, error);
        }
      }, promise);
    }
    
    function handleOwnThenable(promise, thenable) {
      if (thenable._state === FULFILLED) {
        fulfill(promise, thenable._result);
      } else if (thenable._state === REJECTED) {
        reject(promise, thenable._result);
      } else {
        subscribe(thenable, undefined, function (value) {
          return resolve(promise, value);
        }, function (reason) {
          return reject(promise, reason);
        });
      }
    }
    
    function handleMaybeThenable(promise, maybeThenable, then$$1) {
      if (maybeThenable.constructor === promise.constructor && then$$1 === then && maybeThenable.constructor.resolve === resolve$1) {
        handleOwnThenable(promise, maybeThenable);
      } else {
        if (then$$1 === undefined) {
          fulfill(promise, maybeThenable);
        } else if (isFunction(then$$1)) {
          handleForeignThenable(promise, maybeThenable, then$$1);
        } else {
          fulfill(promise, maybeThenable);
        }
      }
    }
    
    function resolve(promise, value) {
      if (promise === value) {
        reject(promise, selfFulfillment());
      } else if (objectOrFunction(value)) {
        var then$$1 = void 0;
        try {
          then$$1 = value.then;
        } catch (error) {
          reject(promise, error);
          return;
        }
        handleMaybeThenable(promise, value, then$$1);
      } else {
        fulfill(promise, value);
      }
    }
    
    function publishRejection(promise) {
      if (promise._onerror) {
        promise._onerror(promise._result);
      }
    
      publish(promise);
    }
    
    function fulfill(promise, value) {
      if (promise._state !== PENDING) {
        return;
      }
    
      promise._result = value;
      promise._state = FULFILLED;
    
      if (promise._subscribers.length !== 0) {
        asap(publish, promise);
      }
    }
    
    function reject(promise, reason) {
      if (promise._state !== PENDING) {
        return;
      }
      promise._state = REJECTED;
      promise._result = reason;
    
      asap(publishRejection, promise);
    }
    
    function subscribe(parent, child, onFulfillment, onRejection) {
      var _subscribers = parent._subscribers;
      var length = _subscribers.length;
    
    
      parent._onerror = null;
    
      _subscribers[length] = child;
      _subscribers[length + FULFILLED] = onFulfillment;
      _subscribers[length + REJECTED] = onRejection;
    
      if (length === 0 && parent._state) {
        asap(publish, parent);
      }
    }
    
    function publish(promise) {
      var subscribers = promise._subscribers;
      var settled = promise._state;
    
      if (subscribers.length === 0) {
        return;
      }
    
      var child = void 0,
          callback = void 0,
          detail = promise._result;
    
      for (var i = 0; i < subscribers.length; i += 3) {
        child = subscribers[i];
        callback = subscribers[i + settled];
    
        if (child) {
          invokeCallback(settled, child, callback, detail);
        } else {
          callback(detail);
        }
      }
    
      promise._subscribers.length = 0;
    }
    
    function invokeCallback(settled, promise, callback, detail) {
      var hasCallback = isFunction(callback),
          value = void 0,
          error = void 0,
          succeeded = true;
    
      if (hasCallback) {
        try {
          value = callback(detail);
        } catch (e) {
          succeeded = false;
          error = e;
        }
    
        if (promise === value) {
          reject(promise, cannotReturnOwn());
          return;
        }
      } else {
        value = detail;
      }
    
      if (promise._state !== PENDING) {
        // noop
      } else if (hasCallback && succeeded) {
        resolve(promise, value);
      } else if (succeeded === false) {
        reject(promise, error);
      } else if (settled === FULFILLED) {
        fulfill(promise, value);
      } else if (settled === REJECTED) {
        reject(promise, value);
      }
    }
    
    function initializePromise(promise, resolver) {
      try {
        resolver(function resolvePromise(value) {
          resolve(promise, value);
        }, function rejectPromise(reason) {
          reject(promise, reason);
        });
      } catch (e) {
        reject(promise, e);
      }
    }
    
    var id = 0;
    function nextId() {
      return id++;
    }
    
    function makePromise(promise) {
      promise[PROMISE_ID] = id++;
      promise._state = undefined;
      promise._result = undefined;
      promise._subscribers = [];
    }
    
    function validationError() {
      return new Error('Array Methods must be provided an Array');
    }
    
    var Enumerator = function () {
      function Enumerator(Constructor, input) {
        this._instanceConstructor = Constructor;
        this.promise = new Constructor(noop);
    
        if (!this.promise[PROMISE_ID]) {
          makePromise(this.promise);
        }
    
        if (isArray(input)) {
          this.length = input.length;
          this._remaining = input.length;
    
          this._result = new Array(this.length);
    
          if (this.length === 0) {
            fulfill(this.promise, this._result);
          } else {
            this.length = this.length || 0;
            this._enumerate(input);
            if (this._remaining === 0) {
              fulfill(this.promise, this._result);
            }
          }
        } else {
          reject(this.promise, validationError());
        }
      }
    
      Enumerator.prototype._enumerate = function _enumerate(input) {
        for (var i = 0; this._state === PENDING && i < input.length; i++) {
          this._eachEntry(input[i], i);
        }
      };
    
      Enumerator.prototype._eachEntry = function _eachEntry(entry, i) {
        var c = this._instanceConstructor;
        var resolve$$1 = c.resolve;
    
    
        if (resolve$$1 === resolve$1) {
          var _then = void 0;
          var error = void 0;
          var didError = false;
          try {
            _then = entry.then;
          } catch (e) {
            didError = true;
            error = e;
          }
    
          if (_then === then && entry._state !== PENDING) {
            this._settledAt(entry._state, i, entry._result);
          } else if (typeof _then !== 'function') {
            this._remaining--;
            this._result[i] = entry;
          } else if (c === Promise$2) {
            var promise = new c(noop);
            if (didError) {
              reject(promise, error);
            } else {
              handleMaybeThenable(promise, entry, _then);
            }
            this._willSettleAt(promise, i);
          } else {
            this._willSettleAt(new c(function (resolve$$1) {
              return resolve$$1(entry);
            }), i);
          }
        } else {
          this._willSettleAt(resolve$$1(entry), i);
        }
      };
    
      Enumerator.prototype._settledAt = function _settledAt(state, i, value) {
        var promise = this.promise;
    
    
        if (promise._state === PENDING) {
          this._remaining--;
    
          if (state === REJECTED) {
            reject(promise, value);
          } else {
            this._result[i] = value;
          }
        }
    
        if (this._remaining === 0) {
          fulfill(promise, this._result);
        }
      };
    
      Enumerator.prototype._willSettleAt = function _willSettleAt(promise, i) {
        var enumerator = this;
    
        subscribe(promise, undefined, function (value) {
          return enumerator._settledAt(FULFILLED, i, value);
        }, function (reason) {
          return enumerator._settledAt(REJECTED, i, reason);
        });
      };
    
      return Enumerator;
    }();
    
    /**
      `Promise.all` accepts an array of promises, and returns a new promise which
      is fulfilled with an array of fulfillment values for the passed promises, or
      rejected with the reason of the first passed promise to be rejected. It casts all
      elements of the passed iterable to promises as it runs this algorithm.
    
      Example:
    
      ```javascript
      let promise1 = resolve(1);
      let promise2 = resolve(2);
      let promise3 = resolve(3);
      let promises = [ promise1, promise2, promise3 ];
    
      Promise.all(promises).then(function(array){
        // The array here would be [ 1, 2, 3 ];
      });
      ```
    
      If any of the `promises` given to `all` are rejected, the first promise
      that is rejected will be given as an argument to the returned promises's
      rejection handler. For example:
    
      Example:
    
      ```javascript
      let promise1 = resolve(1);
      let promise2 = reject(new Error("2"));
      let promise3 = reject(new Error("3"));
      let promises = [ promise1, promise2, promise3 ];
    
      Promise.all(promises).then(function(array){
        // Code here never runs because there are rejected promises!
      }, function(error) {
        // error.message === "2"
      });
      ```
    
      @method all
      @static
      @param {Array} entries array of promises
      @param {String} label optional string for labeling the promise.
      Useful for tooling.
      @return {Promise} promise that is fulfilled when all `promises` have been
      fulfilled, or rejected if any of them become rejected.
      @static
    */
    function all(entries) {
      return new Enumerator(this, entries).promise;
    }
    
    /**
      `Promise.race` returns a new promise which is settled in the same way as the
      first passed promise to settle.
    
      Example:
    
      ```javascript
      let promise1 = new Promise(function(resolve, reject){
        setTimeout(function(){
          resolve('promise 1');
        }, 200);
      });
    
      let promise2 = new Promise(function(resolve, reject){
        setTimeout(function(){
          resolve('promise 2');
        }, 100);
      });
    
      Promise.race([promise1, promise2]).then(function(result){
        // result === 'promise 2' because it was resolved before promise1
        // was resolved.
      });
      ```
    
      `Promise.race` is deterministic in that only the state of the first
      settled promise matters. For example, even if other promises given to the
      `promises` array argument are resolved, but the first settled promise has
      become rejected before the other promises became fulfilled, the returned
      promise will become rejected:
    
      ```javascript
      let promise1 = new Promise(function(resolve, reject){
        setTimeout(function(){
          resolve('promise 1');
        }, 200);
      });
    
      let promise2 = new Promise(function(resolve, reject){
        setTimeout(function(){
          reject(new Error('promise 2'));
        }, 100);
      });
    
      Promise.race([promise1, promise2]).then(function(result){
        // Code here never runs
      }, function(reason){
        // reason.message === 'promise 2' because promise 2 became rejected before
        // promise 1 became fulfilled
      });
      ```
    
      An example real-world use case is implementing timeouts:
    
      ```javascript
      Promise.race([ajax('foo.json'), timeout(5000)])
      ```
    
      @method race
      @static
      @param {Array} promises array of promises to observe
      Useful for tooling.
      @return {Promise} a promise which settles in the same way as the first passed
      promise to settle.
    */
    function race(entries) {
      /*jshint validthis:true */
      var Constructor = this;
    
      if (!isArray(entries)) {
        return new Constructor(function (_, reject) {
          return reject(new TypeError('You must pass an array to race.'));
        });
      } else {
        return new Constructor(function (resolve, reject) {
          var length = entries.length;
          for (var i = 0; i < length; i++) {
            Constructor.resolve(entries[i]).then(resolve, reject);
          }
        });
      }
    }
    
    /**
      `Promise.reject` returns a promise rejected with the passed `reason`.
      It is shorthand for the following:
    
      ```javascript
      let promise = new Promise(function(resolve, reject){
        reject(new Error('WHOOPS'));
      });
    
      promise.then(function(value){
        // Code here doesn't run because the promise is rejected!
      }, function(reason){
        // reason.message === 'WHOOPS'
      });
      ```
    
      Instead of writing the above, your code now simply becomes the following:
    
      ```javascript
      let promise = Promise.reject(new Error('WHOOPS'));
    
      promise.then(function(value){
        // Code here doesn't run because the promise is rejected!
      }, function(reason){
        // reason.message === 'WHOOPS'
      });
      ```
    
      @method reject
      @static
      @param {Any} reason value that the returned promise will be rejected with.
      Useful for tooling.
      @return {Promise} a promise rejected with the given `reason`.
    */
    function reject$1(reason) {
      /*jshint validthis:true */
      var Constructor = this;
      var promise = new Constructor(noop);
      reject(promise, reason);
      return promise;
    }
    
    function needsResolver() {
      throw new TypeError('You must pass a resolver function as the first argument to the promise constructor');
    }
    
    function needsNew() {
      throw new TypeError("Failed to construct 'Promise': Please use the 'new' operator, this object constructor cannot be called as a function.");
    }
    
    /**
      Promise objects represent the eventual result of an asynchronous operation. The
      primary way of interacting with a promise is through its `then` method, which
      registers callbacks to receive either a promise's eventual value or the reason
      why the promise cannot be fulfilled.
    
      Terminology
      -----------
    
      - `promise` is an object or function with a `then` method whose behavior conforms to this specification.
      - `thenable` is an object or function that defines a `then` method.
      - `value` is any legal JavaScript value (including undefined, a thenable, or a promise).
      - `exception` is a value that is thrown using the throw statement.
      - `reason` is a value that indicates why a promise was rejected.
      - `settled` the final resting state of a promise, fulfilled or rejected.
    
      A promise can be in one of three states: pending, fulfilled, or rejected.
    
      Promises that are fulfilled have a fulfillment value and are in the fulfilled
      state.  Promises that are rejected have a rejection reason and are in the
      rejected state.  A fulfillment value is never a thenable.
    
      Promises can also be said to *resolve* a value.  If this value is also a
      promise, then the original promise's settled state will match the value's
      settled state.  So a promise that *resolves* a promise that rejects will
      itself reject, and a promise that *resolves* a promise that fulfills will
      itself fulfill.
    
    
      Basic Usage:
      ------------
    
      ```js
      let promise = new Promise(function(resolve, reject) {
        // on success
        resolve(value);
    
        // on failure
        reject(reason);
      });
    
      promise.then(function(value) {
        // on fulfillment
      }, function(reason) {
        // on rejection
      });
      ```
    
      Advanced Usage:
      ---------------
    
      Promises shine when abstracting away asynchronous interactions such as
      `XMLHttpRequest`s.
    
      ```js
      function getJSON(url) {
        return new Promise(function(resolve, reject){
          let xhr = new XMLHttpRequest();
    
          xhr.open('GET', url);
          xhr.onreadystatechange = handler;
          xhr.responseType = 'json';
          xhr.setRequestHeader('Accept', 'application/json');
          xhr.send();
    
          function handler() {
            if (this.readyState === this.DONE) {
              if (this.status === 200) {
                resolve(this.response);
              } else {
                reject(new Error('getJSON: `' + url + '` failed with status: [' + this.status + ']'));
              }
            }
          };
        });
      }
    
      getJSON('/posts.json').then(function(json) {
        // on fulfillment
      }, function(reason) {
        // on rejection
      });
      ```
    
      Unlike callbacks, promises are great composable primitives.
    
      ```js
      Promise.all([
        getJSON('/posts'),
        getJSON('/comments')
      ]).then(function(values){
        values[0] // => postsJSON
        values[1] // => commentsJSON
    
        return values;
      });
      ```
    
      @class Promise
      @param {Function} resolver
      Useful for tooling.
      @constructor
    */
    
    var Promise$2 = function () {
      function Promise(resolver) {
        this[PROMISE_ID] = nextId();
        this._result = this._state = undefined;
        this._subscribers = [];
    
        if (noop !== resolver) {
          typeof resolver !== 'function' && needsResolver();
          this instanceof Promise ? initializePromise(this, resolver) : needsNew();
        }
      }
    
      /**
      The primary way of interacting with a promise is through its `then` method,
      which registers callbacks to receive either a promise's eventual value or the
      reason why the promise cannot be fulfilled.
       ```js
      findUser().then(function(user){
        // user is available
      }, function(reason){
        // user is unavailable, and you are given the reason why
      });
      ```
       Chaining
      --------
       The return value of `then` is itself a promise.  This second, 'downstream'
      promise is resolved with the return value of the first promise's fulfillment
      or rejection handler, or rejected if the handler throws an exception.
       ```js
      findUser().then(function (user) {
        return user.name;
      }, function (reason) {
        return 'default name';
      }).then(function (userName) {
        // If `findUser` fulfilled, `userName` will be the user's name, otherwise it
        // will be `'default name'`
      });
       findUser().then(function (user) {
        throw new Error('Found user, but still unhappy');
      }, function (reason) {
        throw new Error('`findUser` rejected and we're unhappy');
      }).then(function (value) {
        // never reached
      }, function (reason) {
        // if `findUser` fulfilled, `reason` will be 'Found user, but still unhappy'.
        // If `findUser` rejected, `reason` will be '`findUser` rejected and we're unhappy'.
      });
      ```
      If the downstream promise does not specify a rejection handler, rejection reasons will be propagated further downstream.
       ```js
      findUser().then(function (user) {
        throw new PedagogicalException('Upstream error');
      }).then(function (value) {
        // never reached
      }).then(function (value) {
        // never reached
      }, function (reason) {
        // The `PedgagocialException` is propagated all the way down to here
      });
      ```
       Assimilation
      ------------
       Sometimes the value you want to propagate to a downstream promise can only be
      retrieved asynchronously. This can be achieved by returning a promise in the
      fulfillment or rejection handler. The downstream promise will then be pending
      until the returned promise is settled. This is called *assimilation*.
       ```js
      findUser().then(function (user) {
        return findCommentsByAuthor(user);
      }).then(function (comments) {
        // The user's comments are now available
      });
      ```
       If the assimliated promise rejects, then the downstream promise will also reject.
       ```js
      findUser().then(function (user) {
        return findCommentsByAuthor(user);
      }).then(function (comments) {
        // If `findCommentsByAuthor` fulfills, we'll have the value here
      }, function (reason) {
        // If `findCommentsByAuthor` rejects, we'll have the reason here
      });
      ```
       Simple Example
      --------------
       Synchronous Example
       ```javascript
      let result;
       try {
        result = findResult();
        // success
      } catch(reason) {
        // failure
      }
      ```
       Errback Example
       ```js
      findResult(function(result, err){
        if (err) {
          // failure
        } else {
          // success
        }
      });
      ```
       Promise Example;
       ```javascript
      findResult().then(function(result){
        // success
      }, function(reason){
        // failure
      });
      ```
       Advanced Example
      --------------
       Synchronous Example
       ```javascript
      let author, books;
       try {
        author = findAuthor();
        books  = findBooksByAuthor(author);
        // success
      } catch(reason) {
        // failure
      }
      ```
       Errback Example
       ```js
       function foundBooks(books) {
       }
       function failure(reason) {
       }
       findAuthor(function(author, err){
        if (err) {
          failure(err);
          // failure
        } else {
          try {
            findBoooksByAuthor(author, function(books, err) {
              if (err) {
                failure(err);
              } else {
                try {
                  foundBooks(books);
                } catch(reason) {
                  failure(reason);
                }
              }
            });
          } catch(error) {
            failure(err);
          }
          // success
        }
      });
      ```
       Promise Example;
       ```javascript
      findAuthor().
        then(findBooksByAuthor).
        then(function(books){
          // found books
      }).catch(function(reason){
        // something went wrong
      });
      ```
       @method then
      @param {Function} onFulfilled
      @param {Function} onRejected
      Useful for tooling.
      @return {Promise}
      */
    
      /**
      `catch` is simply sugar for `then(undefined, onRejection)` which makes it the same
      as the catch block of a try/catch statement.
      ```js
      function findAuthor(){
      throw new Error('couldn't find that author');
      }
      // synchronous
      try {
      findAuthor();
      } catch(reason) {
      // something went wrong
      }
      // async with promises
      findAuthor().catch(function(reason){
      // something went wrong
      });
      ```
      @method catch
      @param {Function} onRejection
      Useful for tooling.
      @return {Promise}
      */
    
    
      Promise.prototype.catch = function _catch(onRejection) {
        return this.then(null, onRejection);
      };
    
      /**
        `finally` will be invoked regardless of the promise's fate just as native
        try/catch/finally behaves
      
        Synchronous example:
      
        ```js
        findAuthor() {
          if (Math.random() > 0.5) {
            throw new Error();
          }
          return new Author();
        }
      
        try {
          return findAuthor(); // succeed or fail
        } catch(error) {
          return findOtherAuther();
        } finally {
          // always runs
          // doesn't affect the return value
        }
        ```
      
        Asynchronous example:
      
        ```js
        findAuthor().catch(function(reason){
          return findOtherAuther();
        }).finally(function(){
          // author was either found, or not
        });
        ```
      
        @method finally
        @param {Function} callback
        @return {Promise}
      */
    
    
      Promise.prototype.finally = function _finally(callback) {
        var promise = this;
        var constructor = promise.constructor;
    
        if (isFunction(callback)) {
          return promise.then(function (value) {
            return constructor.resolve(callback()).then(function () {
              return value;
            });
          }, function (reason) {
            return constructor.resolve(callback()).then(function () {
              throw reason;
            });
          });
        }
    
        return promise.then(callback, callback);
      };
    
      return Promise;
    }();
    
    Promise$2.prototype.then = then;
    Promise$2.all = all;
    Promise$2.race = race;
    Promise$2.resolve = resolve$1;
    Promise$2.reject = reject$1;
    Promise$2._setScheduler = setScheduler;
    Promise$2._setAsap = setAsap;
    Promise$2._asap = asap;
    
    /*global self*/
    function polyfill() {
      var local = void 0;
    
      if (typeof global !== 'undefined') {
        local = global;
      } else if (typeof self !== 'undefined') {
        local = self;
      } else {
        try {
          local = Function('return this')();
        } catch (e) {
          throw new Error('polyfill failed because global object is unavailable in this environment');
        }
      }
    
      var P = local.Promise;
    
      if (P) {
        var promiseToString = null;
        try {
          promiseToString = Object.prototype.toString.call(P.resolve());
        } catch (e) {
          // silently ignored
        }
    
        if (promiseToString === '[object Promise]' && !P.cast) {
          return;
        }
      }
    
      local.Promise = Promise$2;
    }
    
    // Strange compat..
    Promise$2.polyfill = polyfill;
    Promise$2.Promise = Promise$2;
    
    Promise$2.polyfill();
    
    return Promise$2;
    
    })));
}());

// XXX strftime
//
// strftime
// github.com/samsonjs/strftime
// @_sjs
//
// Copyright 2010 - 2013 Sami Samhuri <sami@samhuri.net>
//
// MIT License
// http://sjs.mit-license.org
//
;(function()
{
  //// Where to export the API
  var namespace;

  // CommonJS / Node module
  if (typeof module !== 'undefined') {
    namespace = module.exports = strftime;
  }

  // Browsers and other environments
  else {
    // Get the global object. Works in ES3, ES5, and ES5 strict mode.
    namespace = (function(){ return this || (1,eval)('this') }());
  }

  function words(s) { return (s || '').split(' '); }

  var DefaultLocale =
  { days: words('Sunday Monday Tuesday Wednesday Thursday Friday Saturday')
  , shortDays: words('Sun Mon Tue Wed Thu Fri Sat')
  , months: words('January February March April May June July August September October November December')
  , shortMonths: words('Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec')
  , AM: 'AM'
  , PM: 'PM'
  , am: 'am'
  , pm: 'pm'
  };

  namespace.strftime = strftime;
  function strftime(fmt, d, locale) {
    return _strftime(fmt, d, locale);
  }

  // locale is optional
  namespace.strftimeTZ = strftime.strftimeTZ = strftimeTZ;
  function strftimeTZ(fmt, d, locale, timezone) {
    if ((typeof locale == 'number' || typeof locale == 'string') && timezone == null) {
      timezone = locale;
      locale = undefined;
    }
    return _strftime(fmt, d, locale, { timezone: timezone });
  }

  namespace.strftimeUTC = strftime.strftimeUTC = strftimeUTC;
  function strftimeUTC(fmt, d, locale) {
    return _strftime(fmt, d, locale, { utc: true });
  }

  namespace.localizedStrftime = strftime.localizedStrftime = localizedStrftime;
  function localizedStrftime(locale) {
    return function(fmt, d, options) {
      return strftime(fmt, d, locale, options);
    };
  }

  // d, locale, and options are optional, but you can't leave
  // holes in the argument list. If you pass options you have to pass
  // in all the preceding args as well.
  //
  // options:
  //   - locale   [object] an object with the same structure as DefaultLocale
  //   - timezone [number] timezone offset in minutes from GMT
  function _strftime(fmt, d, locale, options) {
    options = options || {};

    // d and locale are optional so check if d is really the locale
    if (d && !quacksLikeDate(d)) {
      locale = d;
      d = undefined;
    }
    d = d || new Date();

    locale = locale || DefaultLocale;
    locale.formats = locale.formats || {};

    // Hang on to this Unix timestamp because we might mess with it directly below.
    var timestamp = d.getTime();

    var tz = options.timezone;
    var tzType = typeof tz;

    if (options.utc || tzType == 'number' || tzType == 'string') {
      d = dateToUTC(d);
    }

    if (tz) {
      // ISO 8601 format timezone string, [-+]HHMM
      //
      // Convert to the number of minutes and it'll be applied to the date below.
      if (tzType == 'string') {
        var sign = tz[0] == '-' ? -1 : 1;
        var hours = parseInt(tz.slice(1, 3), 10);
        var mins = parseInt(tz.slice(3, 5), 10);
        tz = sign * ((60 * hours) + mins);
      }

      if (tzType) {
        d = new Date(d.getTime() + (tz * 60000));
      }
    }

    // Most of the specifiers supported by C's strftime, and some from Ruby.
    // Some other syntax extensions from Ruby are supported: %-, %_, and %0
    // to pad with nothing, space, or zero (respectively).
    return fmt.replace(/%([-_0]?.)/g, function(_, c) {
      var mod, padding;

      if (c.length == 2) {
        mod = c[0];
        // omit padding
        if (mod == '-') {
          padding = '';
        }
        // pad with space
        else if (mod == '_') {
          padding = ' ';
        }
        // pad with zero
        else if (mod == '0') {
          padding = '0';
        }
        else {
          // unrecognized, return the format
          return _;
        }
        c = c[1];
      }

      switch (c) {

        // Examples for new Date(0) in GMT

        // 'Thursday'
        case 'A': return locale.days[d.getDay()];

        // 'Thu'
        case 'a': return locale.shortDays[d.getDay()];

        // 'January'
        case 'B': return locale.months[d.getMonth()];

        // 'Jan'
        case 'b': return locale.shortMonths[d.getMonth()];

        // '19'
        case 'C': return pad(Math.floor(d.getFullYear() / 100), padding);

        // '01/01/70'
        case 'D': return _strftime(locale.formats.D || '%m/%d/%y', d, locale);

        // '01'
        case 'd': return pad(d.getDate(), padding);

        // '01'
        case 'e': return pad(d.getDate(), padding == null ? ' ' : padding);

        // '1970-01-01'
        case 'F': return _strftime(locale.formats.F || '%Y-%m-%d', d, locale);

        // '00'
        case 'H': return pad(d.getHours(), padding);

        // 'Jan'
        case 'h': return locale.shortMonths[d.getMonth()];

        // '12'
        case 'I': return pad(hours12(d), padding);

        // '000'
        case 'j':
          var y = new Date(d.getFullYear(), 0, 1);
          var day = Math.ceil((d.getTime() - y.getTime()) / (1000 * 60 * 60 * 24));
          return pad(day, 3);

        // ' 0'
        case 'k': return pad(d.getHours(), padding == null ? ' ' : padding);

        // '000'
        case 'L': return pad(Math.floor(timestamp % 1000), 3);

        // '12'
        case 'l': return pad(hours12(d), padding == null ? ' ' : padding);

        // '00'
        case 'M': return pad(d.getMinutes(), padding);

        // '01'
        case 'm': return pad(d.getMonth() + 1, padding);

        // '\n'
        case 'n': return '\n';

        // '1st'
        case 'o': return String(d.getDate()) + ordinal(d.getDate());

        // 'am'
        case 'P': return d.getHours() < 12 ? locale.am : locale.pm;

        // 'AM'
        case 'p': return d.getHours() < 12 ? locale.AM : locale.PM;

        // '00:00'
        case 'R': return _strftime(locale.formats.R || '%H:%M', d, locale);

        // '12:00:00 AM'
        case 'r': return _strftime(locale.formats.r || '%I:%M:%S %p', d, locale);

        // '00'
        case 'S': return pad(d.getSeconds(), padding);

        // '0'
        case 's': return Math.floor(timestamp / 1000);

        // '00:00:00'
        case 'T': return _strftime(locale.formats.T || '%H:%M:%S', d, locale);

        // '\t'
        case 't': return '\t';

        // '00'
        case 'U': return pad(weekNumber(d, 'sunday'), padding);

        // '4'
        case 'u':
          var day = d.getDay();
          return day == 0 ? 7 : day; // 1 - 7, Monday is first day of the week

        // ' 1-Jan-1970'
        case 'v': return _strftime(locale.formats.v || '%e-%b-%Y', d, locale);

        // '00'
        case 'W': return pad(weekNumber(d, 'monday'), padding);

        // '4'
        case 'w': return d.getDay(); // 0 - 6, Sunday is first day of the week

        // '1970'
        case 'Y': return d.getFullYear();

        // '70'
        case 'y':
          var y = String(d.getFullYear());
          return y.slice(y.length - 2);

        // 'GMT'
        case 'Z':
          if (options.utc) {
            return "GMT";
          }
          else {
            var tzString = d.toString().match(/\(([\w\s]+)\)/);
            return tzString && tzString[1] || '';
          }

        // '+0000'
        case 'z':
          if (options.utc) {
            return "+0000";
          }
          else {
            var off = typeof tz == 'number' ? tz : -d.getTimezoneOffset();
            return (off < 0 ? '-' : '+') + pad(Math.floor(Math.abs(off) / 60)) + pad(Math.abs(off) % 60);
          }
        
        // XXX 2018-10-20: Added by Jacques to get miliseconds
        case 'Q': return d.getMilliseconds();
        
        default: return c;
      }
    });
  }

  function dateToUTC(d) {
    var msDelta = (d.getTimezoneOffset() || 0) * 60000;
    return new Date(d.getTime() + msDelta);
  }

  var RequiredDateMethods = ['getTime', 'getTimezoneOffset', 'getDay', 'getDate', 'getMonth', 'getFullYear', 'getYear', 'getHours', 'getMinutes', 'getSeconds'];
  function quacksLikeDate(x) {
    var i = 0
      , n = RequiredDateMethods.length
      ;
    for (i = 0; i < n; ++i) {
      if (typeof x[RequiredDateMethods[i]] != 'function') {
        return false;
      }
    }
    return true;
  }

  // Default padding is '0' and default length is 2, both are optional.
  function pad(n, padding, length) {
    // pad(n, <length>)
    if (typeof padding === 'number') {
      length = padding;
      padding = '0';
    }

    // Defaults handle pad(n) and pad(n, <padding>)
    if (padding == null) {
      padding = '0';
    }
    length = length || 2;

    var s = String(n);
    // padding may be an empty string, don't loop forever if it is
    if (padding) {
      while (s.length < length) s = padding + s;
    }
    return s;
  }

  function hours12(d) {
    var hour = d.getHours();
    if (hour == 0) hour = 12;
    else if (hour > 12) hour -= 12;
    return hour;
  }

  // Get the ordinal suffix for a number: st, nd, rd, or th
  function ordinal(n) {
    var i = n % 10
      , ii = n % 100
      ;
    if ((ii >= 11 && ii <= 13) || i === 0 || i >= 4) {
      return 'th';
    }
    switch (i) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
    }
  }

  // firstWeekday: 'sunday' or 'monday', default is 'sunday'
  //
  // Pilfered & ported from Ruby's strftime implementation.
  function weekNumber(d, firstWeekday) {
    firstWeekday = firstWeekday || 'sunday';

    // This works by shifting the weekday back by one day if we
    // are treating Monday as the first day of the week.
    var wday = d.getDay();
    if (firstWeekday == 'monday') {
      if (wday == 0) // Sunday
        wday = 6;
      else
        wday--;
    }
    var firstDayOfYear = new Date(d.getFullYear(), 0, 1)
      , yday = (d - firstDayOfYear) / 86400000
      , weekNum = (yday + 7 - wday) / 7
      ;
    return Math.floor(weekNum);
  }
}());

// XXX sprintf
;(function()
{
/**
 * JavaScript printf/sprintf functions.
 * http://hexmen.com/blog/2007/03/printf-sprintf/
 *
 * This code is unrestricted: you are free to use it however you like.
 * 
 * The functions should work as expected, performing left or right alignment,
 * truncating strings, outputting numbers with a required precision etc.
 *
 * For complex cases these functions follow the Perl implementations of
 * (s)printf, allowing arguments to be passed out-of-order, and to set
 * precision and output-length from other argument
 *
 * See http://perldoc.perl.org/functions/sprintf.html for more information.
 *
 * Implemented flags:
 *
 * - zero or space-padding (default: space)
 *     sprintf("%4d", 3) ->  "   3"
 *     sprintf("%04d", 3) -> "0003"
 *
 * - left and right-alignment (default: right)
 *     sprintf("%3s", "a") ->  "  a"
 *     sprintf("%-3s", "b") -> "b  "
 *
 * - out of order arguments (good for templates & message formats)
 *     sprintf("Estimate: %2$d units total: %1$.2f total", total, quantity)
 *
 * - binary, octal and hex prefixes (default: none)
 *     sprintf("%b", 13) ->    "1101"
 *     sprintf("%#b", 13) ->   "0b1101"
 *     sprintf("%#06x", 13) -> "0x000d"
 *
 * - positive number prefix (default: none)
 *     sprintf("%d", 3) -> "3"
 *     sprintf("%+d", 3) -> "+3"
 *     sprintf("% d", 3) -> " 3"
 *
 * - min/max width (with truncation); e.g. "%9.3s" and "%-9.3s"
 *     sprintf("%5s", "catfish") ->    "catfish"
 *     sprintf("%.5s", "catfish") ->   "catfi"
 *     sprintf("%5.3s", "catfish") ->  "  cat"
 *     sprintf("%-5.3s", "catfish") -> "cat  "
 *
 * - precision (see note below); e.g. "%.2f"
 *     sprintf("%.3f", 2.1) ->     "2.100"
 *     sprintf("%.3e", 2.1) ->     "2.100e+0"
 *     sprintf("%.3g", 2.1) ->     "2.10"
 *     sprintf("%.3p", 2.1) ->     "2.1"
 *     sprintf("%.3p", '2.100') -> "2.10"
 *
 * Deviations from perl spec:
 * - %n suppresses an argument
 * - %p and %P act like %g, but without over-claiming accuracy:
 *   Compare:
 *     sprintf("%.3g", "2.1") -> "2.10"
 *     sprintf("%.3p", "2.1") -> "2.1"
 *
 * @version 2011.09.23
 * @author Ash Searle
 */
//// Where to export the API
var namespace;

// CommonJS / Node module
if (typeof module !== 'undefined') {
    namespace = module.exports = strftime;
}

// Browsers and other environments
else {
    // Get the global object. Works in ES3, ES5, and ES5 strict mode.
    namespace = (function(){ return this || (1,eval)('this') }());
}

namespace.sprintf = sprintf;
namespace.printf  = printf;
function sprintf() {
    function pad(str, len, chr, leftJustify) {
	var padding = (str.length >= len) ? '' : Array(1 + len - str.length >>> 0).join(chr);
	return leftJustify ? str + padding : padding + str;

    }

    function justify(value, prefix, leftJustify, minWidth, zeroPad) {
	var diff = minWidth - value.length;
	if (diff > 0) {
	    if (leftJustify || !zeroPad) {
		value = pad(value, minWidth, ' ', leftJustify);
	    } else {
		value = value.slice(0, prefix.length) + pad('', diff, '0', true) + value.slice(prefix.length);
	    }
	}
	return value;
    }

    var a = arguments, i = 0, format = a[i++];
    return format.replace(sprintf.regex, function(substring, valueIndex, flags, minWidth, _, precision, type) {
	    if (substring == '%%') return '%';

	    // parse flags
	    var leftJustify = false, positivePrefix = '', zeroPad = false, prefixBaseX = false;
	    for (var j = 0; flags && j < flags.length; j++) switch (flags.charAt(j)) {
		case ' ': positivePrefix = ' '; break;
		case '+': positivePrefix = '+'; break;
		case '-': leftJustify = true; break;
		case '0': zeroPad = true; break;
		case '#': prefixBaseX = true; break;
	    }

	    // parameters may be null, undefined, empty-string or real valued
	    // we want to ignore null, undefined and empty-string values

	    if (!minWidth) {
		minWidth = 0;
	    } else if (minWidth == '*') {
		minWidth = +a[i++];
	    } else if (minWidth.charAt(0) == '*') {
		minWidth = +a[minWidth.slice(1, -1)];
	    } else {
		minWidth = +minWidth;
	    }

	    // Note: undocumented perl feature:
	    if (minWidth < 0) {
		minWidth = -minWidth;
		leftJustify = true;
	    }

	    if (!isFinite(minWidth)) {
		throw new Error('sprintf: (minimum-)width must be finite');
	    }

	    if (precision && precision.charAt(0) == '*') {
		precision = +a[(precision == '*') ? i++ : precision.slice(1, -1)];
		if (precision < 0) {
		    precision = null;
		}
	    }

	    if (precision == null) {
		precision = 'fFeE'.indexOf(type) > -1 ? 6 : (type == 'd') ? 0 : void(0);
	    } else {
		precision = +precision;
	    }

	    // grab value using valueIndex if required?
	    var value = valueIndex ? a[valueIndex.slice(0, -1)] : a[i++];
	    var prefix, base;

	    switch (type) {
		case 'c': value = String.fromCharCode(+value);
		case 's': {
			      // If you'd rather treat nulls as empty-strings, uncomment next line:
			      // if (value == null) return '';

			      value = String(value);
			      if (precision != null) {
				  value = value.slice(0, precision);
			      }
			      prefix = '';
			      break;
			  }
		case 'b': base = 2; break;
		case 'o': base = 8; break;
		case 'u': base = 10; break;
		case 'x': case 'X': base = 16; break;
		case 'i':
		case 'd': {
			      var number = parseInt(+value);
			      if (isNaN(number)) {
				  return '';
			      }
			      prefix = number < 0 ? '-' : positivePrefix;
			      value = prefix + pad(String(Math.abs(number)), precision, '0', false);
			      break;
			  }
		case 'e': case 'E':
		case 'f': case 'F':
		case 'g': case 'G':
		case 'p': case 'P':
		          {
			      var number = +value;
			      if (isNaN(number)) {
				  return '';
			      }
			      prefix = number < 0 ? '-' : positivePrefix;
			      var method;
			      if ('p' != type.toLowerCase()) {
				  method = ['toExponential', 'toFixed', 'toPrecision']['efg'.indexOf(type.toLowerCase())];
			      } else {
				  // Count significant-figures, taking special-care of zeroes ('0' vs '0.00' etc.)
				  var sf = String(value).replace(/[eE].*|[^\d]/g, '');
				  sf = (number ? sf.replace(/^0+/,'') : sf).length;
				  precision = precision ? Math.min(precision, sf) : precision;
				  method = (!precision || precision <= sf) ? 'toPrecision' : 'toExponential';
			      }
			      var number_str = Math.abs(number)[method](precision);
			      // number_str = thousandSeparation ? thousand_separate(number_str): number_str;
			      value = prefix + number_str;
			      break;
			  }
		case 'n': return '';
		default: return substring;
	    }

	    if (base) {
		// cast to non-negative integer:
		var number = value >>> 0;
		prefix = prefixBaseX && base != 10 && number && ['0b', '0', '0x'][base >> 3] || '';
		value = prefix + pad(number.toString(base), precision || 0, '0', false);
	    }
	    var justified = justify(value, prefix, leftJustify, minWidth, zeroPad);
	    return ('EFGPX'.indexOf(type) > -1) ? justified.toUpperCase() : justified;
    });
}
sprintf.regex = /%%|%(\d+\$)?([-+#0 ]*)(\*\d+\$|\*|\d+)?(\.(\*\d+\$|\*|\d+))?([scboxXuidfegpEGP])/g;

/**
 * Trival printf implementation, probably only useful during page-load.
 * Note: you may as well use "document.write(sprintf(....))" directly
 */
function printf() {
    // delegate the work to sprintf in an IE5 friendly manner:
    var i = 0, a = arguments, args = Array(arguments.length);
    while (i < args.length) args[i] = 'a[' + (i++) + ']';
    document.write(eval('sprintf(' + args + ')'));
}
}());

/* Simple JavaScript Inheritance
 * By John Resig https://johnresig.com/blog/simple-javascript-inheritance/
 * MIT Licensed.
 */
// Inspired by base2 and Prototype
// Modified by Jacques Deguest on 2021-04-06 to enable hash like init parameters and 
// to allow class wide variables or functions using the special prefix "_"
// This is inspired from SO <https://stackoverflow.com/questions/11172801/static-variables-with-john-resigs-simple-class-pattern>
// Added special __class__ to set the class level and object level className property, inspired by:
// <https://github.com/pointofpresence/js-inherit>
// XXX POBaseClass
(function()
{
    /**
     * RegExp to match *( ";" parameter ) in RFC 7231 sec 3.1.1.1
     *
     * parameter     = token "=" ( token / quoted-string )
     * token         = 1*tchar
     * tchar         = "!" / "#" / "$" / "%" / "&" / "'" / "*"
     *               / "+" / "-" / "." / "^" / "_" / "`" / "|" / "~"
     *               / DIGIT / ALPHA
     *               ; any VCHAR, except delimiters
     * quoted-string = DQUOTE *( qdtext / quoted-pair ) DQUOTE
     * qdtext        = HTAB / SP / %x21 / %x23-5B / %x5D-7E / obs-text
     * obs-text      = %x80-FF
     * quoted-pair   = "\" ( HTAB / SP / VCHAR / obs-text )
     */
    // eslint-disable-line no-control-regex
    var PARAM_REGEXP = /; *([!#$%&'*+.^_`|~0-9A-Za-z-]+) *= *("(?:[\u000b\u0020\u0021\u0023-\u005b\u005d-\u007e\u0080-\u00ff]|\\[\u000b\u0020-\u00ff])*"|[!#$%&'*+.^_`|~0-9A-Za-z-]+) */g;
    
    /**
     * RegExp to match quoted-pair in RFC 7230 sec 3.2.6
     *
     * quoted-pair = "\" ( HTAB / SP / VCHAR / obs-text )
     * obs-text    = %x80-FF
     */
    // eslint-disable-line no-control-regex
    var QESC_REGEXP = /\\([\u000b\u0020-\u00ff])/g;

    /**
     * RegExp to match chars that must be quoted-pair in RFC 7230 sec 3.2.6
     */
    var QUOTE_REGEXP = /([\\"])/g;
    /**
     * RegExp to match type in RFC 7231 sec 3.1.1.1
     *
     * media-type = type "/" subtype
     * type       = token
     * subtype    = token
     */
    var TYPE_REGEXP  = /^[!#$%&'*+.^_`|~0-9A-Za-z-]+\/[!#$%&'*+.^_`|~0-9A-Za-z-]+$/;
    var TOKEN_REGEXP = /^[!#$%&'*+.^_`|~0-9A-Za-z-]+$/;
    var TEXT_REGEXP  = /^[\u000b\u0020-\u007e\u0080-\u00ff]+$/;
    
    var LOCALE_REGEXP = /^[a-z]{2}((?:[_-][A-Z]{2})(?:\.[\w-]+)?)?$/;

    var initializing = false, fnTest = /xyz/.test(function(){xyz;}) ? /\b_super\b/ : /.*/;

    // The base POBaseClass implementation (does nothing)
    this.POBaseClass = function(){};

    this.POBaseClass.prototype.isA = function(className)
    {
        if( !this.hasOwnProperty('className') )
        {
            return false;
        }
        return this.className === className;
    };

    // Create a new POBaseClass that inherits from this class
    POBaseClass.extend = function(prop)
    {
        var _super = this.prototype;

        // Dummy class constructor
        initializing = true;
        function POBaseClass()
        {
            // Initialize only if not currently in the process of initializing another object (avoid infinite loop)
            if( !initializing && this.init )
            {
                this.init.apply(this, arguments);
            }
        };
        initializing = false;

        // Inherit from this class
        POBaseClass.prototype = Object.create(this.prototype);
        POBaseClass.prototype.constructor = POBaseClass;

        // Copy the properties over onto the new prototype
        for( var name in prop ) 
        {
            // Check if we're overwriting an existing function
            if( typeof prop[name] == "function" &&
                typeof _super[name] == "function" &&
                fnTest.test(prop[name]) )
            {
                POBaseClass.prototype[name] = (function(name, fn)
                {
                    return function() 
                    {
                        var tmp = this._super;

                        // Add a new ._super() method that is the same method
                        // but on the super-class
                        this._super = _super[name];

                        // The method only need to be bound temporarily, so we
                        // remove it when we're done executing
                        var ret = fn.apply(this, arguments);        
                        this._super = tmp;
                        return ret;
                    };
                })(name, prop[name]);
            }
            else if( name == '__class__' )
            {
                POBaseClass.prototype.className = prop[name];
            }
            else if( name.substr(0, 1) == '_' )
            {
                POBaseClass[ name.substr(1) ] = prop[name];
            }
            else
            {
                POBaseClass.prototype[name] = prop[name];
            }
        }

        // And make this class extendable
        POBaseClass.extend = arguments.callee;

        return POBaseClass;
    };

    if( !window.URI )
    {
        (function()
        {
            (function(global)
            {
                'use strict';
    
                // Define the URI class
                /*
                 * Instantiate a new URI object. All arguments are optional, and if none is provided, it defaults to window.location.href
                 *
                 * @throws TypeError
                 * @param {String}  relativePath    A relative or absolute path, including one starting with http
                 * @param {String}  base            An optional base URL to resolve the relative path provided as the first argument. Defaults to window.location.href
                 * @return {URI} Returns a new URI object
                 **/
                function URI(relativePath, base)
                {
                    if( !(this instanceof URI) )
                    {
                        throw new TypeError( "Class constructors must be invoked with 'new'" );
                    }
    
                    // Create a URL object
                    var tempURL;
                    if( !relativePath && !base )
                    {
                        base = window.location.href;
                        tempURL = new URL(window.location.href);
                    }
                    else
                    {
                        // Use 'window.location.href' as the default base
                        base = base || window.location.href;
                        tempURL = new URL(relativePath, base);
                    }
    
                    // Store the URL instance for internal reference
                    this._url = tempURL;
    
                    // Define property accessors for URL properties
                    var properties = ['href', 'protocol', 'host', 'hostname', 'port', 'pathname', 'search', 'hash', 'password', 'username'];
                    properties.forEach(function(prop)
                    {
                        Object.defineProperty(this, prop,
                        {
                            get: function()
                            {
                                return this._url[prop];
                            },
                            set: function(value)
                            {
                                this._url[prop] = value;
                            },
                            enumerable: true,
                            configurable: true
                        });
                    }, this);

                    // Make origin read-only
                    Object.defineProperty(this, 'origin',
                    {
                        get: function()
                        {
                            return this._url.origin;
                        },
                        set: function()
                        {
                            throw new Error( "The 'origin' property is read-only." );
                        },
                        enumerable: true,
                        configurable: true
                    });

                    // searchParams returns a URLSearchParams object
                    Object.defineProperty(this, 'searchParams',
                    {
                        get: function()
                        {
                            return this._url.searchParams;
                        },
                        enumerable: true,
                        configurable: true
                    });
                }
    
                // Inherit from URL.prototype
                URI.prototype = Object.create(URL.prototype);
    
                // Fix the constructor reference
                URI.prototype.constructor = URI;
    
                // Override the `toString` method to delegate to the URL instance
                URI.prototype.toString = function()
                {
                    return this._url.toString();
                };
    
                // Static methods
                URI.canParse = function(url, base)
                {
                    try
                    {
                        new URL(url, base);
                        return true;
                    }
                    catch(e)
                    {
                        return false;
                    }
                };
    
                // Note: createObjectURL and revokeObjectURL are methods of URL but relate to Blobs, not URL manipulation
                URI.createObjectURL = function(blob)
                {
                    return URL.createObjectURL(blob);
                };
    
                URI.revokeObjectURL = function(objectURL)
                {
                    URL.revokeObjectURL(objectURL);
                };
    
                URI.parse = function(url, base)
                {
                    return new URL(url, base);
                };
    
                // Instance method
                URI.prototype.toJSON = function()
                {
                    return this._url.toJSON();
                };
    
                // Credits: Grok (xAI)
                /*
                 * This takes an array of segments that will be added to the current object pathname.
                 * 
                 * @param {Array}   segments    One or more path segments to append to the object pathname
                 * @return {URI}    Returns the current URI object for chaining
                 **/
                URI.prototype.appendToPath = function()
                {
                    var segments = Array.prototype.slice.call(arguments, 0);
    
                    // Split path into segments, handling multiple slashes
                    var path = this._url.pathname.split( /\/{1,}/ );
    
                    // Append new segments
                    for( var i = 0; i < segments.length; i++ )
                    {
                        path.push(segments[i]);
                    }
    
                    // Reconstruct the path
                    this._url.pathname = path.join('/');
    
                    // Return this for method chaining
                    return this;
                };
    
                // Expose the URI class globally
                global.URI = URI;
            })(this);
        })();
    }

    /*
    See also <https://stackoverflow.com/a/33311143/4814971>
    to make private variables and class wide variables
    */

    // NOTE: POGenericClass class
    // NOTE: POGenericClass class
    window.POGenericClass = POBaseClass.extend(
    {
        __class__: "POGenericClass",
        
        init: function( opts )
        {
            var self = this;
            if( typeof( opts ) === 'undefined' )
            {
                opts = {};
            }
            if( opts.hasOwnProperty( 'debug' ) )
            {
                self.debug_level = parseInt( opts.debug );
                delete( opts.debug );
            }
            else if( opts.hasOwnProperty( 'debug_level' ) )
            {
                self.debug_level = parseInt( opts.debug_level );
                delete( opts.debug_level );
            }
            else if( settings.hasOwnProperty( 'DEBUG' ) )
            {
                if( window.DEBUG == true )
                {
                    self.debug_level = 1;
                }
                else if( Number.isInteger( settings.DEBUG ) )
                {
                    self.debug_level = settings.DEBUG;
                }
            }
            // self.debug = self.debug_level;
            // this._super( opts );
            var tmpParams = opts || {};
            Object.keys(tmpParams).forEach(function(key)
            {
                self[key] = tmpParams[key];
            });
            
            // For local storage and setSitePrefs() and getSitePrefs()
            self.ai_data = 'ai_data';
            // To contain cached data loaded from /public/l10n.json
            self.l10n = {};
            self.formatterCache = {};
            // this._super( opts );
        },

        /**
         * Logs a debug message to the console
         *
         * @param  {String} message  A debug message
         */
        debug: function()
        {
            var self = this;
            var args = Array.from(arguments);
            args.unshift( "debug" );
            this.log_console.apply( self, args );
        },

        /**
         * Logs an error to the console
         *
         * @param  {String} message  An error message
         */
        error: function()
        {
            var self = this;
            var args = Array.from(arguments);
            args.unshift( "error" );
            self.log.apply( self, args );
        },

        /**
         * Logs an info message to the console
         *
         * @param  {String} message  An info message
         */
        info: function()
        {
            var self = this;
            var args = Array.from(arguments);
            args.unshift( "info" );
            this.log_console.apply( self, args );
        },

        /**
         * Logs a message to the console
         *
         * @param  {String} message  A message
         */
        log: function()
        {
            var self = this;
            var args = Array.from(arguments);
            args.unshift( "log" );
            self.log_console.apply( self, args );
        },

        log_console: function()
        {
            var self = this;
            // console.log( "self.debug_level is " + self.debug_level + " and settings.DEBUG is " + settings.DEBUG  );
            var logType = "log";
            // Credits: https://stackoverflow.com/a/19790505/4814971
            var toPrint = [];
            for( var i = 0; i < arguments.length; ++i ) 
            {
                toPrint.push( arguments[i] );
            }
            // console.log( "toPrint contains: " + JSON.stringify( toPrint, null, 4 ) );
            // If we have more than one argument and our first one is a keyword, we use it to know how to log
            if( arguments.length > 1 &&
                typeof( toPrint[0] ) === "string" &&
                toPrint[0].match( /^(debug|error|info|log|trace|warn)$/ ) )
            {
                logType = toPrint.shift();
            }
            if( !self.debug_level && logType !== 'error' )
            {
                return(false);
            }
            var callerFuncName = '';
            if( arguments.callee.caller !== null )
            {
                var callerFunc = arguments.callee.caller.toString();
                callerFuncName = (callerFunc.substring( callerFunc.indexOf( 'function' ) + 8, callerFunc.indexOf( '(' ) ) || 'anoynmous');
            }
            var logData = {};
            var stackString = (new Error()).stack;
            stackString = stackString.replace( /[\n\r]+$/g, '' );
            logData.stackTrace = stackString;
            var stackLines = stackString.split( "\n" );
            var stackTrace = [];
            for( var i = 0; i < stackLines.length; i++ )
            {
                var def = {};
                var line = stackLines[i];
                // console.log( "Checking line '" + line + "'" );
                var chunk = line.split( "@" );
                var functionInfo = chunk[0];
                var locationInfo = chunk[1];
                var matches = [];
                // http://legal-server.test/js/jquery-1.11.2.min.js line 2 > eval:749:4
                if( ( matches = locationInfo.match( /^(\S+)\s+line\s\d+\s+>\s+eval\:(\d+):(\d+)$/ ) ) !== null )
                {
                    def.url = matches[1];
                    def.file = def.url.split( '/' ).slice(-1)[0];
                    def.eval = true;
                    def.line = matches[2];
                    def.col = matches[3];
                }
                // http://legal-server.test/js/desktop.js:502:38
                else if( ( matches = locationInfo.match( /^(.*?):(\d+):(\d+)$/ ) ) !== null )
                {
                    def.url = matches[1];
                    def.file = def.url.split( '/' ).slice(-1)[0];
                    def.line = matches[2];
                    def.col = matches[3];
                    // con.log( `Found url ${def.url} file ${def.file} line ${def.line} and col ${def.col}` );
                }
                else
                {
                    console.info( "Location no match for: '" + locationInfo + "'" );
                }
                // LegalTech</ui.legalTechProgressBar
                // LegalTech/this.init/</<
                // window.Account</ui.log
                // send
                def.object = null;
                def.method = null;
                if( ( matches = functionInfo.match( /^([a-zA-Z0-9_\.]+)[\<\/]+([a-zA-Z0-9\._]+)/ ) ) !== null )
                {
                    def.object = matches[1];
                    def.method = matches[2];
                }
                // success/</<
                // $.fn.changeMenu
                else if( ( matches = functionInfo.match( /^(\$?[a-zA-Z0-9_\.]+)/ ) ) !== null )
                {
                    def.method = matches[1];
                }
                else
                {
                    // con.log( "Function no match for: '" + functionInfo + "'" );
                }
                stackTrace.push( def );
            }
            // console.info( "stackTrace result is: " + JSON.stringify( stackTrace, null, 4 ) );
            /*
            var index = caller_line.indexOf( 'at ' );
            var clean = caller_line.slice( index + 2, caller_line.length );
            */
            // log.apply( null, arguments );
            logData.message = toPrint.join( '' );
            var isSprintf = false;
            if( typeof( toPrint[0] ) !== 'undefined' )
            {
                var testPrintf = new String( toPrint[0] );
                if( testPrintf.indexOf( '%o' ) != -1 ||
                    testPrintf.indexOf( '%O' ) != -1 ||
                    testPrintf.indexOf( '%d' ) != -1 ||
                    testPrintf.indexOf( '%i' ) != -1 ||
                    testPrintf.indexOf( '%.' ) != -1 ||
                    testPrintf.indexOf( '%f' ) != -1 ||
                    testPrintf.indexOf( '%.f' ) != -1 ||
                    testPrintf.indexOf( '%s' ) != -1 )
                {
                    isSprintf = true;
                }
            }
            
            // offset 0 is our own function ui.log, so we check for our caller at offset 1
            var j = 1;
            var ref = stackTrace[j];
            // console.log( "Checking method '" + ref.method + "'" );
            if( ( ref.method === 'debug' || ref.method === 'error' || ref.method === 'log' || ref.method === 'trace' || ref.method === 'warn' ) && ( j + 1 ) < stackTrace.length )
            {
                var def = stackTrace[j+1];
                if( def.object !== null && def.object.length > 0 )
                {
                    var thisObject = def.object;
                    if( thisObject.match( /^window\./ ) ) thisObject = def.object.split( "." )[1];
                    toPrint.unshift( sprintf( '{%s} %s -> %s%s[%d]: ', thisObject, def.method, def.file, (def.eval ? "(eval)" : ""), def.line ) );
                    logData.app = null;
                    if( thisObject.hasOwnProperty( 'resources' ) )
                    {
                        logData.app = thisObject.resources.name;
                    }
                }
                else
                {
                    toPrint.unshift( sprintf( '%s -> %s%s[%d]: ', def.method, def.file, (def.eval ? "(eval)" : ""), def.line ) );
                }
                // logData.location = sprintf( '%s -> %s%s', def.url, def.method, (def.eval ? "(eval)" : "") );
                logData.location = def.url;
                logData.line = def.line;
                logData.col = def.col;
                logData.method = def.method || '(eval)';
                // break;
            }
            toPrint.unshift( strftime( '%Y-%m-%d %H:%M:%S.%Q ', (new Date()).getTime() ) );
            var logFunction = console.log;
            if( typeof( logType ) === 'string' )
            {
                logFunction = eval( "console." + logType );
            }
            logFunction.apply( null, toPrint );
        },

        /**
         * Logs a trace to the console
         *
         * @param  {String} message  A trace message
         */
        trace: function()
        {
            var self = this;
            var args = Array.from(arguments);
            args.unshift( "trace" );
            this.log_console.apply( self, args );
        },

        /**
         * Logs a warning to the console
         *
         * @param  {String} message  A warning message
         */
        warn: function()
        {
            var self = this;
            var args = Array.from(arguments);
            args.unshift( "warn" );
            this.log_console.apply( self, args );
        },

        /**
         * Returns the latest error, or an empty string if there is none.
         *
         * @return {String} Returns an error string.
         */
        getError: function()
        {
            return( typeof( this._error ) === 'undefined' ? '' : this._error );
        },

        /**
         * Checks if there is an error set.
         *
         * @return {Boolean} Returns true if an error was set, or false otherwise.
         */
        hasError: function()
        {
            return( this._error.length > 0 );
        },

        /**
         * Sets an error, and makes it available both in the object, and as a global 'ERROR' variable.
         *
         * @param {Object} Either an object, or an array of text string to concatenate.
         *
         * @return {Void}
         */
        setError: function()
        {
            var self = this;
            var args = Array.from(arguments);
            this._error = ( typeof( args[0] ) === 'object' && args.length == 1 ) ? args[0] : args.join( '' );
            self.error( this._error );
            var className = window[ this.className ];
            className['ERROR'] = this._error;
            return;
        }
    });

    /*
    NOTE: GettextString class inheriting from String
    The purpose is to return an instance of GettextString class that automatically stringifies when necessary and that contains the string locale (a.k.a. language) property.
    The string locale property is set upon fetching the localised version, and is useful to know what locale (a.k.a. language) it actually is, especially when it failed to find any localised version.
    */
    window.GettextString = function(str,locale)
    {
        this._value = str;
        this.locale = locale;
        var self = this;
        Object.defineProperty(this, 'length', 
        {
            get: function()
            {
                return( self._value.length );
            },
            // writable: false,
            configurable: false,
            enumerable: true
        });
    };

    Object.getOwnPropertyNames(String.prototype).forEach(function(key)
    {
        var func = String.prototype[key];
        GettextString.prototype[key] = function()
        {
            return func.apply(this._value, arguments);
        };
    });
    
    GettextString.prototype.setLocale = function(locale)
    {
        this.locale = locale;
    };

    GettextString.prototype.getLocale = function()
    {
        return(this.locale);
    };
    
    GettextString.prototype.setLang = function(locale)
    {
        this.locale = locale;
    };

    GettextString.prototype.getLang = function()
    {
        return(this.locale);
    };

    // NOTE: Gettext class
    window.Gettext = window.POGenericClass.extend(
    {
        __class__: "Gettext",
        _L10N: {},
        // new PO({ domain: "com.example.api", path: "/some/where", locale: "ja_JP" })
        /**
         * Creates and returns a new Gettext instance.
         *
         * @example
         *      var po = new Gettext({ domain: "com.example.api", locale: "ja_JP", directory: "/locale" });
         * 
         * @constructor
         * @param  {Object}  [options]             A set of options
         * @param  {String}  options.sourceLocale  The locale that the source code and its
         *                                         texts are written in. Translations for
         *                                         this locale is not necessary.
         * @param  {Boolean} options.debug         Whether to output debug info into the
         *                                         console.
         * @return {Object}  A Gettext instance
         */
        init: function( opts )
        {
            var self = this;
            opts = opts || {};
            this.domain = null;
            this.category = null;
            if( opts.hasOwnProperty( 'debug' ) )
            {
                opts.debug_level = opts.debug;
                delete( opts.debug );
            }
            if( opts.hasOwnProperty( 'useCategory' ) )
            {
                if( opts.useCategory ) opts.category = 'LC_MESSAGES';
                delete( opts.useCategory );
            }
            else if( !opts.hasOwnProperty( 'useCategory' ) )
            {
                opts.category = 'LC_MESSAGES';
            }
            /*
            This is the root path beneath which should be the repository of the data:
            en_GB/com.example.api.json
            fr_FR/com.example.api.json
            ja_JP/com.example.api.json
            No need for the LC_MESSAGE directory, which, under web context, is meaningless
            Thus, if this.path was set to '/locale', we would resolve the full path to:
            /locale/en_GB/com.example.api.json
            */
            this.path    = null;
            this.locale  = (typeof( document ) !== 'undefined' ? document.documentElement.getAttribute('lang') : false) || 'en';
            this._super( opts );
            self.debug( "domain is: ", this.domain );
            self.debug( "Category value is: " + this.category );
            self.debug( "Initiating object." );

            this.isReady = false;
            this.hasLoadError = false;
            this.supported_languages = [];

            if( typeof( self.domain ) === 'undefined' || self.domain == null )
            {
                throw new Error( "No domain was provided for localisation" );
            }
            else if( !this.domain.match( /^[a-z]+(\.[a-zA-Z0-9\_\-]+)*$/ ) )
            {
                throw new Error( "Domain provided \"" + this.domain + "\" contains illegal characters." );
            }
            if( typeof( this.path ) === 'undefined' || this.path === null )
            {
                throw new Error( "No directory path was provided for localisation" );
            }
            if( typeof( this.locale ) === 'undefined' || this.locale === null )
            {
                throw new Error( "No language was set." );
            }
            // else if( !this.locale.match( /^[a-z]{2}(?:[_-][A-Z]{2}(?:\.[\w-]+)?)?$/ ) )
            else if( !this.locale.match( LOCALE_REGEXP ) )
            {
                throw new Error( "Language provided (\"" + this.locale + "\") is in an unsupported format. Use something like \"en_GB\", \"en-GB\" or simply \"en\" or even \"en_GB.utf-8\"." );
            }

            this.locale = this.locale.replace( '-', '_' );
            this.path = new URI( this.path );
            this.plural = [];
            window.Gettext.L10N = window.Gettext.L10N || {};

            // Start loading data but don't wait for it here
            this._initPromise = this.setTextDomain( this.domain ).then(function( hash )
            {
                self.debug( "setTextDomain() returned: \"" + JSON.stringify( hash, null, 4 ) + "\"." );
                if( typeof( hash ) === 'undefined' )
                {
                    throw self.getError();
                }
                self.isReady = true;
                return(self);
            }).catch(function( error )
            {
                self.hasLoadError = true;
                self.setError( error );
            });

            // Check if promise return is requested
            if( opts && opts.promise )
            {
                return this._initPromise;
            }

            // Return this for backward compatibility
            return( this );
        },

        /**
         * Translates a string using the default textdomain
         *
         * @example
         *     po.gettext('Some text')
         *
         * @param  {String} msgid  String to be translated
         * @return {String} Translation or the original string if no translation was found
         */
        gettext: function(msgid)
        {
            return( this.dngettext( this.domain, msgid ) );
        },

        /**
         * Given an original string, this return the sprintf formatted localised equivalent
         *
         * @example
         *     p.gettext( "Hello %s, welcome to %s", "Jacques", "Tokyo”, etc... )
         *
         * @param  {String} msgid      String to be translated
         * @param  {Array}  parameters List of parameters passed to sprintf
         * @return {String} Localised formatted string
         */
        gettextf: function()
        {
            var self = this;
            var args = Array.from(arguments);
            var thisText = self.dngettext( self.domain, args.shift() );
            args.unshift( thisText );
            return( new GettextString( sprintf.apply( null, args ), self.locale ) );
        },

        /**
         * Translates a string using a specific domain
         *
         * @example
         *     po.dgettext('domainname', 'Some text')
         *
         * @param  {String} domain  A gettext domain name
         * @param  {String} msgid   String to be translated
         * @return {String} Translation or the original string if no translation was found
         */
        dgettext: function(domain, msgid)
        {
            return( this.dngettext( domain, msgid ) );
        },

        /**
         * Translates a plural string using the default textdomain
         *
         * @example
         *     po.ngettext('One thing', 'Many things', numberOfThings)
         *
         * @param  {String} msgid        String to be translated when count is not plural
         * @param  {String} msgidPlural  String to be translated when count is plural
         * @param  {Number} count        Number count for the plural
         * @return {String} Translation or the original string if no translation was found
         */
        ngettext: function(msgid, msgidPlural, count)
        {
            return( this.dngettext(this.domain, msgid, msgidPlural, count) );
        },

        /**
         * Translates a plural string using a specific textdomain
         *
         * @example
         *     po.dngettext('domainname', 'One thing', 'Many things', numberOfThings)
         *
         * @param  {String} domain       A gettext domain name
         * @param  {String} msgid        String to be translated when count is not plural
         * @param  {String} msgidPlural  String to be translated when count is plural
         * @param  {Number} count        Number count for the plural
         * @param  {Object} opts         An optional hash of parameters
         * @return {String} Translation or the original string if no translation was found
         */
        dngettext: function(domain, msgid, msgidPlural, count)
        {
            var self = this;
            // Force stringification of object, if any.
            msgid = msgid + "";
            var defaultTranslation = msgid;
            var index;
            var args = Array.prototype.slice.call(arguments);
            if( typeof( args[ args.length - 1 ] ) === 'object' )
            {
                opts = args.pop();
            }
            else
            {
                opts = {};
            }

            if( !isNaN(count) && count !== 1 )
            {
                defaultTranslation = msgidPlural || msgid;
            }
            if( !opts.hasOwnProperty( 'locale' ) )
            {
                opts.locale = self.locale;
            }
            
            self.debug( "Fetching data has for domain \"" + domain + "\". and for locale \"" + opts.locale + "\", and for msgid '" + msgid + "'" );
            var data = self.getDomainHash({ domain: domain });
            var plural = self.plural;
            if( !data.hasOwnProperty( opts.locale ) )
            {
                this.warn( "No locale \"" + opts.locale + "\" found for the domain \"" + domain + "\"." );
                return( new GettextString( defaultTranslation ) );
            }
            self.debug( "Data for domain \"" + domain + "\" contains " + Object.keys( data[ opts.locale ] ).length + " elements." );
            if( data[ opts.locale ].hasOwnProperty(msgid) )
            {
                self.debug( "Plural is: " + JSON.stringify( plural ) );
                if( plural.length == 0 )
                {
                    plural = self.getPlural();
                }
                if( Array.isArray( data[ opts.locale ][msgid].msgstr ) )
                {
                    self.debug( "msgid localised value is a plural aware text -> " + JSON.stringify( data[ opts.locale ][msgid].msgstr ) );
                    if( typeof( count ) === 'number' &&
                        parseInt( plural[0] ) > 0 )
                    {
                        var n = count;
                        index = eval( plural[1] );
                        if( typeof( index ) === 'boolean' )
                        {
                            index = index ? 1 : 0;
                        }
                    }
                    else
                    {
                        index = 0;
                    }
                    self.debug( "Count is \"" + count + "\" and plural offset computed is " + index );
                    return data[ opts.locale ][msgid].msgstr[index]
                        ? new GettextString( data[ opts.locale ][msgid].msgstr[index], opts.locale )
                        : self.sourceLocale
                            ? new GettextString( defaultTranslation, self.sourceLocale )
                            : new GettextString( defaultTranslation );
                }
                return data[ opts.locale ][msgid].msgstr
                    ? new GettextString( data[ opts.locale ][msgid].msgstr, opts.locale )
                    : self.sourceLocale
                        ? new GettextString( defaultTranslation, self.sourceLocale )
                        : new GettextString( defaultTranslation );
            }
            else if( !self.sourceLocale || opts.locale !== self.sourceLocale )
            {
                self.warn( 'No dictionary was found for msgid "' + msgid + '" and domain "' + domain + '"' );
                // self.info( JSON.stringify( data[ opts.locale ], null, 4 ) );
            }
            return self.sourceLocale ? new GettextString( defaultTranslation, self.sourceLocale ) : new GettextString( defaultTranslation );
        },

        /**
         * Provided with a locale, a msgid and its localised content, this will add it to the dictionary for this domain
         *
         * @example
         *     po.addItem( locale, key, value )
         *
         * @param  {String} locale      Locale value, such as en_US, or ja
         * @param  {String} msgid       The original text used as the key
         * @param  {String} msgstr      The localised content
         * @return {Object} Hash of msgid-msgstr pair added
         */
        addItem: function( locale, key, value )
        {
            var self = this;
            var hash = self.getDomainHash();
            locale = locale.replace( '-', '_' );
            if( !self.isSupportedLanguage( locale ) )
            {
                throw new Error( "Language requested \"" + locale + "\" to add item is not supported." );
            }
            if( typeof( key ) === 'undefined' || key === null )
            {
                throw new Error( "Key provided to add data to language \"" + locale + "\" is undefined or null" );
            }
            hash[ locale ][ key ] = { msgid: key, msgstr: value };
            return( hash[ locale ][ key ] );
        },

        /**
         * Returns the content type used in the po or mo file.
         *
         * @example
         *      var type = po.contentType();
         *
         * @return {String} A string such as "text/plain; charset=utf-8" or maybe just "text/plain"
         */
        charset: function()
        {
            var self = this;
            var type = self.contentType();
            var def  = self.parseHeaderValue( type );
            return( def.params.charset );
        },

        /**
         * Returns the encoding used in the po or mo file.
         *
         * @example
         *      var encoding = po.contentEncoding();
         *
         * @return {String} A string such as "8bit"
         */
        contentEncoding: function() { return( this.getMetaValue( 'Content-Transfer-Encoding' ) ); },

        /**
         * Returns the content type used in the po or mo file.
         *
         * @example
         *      var type = po.contentType();
         *
         * @return {String} A string such as "text/plain; charset=utf-8" or maybe just "text/plain"
         */
        contentType: function() { return( this.getMetaValue( 'Content-Type' ) ); },

        /**
         * Read-only method that returns the current language in effet, i.e.
         *
         * @example
         *     po.addItem( locale, key, value )
         *
         * @return {String} Locale value set such as: <html lang="fr-FR">
         */
        currentLang: function()
        {
            this.debug( "Returning '" + document.getElementsByTagName('html')[0].getAttribute('lang') + "'." );
            return( document.getElementsByTagName('html')[0].getAttribute('lang') );
        },

        /**
         * Checks if a given locale exists, i.e. has been loaded already in the domain data
         *
         * @example
         *     po.exists( "fr-FR" ); // Using fr_FR works too
         *
         * @param  {String}  locale      Locale value, such as en_US, or ja
         * @return {Boolean} True if it exists or false otherwise
         */
        exists: function( lang )
        {
            var self = this;
            if( typeof( lang ) === 'undefined' )
            {
                throw new Error( "No language to check for existence was provided." );
            }
            else if( lang == null )
            {
                throw new Error( "Language provided to check for existence is null." );
            }
            else if( !lang.match( LOCALE_REGEXP ) )
            {
                throw new Error( "Unsupported locale format \"" + lang + "\"." );
            }
            lang = lang.replace( '-', '_' );
            var hash = self.getDomainHash();
            return( hash.hasOwnProperty( lang ) );
        },

        /**
         * Get an array of <span> html element each for one language and its related localised content
         *
         * @example
         *     p.fetchLocale( "Hello!" )
         *     // Returns:
         *     // <span lang="de-DE">Grüß Gott!</span>
         *     // <span lang="fr-FR">Salut !</span>
         *     // <span lang="ja-JP">今日は！</span>
         *     // <span lang="ko-KR">안녕하세요!</span>
         *
         * @param  {String} Text  The original text (a msgid)
         * @return {Array} An array of span html elements
         */
        fetchLocale: function(key)
        {
            var self = this;
            var hash = self.getDomainHash();
            var spans = [];
            // Browsing through each available locale language
            // Make it predictable using sort()
            Object.keys(hash).sort().forEach(function(k, index)
            {
                var locWeb = k.replace( '_', '-' );
                spans.push( '<span lang="' + locWeb + '">' + self.dngettext( self.domain, key, { locale: k }) + '</span>' );
            });
            return( spans );
        },

        /**
         * Get an array of <span> html element each for one language and its related localised content depending on whether there is one or more than one elements
         *
         * @example
         *     p.fetchLocalen( "%d person", "%d persons", 2 )
         *     // Returns:
         *     // <span lang="de-DE">2 Personen</span>
         *     // <span lang="fr-FR">2 personnes</span>
         *     // <span lang="ja-JP">2人</span>
         *     // <span lang="ko-KR">2명</span>
         *
         * @param  {String} msgid        String to be translated when count is not plural
         * @param  {String} msgidPlural  String to be translated when count is plural
         * @param  {Number} count        Number count for the plural
         * @return {Array} An array of span html elements
         */
        fetchLocalen: function(key, plural, count)
        {
            var self = this;
            if( arguments.length < 3 )
            {
                throw new Error( "Missing argument. fetchLocalen( key, plural, count )" );
            }
            var args = Array.from(arguments);
            args.splice(0,3);
            
            var hash = self.getDomainHash();
            var spans = [];
            // Browsing through each available locale language
            // Make it predictable using sort()
            Object.keys(hash).sort().forEach(function(k, index)
            {
                var locWeb = k.replace( '_', '-' );
                self.log( "Fetching localised text for singular '" + key + "', plural '" + plural + "' with count '" + count + "' and locale '" + k + "'" );
                var text = self.dngettext( self.domain, key, plural, count, { locale: k });
                self.log( "Text found is '" + text + "'" );
                // Clone
                var params = args.slice();
                params.unshift( text );
                if( params.length == 1 )
                {
                    params.push( count );
                }
                self.log( "Params to sprintf are: " + JSON.stringify( params, null, 4 ) );
                spans.push( '<span lang="' + locWeb + '">' + sprintf.apply( null, params ) + '</span>' );
            });
            return( spans );
        },

        // Ref: <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise#Example_using_new_XMLHttpRequest()>
        /**
         * Performs an http query
         *
         * @example
         *     p.getData({ url: "https://example.com/locale/en_GB/com.example.api.json", method: "GET" })
         *
         * @param  {Object} options       Hash of options
         * @return {Object} A promise object
         */
        getData: function( opts )
        {
            var self = this;
            return new Promise(function(resolve, reject)
            {
                // default parameters are only available in ES6
                if( typeof( opts ) === 'undefined' )
                {
                    opts = {};
                }

                if( !opts.hasOwnProperty( 'url' ) )
                {
                    reject( new Error( "No \"url\" options was provided." ) );
                }
                else if( typeof( opts.url ) === 'undefined' || opts.url.length == 0 )
                {
                    reject( new Error( "\"url\" option provided is empty." ) );
                }

                if( !opts.hasOwnProperty( 'method' ) )
                {
                    reject( new Error( "No \"method\" options was provided." ) );
                }
                else if( typeof( opts.method ) === 'undefined' || opts.method.length == 0 )
                {
                    reject( new Error( "\"method\" option provided is empty." ) );
                }

                var url = new URI( opts.url );
                var thisLoc = new URI();

                if( !opts.hasOwnProperty( 'async' ) )
                {
                    opts.async = true;
                }
                self.debug( "async is set to " + opts.async );
                if( !opts.hasOwnProperty( 'headers' ) )
                {
                    opts.headers = {};
                    opts.headers['Content-Type'] = 'application/json';
                }

                if( thisLoc.protocol == 'file:' )
                {
                    reject( new Error( "You need to load the test html file from an http server and not as a file://. You can use python3 -m http.server or python -m SimpleHTTPServer" ) );
                }

                var data, xhr;
                if( ( xhr = self.getXhrObject() ) )
                {
                    xhr.onload = function()
                    {
                        /* Status is 0 for local file URL loading. */
                        if( this.status == 0 || ( this.status >= 200 && this.status < 400 ) )
                        {
                            self.debug( "HTTP response code is: '" + this.status + "'." );
                            // resolve(xhr.response);
                            data = eval( '(' + xhr.responseText  + ')');
                            resolve(data);
                        }
                        else
                        {
                            reject( new Error( "Unable to get data from uri \"" + opts.url + "\": (" + this.status + ") " + xhr.statusText ) );
                        }
                    };
                    xhr.onerror = function()
                    {
                        reject( new Error( "Unable to load data from uri \"" + opts.url + "\": (" + this.status + ") " + xhr.statusText ) );
                    };

                    xhr.open(opts.method, opts.url, opts.async);
                    if( opts.responseType )
                    {
                        // e.g. arraybuffer to load .mo files
                        xhr.responseType = opts.responseType;
                    }
                    else
                    {
                        xhr.setRequestHeader( "Accept", "application/json" );
                    }
                    if( opts.headers )
                    {
                        Object.keys(opts.headers).forEach(function(key)
                        {
                            xhr.setRequestHeader(key, opts.headers[key]);
                        });
                    }

                    // xhr.setRequestHeader( "Content-Type", "application/json" );
                    var params = opts.params;
                    if( params && typeof params === 'object' )
                    {
                        params = Object.keys(params).map(function(key)
                        {
                            return( encodeURIComponent(key) + '=' + encodeURIComponent(params[key]) );
                        }).join('&');
                        xhr.send(params);
                    }
                    else
                    {
                        xhr.send(null);
                    }
                }
            });
        },

        // example: <link rel="gettext" href="/local" />
        /**
         * Return the uri path of the localised content found in <rel> html tag if any
         *
         * @example
         *     p.getDataPath()
         *
         * @return {String} URI path to localised content
         */
        getDataPath: function()
        {
            var links = document.getElementsByTagName( 'link' );
            for( var i = 0, l = links.length; i < l; i++ )
            {
                var link = links[i];
                if( link.getAttribute( 'rel' ) == 'gettext' && !link.hasAttribute( 'lang' ) )
                {
                    return( link.getAttribute( 'href' ) );
                }
            }
            return;
        },

        /**
         * Returns an array reference containing the 7 days of the week in their long representation.
         *
         * @example
         *     p.getDaysLong()
         *
         * @return {Array} Array of weekdays
         */
        getDaysLong: function()
        {
            var self = this;
            var days = [];
            var locale = self.locale.replace( '_', '-' );
            for( var i = 0; i < 12; i++ )
            {
                days.push( new Date(0,i).toLocaleString( locale, { weekday: "long" }) );
            }
            return( days );
        },

        /**
         * Returns an array reference containing the 7 days of the week in their short representation.
         *
         * @example
         *     p.getDaysShort()
         *
         * @return {Array} Array of weekdays
         */
        getDaysShort: function()
        {
            var self = this;
            var days = [];
            var locale = self.locale.replace( '_', '-' );
            for( var i = 0; i < 12; i++ )
            {
                days.push( new Date(0,i).toLocaleString( locale, { weekday: "short" }) );
            }
            return( days );
        },

        /**
         * Get the hash of all elements for a given domain
         *
         * @example
         *     p.getDomainHash( "com.example.api" )
         *
         * @param  {String} Domain  The domain key
         * @return {Object} An hash of locale-hash pairs. Each hash contains a msgid-hash pair
         */
        getDomainHash: function( opts )
        {
            var self = this;
            if( typeof( opts ) === 'undefined' )
            {
                opts = {};
            }
            else if( typeof( opts ) !== 'object' )
            {
                throw new Error( "Parameter provide must be an hash of option parameters." );
            }

            opts.domain = opts.domain || this.domain;

            var hash = window.Gettext.L10N;
            if( !hash.hasOwnProperty( opts.domain ) )
            {
                throw new Error( "No locale data for domain \"" + opts.domain + "\"." );
            }
            if( opts.hasOwnProperty( 'locale' ) && 
                typeof( opts.locale ) !== 'undefined' )
            {
                opts.locale = opts.locale.replace( '-', '_' );
                self.debug( "Returning domain hash for domain \"" + opts.domain + "\" and locale \"" + opts.locale + "\" -> " + JSON.stringify( hash[ opts.domain ], null, 4 ) );
                if( opts.locale.length == 0 )
                {
                    throw new Error( "Locale was provided, but is empty." );
                }
                return( hash[ opts.domain ][ opts.locale ] );
            }
            // self.debug( "Returning domain hash -> " + JSON.stringify( hash[ opts.domain ] ) );
            return( hash[ opts.domain ] );
        },

        // example: <link rel="gettext" lang="ja_JP" href="/locale/ja_JP" />
        /**
         * Return the uri path to localised content for a given language (a.k.a. locale) found in a <rel> html tag if any.
         *
         * @example
         *     p.getLangDataPath( locale )
         *
         * @param  {String} locale       A string representing the language to query
         * @return {String} URI path to localised content for the given locale
         */
        getLangDataPath: function(lang)
        {
            if( typeof( lang ) !== 'string' )
            {
                throw new Error( "Local provided (" + lang + ") is not a string" );
            }
            else if( !lang.match( LOCALE_REGEXP ) )
            {
                throw new Error( "Local provided (" + lang + ") is of an unsupported format." );
            }

            lang = lang.replace( '_', '-' );

            var links = document.getElementsByTagName( 'link' );
            for( var i = 0, l = links.length; i < l; i++ )
            {
                var link = links[i];
                if( link.getAttribute( 'rel' ) == 'gettext' && link.getAttribute( 'lang' ) == lang )
                {
                    return( link.getAttribute( 'href' ) );
                }
            }
            return;
        },
        /**
         * Get the hash of all elements for a given locale (a.k.a. language)
         *
         * @example
         *     p.getLanguageDict( "fr-FR" )
         *
         * @param  {String} Locale    Language string
         * @return {Object} An hash of msgid-hash pairs. Each hash contains a msgid and msgstr properties
         */
        getLanguageDict: function( lang )
        {
            var self = this;
            if( typeof( lang ) === 'undefined' || lang === null )
            {
                throw new Error( "Language provided, to get its dictionary, is undefined or null." );
            }
            else if( !lang.match( LOCALE_REGEXP ) )
            {
                throw new Error( "Locale provided (" + lang + ") is in an unsupported format." );
            }
            lang = lang.replace( '-', '_' );
            
            if( !self.isSupportedLanguage( lang ) )
            {
                throw new Error( "Language provided (" + lang + "), to get its dictionary, is unsupported." );
            }
            var hash = self.getDomainHash();
            if( !hash.hasOwnProperty( lang ) )
            {
                throw new Error( "Language provided (" + lang + "), to get its dictionary, could not be found. This is weird. Most likely a configuration mistake." );
            }
            return( hash[ lang ] );
        },

        /**
         * Get the locale to get translated messages for.
         *
         * @example
         *     po.getLocale()
         *
         * @param {String} locale  A locale
         */
        getLocale: function()
        {
            var locale = this.locale.replace( '_', '-' );
            return( locale );
        },

        /**
         * Get a list of localised string in a <span> with each a lang attribute and return an array
         *
         * @example
         *     p.getLocales( "Hello!" )
         *
         * @param  {String} Text       Original string
         * @return {String} Localised string of <span> html elements each with its lang attribute
         */
        getLocales: function(key)
        {
            var self = this;
            var res = self.fetchLocale(key);
            if( res.length > 0 )
            {
                return( res.join( "\n" ) );
            }
            else
            {
                return(key);
            }
        },

        /**
         * Get a list of localised string in a <span> and format each of them using sprintf
         *
         * @example
         *     p.getLocalesf( "Hello!" )
         *
         * @param  {String} Text       Original string
         * @return {String} String of <span> elements each with its localised content and lang attribute
         */
        getLocalesf: function()
        {
            var self = this;
            var args = Array.from(arguments);
            // First argument is the locale key string
            var thisKey = args.shift();
            // var res = self.fetchLocale( thisKey );
            var res = self.fetchLocale(arguments);
            if( res.length > 0 )
            {
                for( var i=0; i<res.length; i++ )
                {
                    // This does not work
                    //res[i] = sprintf( res[i], args );
                    // This does not work either
                    //res[i] = sprintf.apply( this, args );
                    // But this did !
                    // Ref: https://developer.mozilla.org/fr/docs/Web/JavaScript/Reference/Op%C3%A9rateurs/Syntaxe_d%C3%A9composition#A_better_apply
                    // https://stackoverflow.com/a/2856069/4814971
                    // ...args not supported on older browsers
                    // res[i] = sprintf( res[i], ...args );
                    var j = 0, args2 = Array(args.length);
                    while( j < args2.length ) 
                    {
                        args2[j] = args[j];
                        j++;
                    }
                    args2.unshift( res[i] );
                    res[i] = sprintf.apply( null, args2 );
                }
                return( res.join( "\n" ) );
            }
            else
            {
                return( sprintf( thisKey, args ) );
            }
        },

        /**
         * Given a po meta field representing a date, and this will return a Date object representing its value
         *
         * @example
         *     po.getMetaDate( "PO-Revision-Date" );
         *
         * @param  {String} Field       PO meta field name
         * @return {Object} Date object representing the field value
         */
        getMetaDate: function(field)
        {
            var self = this;
            var meta = self.getMetaData();
            if( typeof( meta ) === 'undefined' )
            {
                return;
            }
            else if( !meta.hasOwnProperty( field ) )
            {
                return;
            }
            return( self.parseDateToObject( meta[ field ] ) );
        },

        /**
         * Takes no argument and return the hash of the po file meta information has field name-value pairs.
         *
         * @example
         *     po.getMetaData();
         *
         * @return {Object} Hash of the po file meta data
         */
        getMetaData: function()
        {
            var self = this;
            var hash = self.getDomainHash({ locale: self.locale });
            self.debug( "Domain hash found for locale \"" + self.locale + "\" is : " + JSON.stringify( hash, null, 4 ) );
            return( hash._meta );
        },

        /**
         * Takes no argument and return the array of the po file meta fields
         *
         * @example
         *     po.getMetaKeys();
         *
         * @return {Array} Array of meta fields
         */
        getMetaKeys: function()
        {
            var self = this;
            var hash = self.getDomainHash({ locale: self.locale });
            return( hash._meta_keys );
        },

        /**
         * Given a po meta field, and this will return its value
         *
         * @example
         *     po.getMetaValue( "Project-Id-Version" );
         *
         * @param  {String} Field       PO meta field name
         * @return {String} Meta field value
         */
        getMetaValue: function(field)
        {
            var self = this;
            var meta = self.getMetaData();
            return( meta[ field ] );
        },

        /**
         * Performs an http get query to get a .mo (machine object) data
         *
         * @example
         *     p.getMoData( URI )
         *
         * @param  {String} uri       An URI representing the location of the .mo file
         * @return {Object} A promise object
         */
        getMoData: function(uri)
        {
            if( !uri )
            {
                throw new Error( 'No uri was specified to load the .mo file.' );
            }
            // Returns a Promise
            return( this.getData({
                responseType: 'arraybuffer',
            }) );
        },

        // <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date/toLocaleDateString>
        /**
         * Returns an array reference containing the 12 months in their long representation.
         *
         * @example
         *     p.getMonthsLong()
         *
         * @return {Array} Array of months name
         */
        getMonthsLong: function()
        {
            var self = this;
            var months = [];
            var locale = self.locale.replace( '_', '-' );
            for( var i = 0; i < 12; i++ )
            {
                months.push( new Date(0,i).toLocaleString( locale, { month: "long" }) );
            }
            return( months );
        },

        /**
         * Returns an array reference containing the 12 months in their short representation.
         *
         * @example
         *     p.getMonthsShort()
         *
         * @return {Array} Array of months name
         */
        getMonthsShort: function()
        {
            var self = this;
            var months = [];
            var locale = self.locale.replace( '_', '-' );
            for( var i = 0; i < 12; i++ )
            {
                months.push( new Date(0,i).toLocaleString( locale, { month: "short" }) );
            }
            return( months );
        },

        /**
         * Returns an hash reference containing the following properties:
         *      - currency
         *      - decimal
         *      - int_currency
         *      - negative_sign
         *      - precision
         *      - thousand
         *
         * @example
         *     p.getNumericDict()
         *
         * @return {Object} Hash of properties
         */
        getNumericDict: function()
        {
            var self = this;
            var def  = {};
            var locale = self.locale.replace( '_', '-' );
            def.thousand = self._getSeparator( locale, 'group' );
            def.decimal  = self._getSeparator( locale, 'decimal' );
            return( def );
        },

        /**
         * Takes no arguments, and returns the value of the meta field "Plural-Forms"
         *
         * @example
         *     po.getPlural();
         *
         * @return {Array} An array with 2 entries; 0=number of plural forms, 1=the expression to evaluate the plurality to get the right offset value
         */
        getPlural: function()
        {
            var self = this;
            if( this.plural.length > 0 )
            {
                return( this.plural );
            }
            
            var meta = self.getMetaData();
            self.debug( "Meta data hash found for domain \"" + self.domain + "\" and locale \"" + self.locale + "\" is: " + JSON.stringify( meta ) );
            if( meta.hasOwnProperty( 'Plural-Forms' ) )
            {
                var pluralDef = meta[ 'Plural-Forms' ];
                var pluralDef_re = new RegExp('^\\s*nplurals\\s*=\\s*([0-9]+)\\s*;\\s*plural\\s*=\\s*(.*?)\;?$');
                if( pluralDef_re.test( pluralDef ) )
                {
                    var res = pluralDef.match(pluralDef_re);
                    this.plural = [res[1], res[2]];
                    return( this.plural );
                }
                else
                {
                    throw new Error( "Malformed plural definition found in po data in meta field \"Plural-Forms\": " + pluralDef );
                }
            }
            return( [] );
        },

        /**
         * Provided with an original text and an optional language (locale), this return the localised equivalent if any, or the original string by default.
         *
         * @example
         *     p.getText( "Hello !", "fr-FR" )
         *
         * @param  {Number} originalOffset       Original offset position
         * @param  {Number} translationOffset    Offset position for the translation
         * @return {Object} Hash of data with 1 id-str pair
         */
        getText: function( thisKey, thisLang )
        {
            var self = this;
            var l10n = self.getDomainHash();
            if( thisLang === null || typeof( thisLang ) === 'undefined' )
            {
                thisLang = document.getElementsByTagName('html')[0].getAttribute('lang');
            }
            thisLang = thisLang.replace( '-', '_' );
            // Force stringification if this is an object
            thisKey = thisKey + "";
            if( l10n.hasOwnProperty( thisLang ) )
            {
                if( l10n[ thisLang ].hasOwnProperty( thisKey ) )
                {
                    // return( l10n[ thisLang ][ thisKey ].msgstr );
                    return( new GettextString( l10n[ thisLang ][ thisKey ].msgstr, thisLang ) );
                }
            }
            // return( thisKey );
            return( new GettextString( thisKey ) );
        },

        /**
         * Given an original string, this return the sprintf formatted localised equivalent
         *
         * @example
         *     p.getTextf( "Hello %s, welcome to %s", "Jacques", "Tokyo”, etc..., { lang: "fr-FR" } )
         *
         * @param  {String} text       Original string
         * @param  {Array}  parameters List of parameters passed to sprintf
         * @param  {Object} options    Hash of options
         * @return {String} Localised formatted string
         */
        getTextf: function()
        {
            var self = this;
            var args = Array.from(arguments);
            var params = {};
            if( typeof( args.slice( -1 )[0] ) === 'object' )
            {
                params = args.pop();
            }
            if( !params.hasOwnProperty( 'lang' ) ) params.lang = document.getElementsByTagName('html')[0].getAttribute('lang');
            var thisKey = args.shift();
            params.lang = params.lang.replace( '-', '_' );
            //return( sprintf( getText( thisKey, params.lang ), ...args ) );
            var thisText = self.getText( thisKey, params.lang );
            var strLang = thisText.getLocale();
            args.unshift( thisText );
            // return( sprintf.apply( null, args ) );
            return( new GettextString( sprintf.apply( null, args ), strLang ) );
        },

        /**
         * Return the current domain used
         *
         * @example
         *     p.getTextDomain()
         *
         * @return {String} A domain, such as com.example.api
         */
        getTextDomain: function()
        {
            return( this.domain );
        },

        /**
         * Return a XMLHttpRequest object
         *
         * @example
         *     p.getXhrObject()
         *
         * @return {Object} A XMLHttpRequest object
         */
        // <https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest/Using_XMLHttpRequest>
        getXhrObject: function()
        {
            var self = this;
            if( window.XMLHttpRequest )
            {
                return( new XMLHttpRequest() );
            }
            
            // Not sure it is worth it to keep supporting IE
            if( window.ActiveXObject )
            {
                try
                {
                    return( new window.ActiveXObject( "Microsoft.XMLHTTP" ) );
                }
                catch(e)
                {
                    throw new Error( "Unable to get a XMLHttpRequest object." );
                }
            }
            return( null );
        },

        /**
         * Provided with a language (locale) and this returns true if it is supported or false otherwise
         *
         * @example
         *     p.isSupportedLanguage( locale )
         *
         * @param  {String} locale       A string representing a locale (a.k.a. language)
         * @return {Boolean} Returns true if supported or false otherwise
         */
        isSupportedLanguage: function( lang )
        {
            if( this.supported_languages.indexOf( lang ) )
            {
                return( true );
            }
            else
            {
                return( false );
            }
        },

        /**
         * Returns the value of the header Language. To get the locale currently in use in the po object, use getLocale()
         * 
         * @example
         *      p.language()
         *
         * @return {String} Returns a string containing the value of the header Language
         */
        language: function() { return( this.getMetaValue( 'Language' ) ); },

        /**
         * Returns the value of the header Language-Team.
         * 
         * @example
         *      p.languageTeam()
         *
         * @return {String} Returns a string containing the value of the header Language-Team
         */
        languageTeam: function() { return( this.getMetaValue( 'Language-Team' ) ); },

        /**
         * Returns the value of the header Last-Translator.
         * 
         * @example
         *      p.lastTranslator()
         *
         * @return {String} Returns a string containing the value of the header Last-Translator
         */
        lastTranslator: function() { return( this.getMetaValue( 'Last-Translator' ) ); },

        /**
         * Get remote po data based on options provided as hash
         *
         * @example
         *     po.loadDomainData({ domain: "com.example.api", locale: "fr-FR", path: "/locale", category: "LC_MESSAGES" });
         *
         * @param  {Object} options      An hash of options
         */
        loadDomainData: function(opts)
        {
            var self = this;
            opts = opts || {};
        
            opts.path     = ( opts.path || this.path );
            opts.locale   = ( opts.locale || this.locale );
            opts.domain   = ( opts.domain || this.domain );
            opts.category = ( opts.category || this.category );
            opts.locale   = opts.locale.replace('-','_');
        
            // var dataUri = opts.path + "/" + opts.locale + "/" + opts.domain + ".json";
            var dataUri = opts.path + "/" + opts.locale + "/" + ( ( typeof( opts.category ) === 'string' && opts.category.length > 0 ) ? opts.category + "/" : "" ) + opts.domain + ".json";
        
            return self.getData({ url: dataUri, method: "GET" }).then(function(data)
            {
                self.debug( "Data retrieved is: " + JSON.stringify( data, null, 4 ) );
                if( !data )
                {
                    throw new Error( "Invalid JSON data at " + dataUri );
                }
                else if( !data.elements )
                {
                    throw new Error( "Missing property \"elements\" in po json file at uri \"" + dataUri + "\"." );
                }
                else if( !data.meta )
                {
                    throw new Error( "Missing property \"meta\" in po json file at uri \"" + dataUri + "\"." );
                }
                else if( !data.meta_keys )
                {
                    throw new Error( "Missing property \"meta_keys\" in po json file at uri \"" + dataUri + "\"." );
                }
                else if( !Array.isArray(data.elements) )
                {
                    throw new Error( "Property elements found is not an array in po json file at uri \"" + dataUri + "\"." );
                }
                else if( !( typeof( data.meta ) === 'object' ) )
                {
                    throw new Error( "Property meta found is not an hash in po json file at uri \"" + dataUri + "\"." );
                }
                else if( !Array.isArray( data.meta_keys ) )
                {
                    throw new Error( "Property meta_keys found is not an array in po json file at uri \"" + dataUri + "\"." );
                }

                self.debug( "Successfully loaded data for domain \"" + opts.domain + "\" and locale \"" + opts.locale + "\"." );
                var hash = window.Gettext.L10N;

                if( !hash[opts.domain] ) hash[opts.domain] = {};
                if( !hash[opts.domain][opts.locale] ) hash[opts.domain][opts.locale] = {};

                self.debug( "Adding meta information from uri \"" + dataUri + "\" for domain \"" + opts.domain + "\" and locale \"" + opts.locale + "\": " + JSON.stringify( data.meta, null, 4 ) );
                hash[ opts.domain ][ opts.locale ]._meta = data.meta;
                hash[ opts.domain ][ opts.locale ]._meta_keys = data.meta_keys;
                self.debug( sprintf( "%d elements found for this JSON po.", data.elements.length ) );

                for( var i = 0; i < data.elements.length; i++ )
                {
                    var elem = data.elements[i];
                    if( !elem.msgid || !elem.msgstr )
                    {
                        console.warn( "Element at offset " + i + " is missing either a msgid or msgstr property at uri \"" + dataUri + "\"." );
                        return;
                    }
                    // Likely the meta information
                    else if( elem.msgid.length == 0 )
                    {
                        return;
                    }
                    self.debug( "Adding msgid \"" + elem.msgid + "\" -> \"" + JSON.stringify(elem) + "\"." );
                    hash[opts.domain][opts.locale][elem.msgid] = elem;
                }

                if( data.meta.hasOwnProperty( 'Plural-Forms' ) && data.meta['Plural-Forms'].length > 0 )
                {
                    self.debug( "Found plural value in meta: " + data.meta['Plural-Forms'] );
                    var pluralDef = data.meta["Plural-Forms"];
                    // Example (ru_RU): nplurals=3; plural=n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2
                    var pluralDef_re = new RegExp('^\\s*nplurals\\s*=\\s*([0-9]+)\\s*;\\s*plural\\s*=\\s*(.*?)\;?$');
                    if( pluralDef_re.test( pluralDef ) )
                    {
                        var res = pluralDef.match(pluralDef_re);
                        self.plural = [res[1], res[2]];
                        self.debug( "Set plural to: " + JSON.stringify( self.plural ) );
                    }
                    else
                    {
                        throw new Error( "Malformed plural definition found in po data at uri \"" + dataUri + "\" in meta field \"Plural-Forms\": " + pluralDef );
                    }
                }
                // Default
                else
                {
                    self.warn( "Unable to find the field \"Plural-Forms\" in header in file at \"" + dataUri + "\"." );
                    self.plural = [1,0];
                }
                window.Gettext.L10N = hash;
                self.isReady = true;
                return hash[opts.domain][opts.locale];
            }).catch(function(err)
            {
                self.hasLoadError = true;
                self.setError( new Error( "Failed to load localisation JSON data from uri \"" + dataUri + "\": " + err.message ) );
                throw err;
            });
        },

        /**
         * Returns the value of the header MIME-Version.
         * 
         * @example
         *      p.mimeVersion()
         *
         * @return {String} Returns a string containing the value of the header MIME-Version
         */
        mimeVersion: function() { return( this.getMetaValue( 'MIME-Version' ) ); },

        // 2019-10-03 19-44+0000
        // 2021-06-24 13:21+0100
        parseDateToObject: function(str)
        {
            var self = this;
            var re = /^(\d{4})\D(\d{1,2})\D(\d{1,2})[\s\t]+(\d{1,2})\D(\d{1,2})(?:\D(\d{1,2}))?([+-])(\d{2})(\d{2})$/;
            var matches = str.match( re );
            if( !matches || !matches.length )
            {
                throw new Error( "Date time string provided is unsupported: \"" + str + "\"." );
            }
            if( isNaN( matches[6] ) )
            {
                matches[6] = 0;
            }
            matches.shift();
            // self.debug( "Matches are -> " + JSON.stringify( matches ) );
            matches.unshift( '%02d-%02d-%02dT%02d:%02d:%02d%s%02d:%02d' );
            // self.debug( "Result would be -> " + sprintf.apply( null, matches ) );
            var d = new Date( sprintf.apply( null, matches ) );
            return( d );
        },

        /*
         * Credits: <https://github.com/jshttp/content-type>
         * Adapted by Jacques Deguest
         */
        /**
         * Parse header field value and breaks it down into attribute-value dictionary and returns an HeaderValue object
         *
         * @example
         *     po.parseHeaderValue( "text/plain; charset=utf-8" );
         *
         * @param  {Object} HeaderValue      Returns an HeaderValue object
         */
        parseHeaderValue: function(string)
        {
            var self = this;
            if( typeof( string ) !== 'string' ||
                string === null ||
                string.length == 0 )
            {
                throw new TypeError( 'Argument string is required' );
            }

            var index = string.indexOf( ';' );
            var type = index !== -1
                ? string.substr(0, index).trim()
                : string.trim();

            if( !TYPE_REGEXP.test(type) )
            {
                throw new TypeError( 'Invalid media type "' + type + '"' );
            }

            // Private class; see below
            var obj = new HeaderValue(type);

            // parse parameters
            if( index !== -1 )
            {
                var key;
                var match;
                var value;

                PARAM_REGEXP.lastIndex = index;

                while( ( match = PARAM_REGEXP.exec(string) ) )
                {
                    if( match.index !== index )
                    {
                        throw new TypeError( 'Invalid parameter format' );
                    }

                    index += match[0].length;
                    key = match[1].toLowerCase();
                    value = match[2];

                    if( value[0] === '"' )
                    {
                        // Remove quotes and escapes
                        value = value
                            .substr( 1, value.length - 2 )
                            .replace( QESC_REGEXP, '$1' );
                    }
                    obj.setParam( key, value );
                }

                if( index !== string.length )
                {
                    throw new TypeError( 'Invalid parameter format' );
                }
            }
            return( obj );
        },

        /**
         * Returns the value of the header Plural-Forms.
         * 
         * @example
         *      p.pluralForms()
         *
         * @return {String} Returns a string containing the value of the header Plural-Forms
         */
        pluralForms: function() { return( this.getMetaValue( 'Plural-Forms' ) ); },

        /**
         * Returns the value of the header PO-Revision-Date.
         * 
         * @example
         *      p.poRevisionDate()
         *
         * @return {String} Returns a string containing the value of the header PO-Revision-Date
         */
        poRevisionDate: function() { return( this.getMetaDate( 'PO-Revision-Date' ) ); },

        /**
         * Returns the value of the header POT-Creation-Date.
         * 
         * @example
         *      p.potCreationDate()
         *
         * @return {String} Returns a string containing the value of the header POT-Creation-Date
         */
        potCreationDate: function() { return( this.getMetaDate( 'POT-Creation-Date' ) ); },

        /**
         * Returns the value of the header Project-Id-Version.
         * 
         * @example
         *      p.projectIdVersions()
         *
         * @return {String} Returns a string containing the value of the header Project-Id-Version
         */
        projectIdVersion: function() { return( this.getMetaValue( 'Project-Id-Version' ) ); },

        /**
         * Provided with a callback function and this will execute once the data have been loaded
         * 
         * @example
         *      p.ready(function() { console.log( "Ok, ready!" ); })
         *
         */
        ready: function(callback, errCallback)
        {
            var self = this;
            // Return a Promise that ensures data is fully loaded and accessible
            // If we have a callback, use it as the promise's executor
            return new Promise(function(resolve, reject)
            {
                // Check if already ready
                if( self.isReady )
                {
                    if( typeof( callback ) === 'function' ) callback(self);
                    resolve(self);
                }
                // Check if an error occurred during initialization
                else if( self.hasLoadError )
                {
                    var error = self.getError();
                    if( typeof( errCallback ) === 'function' ) errCallback( error );
                    reject( error );
                }
                // Wait for the _initPromise to resolve or reject
                else
                {
                    self._initPromise.then(function()
                    {
                        if( !self.isReady ) // Ensure readiness
                        {
                            reject( new Error( "Translation data not available or incomplete for domain: " + self.domain + ", locale: " + self.locale ) );
                            return;
                        }

                        if( typeof( callback ) === 'function' ) callback(self);
                        resolve(self);
                    }).catch(function(error)
                    {
                        self.hasLoadError = true;
                        self.setError(error);
                        if( typeof( errCallback ) === 'function' ) errCallback(error);
                        reject(error);
                    });
                }
            });
        },

        /**
         * Returns the value of the header Report-Msgid-Bugs-To.
         * 
         * @example
         *      p.reportBugsTo()
         *
         * @return {String} Returns a string containing the value of the header Report-Msgid-Bugs-To
         */
        reportBugsTo: function() { return( this.getMetaValue( 'Report-Msgid-Bugs-To' ) ); },

        /**
         * Sets the locale to get translated messages for.
         *
         * @example
         *     po.setLocale( 'ja_JP' )
         *
         * @param {String} locale  A locale such as "en-GB", "fr_FR", "ja-JP", etc.
         */
        setLocale: function(locale)
        {
            var self = this;
            if( typeof( locale ) !== 'string' )
            {
                this.warn( "The locale provided \"" + locale + "\" is of type " + typeof( locale ) + " while I was expecting a string." );
                return;
            }

            locale = locale.trim();
            if( locale === '' )
            {
                this.warn( "The locale value you provided is actually empty." );
            }

            if( !locale.match( LOCALE_REGEXP ) )
            {
                throw new Error( "Language provided (\"" + locale + "\") is in an unsupported format. Use something like \"en_GB\", \"en-GB\" or simply \"en\" or even \"en_GB.utf-8\"." );
            }

            // Normalise to the underscore form used in L10N keys and file paths
            locale = locale.replace( '-', '_' );
            // Ensure we have a domain hash to inspect
            var l10n = self.getDomainHash();
            // If we do not have data for this locale yet, load it now.
            if( locale != this.locale && !l10n.hasOwnProperty( locale ) )
            {
                self.loadDomainData({ domain: this.domain, locale: locale });
            }
            // Switch current locale (normalised form, e.g. "fr_FR")
            this.locale = locale;
        },

        /**
         * Sets the default gettext domain.
         *
         * @example
         *     po.setTextDomain( 'com.example.api' )
         *
         * @param {String} domain  A gettext domain name
         */
        setTextDomain: function(domain)
        {
            var self = this;
            self.debug( "Fetching domain data for \"" + domain + "\"." );
        
            if( typeof( domain ) !== 'string' )
            {
                self.warn( "The domain provided \"" + domain + "\" is of type " + typeof( domain ) + " while I was expecting a string." );
                return Promise.reject( new Error( "Invalid domain type" ) );
            }
        
            if( domain.trim() === '' )
            {
                self.warn( "The domain value you provided is actually empty." );
                return Promise.reject( new Error( "Empty domain provided" ) );
            }
        
            self.domain = domain;
            var hash = window.Gettext.L10N;
            if( !hash.hasOwnProperty( self.domain ) )
            {
                hash[self.domain] = {};
            }
        
            if( !hash[ self.domain ].hasOwnProperty( self.locale ) || 
                !Object.keys( hash[ self.domain ][ self.locale ] ).length == 0 )
            {
                return self.loadDomainData({ domain: self.domain, locale: self.locale }).then(function()
                {
                    self.debug( "Domain \"" + domain + "\" for locale \"" + self.locale + "\" is loaded." );
                    self.isReady = true; // Set readiness here
                    return self.getDomainHash({ locale: self.locale });
                }).catch(function(err)
                {
                    self.setError( new Error( "Failed to load translation data: " + err.message ) );
                    throw err; // Propagate error
                });
            }
            else
            {
                self.isReady = true; // Data is already available
                return Promise.resolve(self.getDomainHash({ locale: self.locale }));
            }
        },

        _getSeparator: function(locale, separatorType)
        {
            var self = this;
            const numberWithGroupAndDecimalSeparator = 1000.1;
            return Intl.NumberFormat(locale)
                .formatToParts(numberWithGroupAndDecimalSeparator)
                .find(part => part.type === separatorType)
                .value;
        }        
    });
    window.Gettext.L10N = {};
    window.Gettext.ERROR = '';

    window.TEXTDOMAIN = ( window.TEXTDOMAIN || '' );
    function _( msgid )
    {
        if( typeof( msgid ) === 'undefined' )
        {
            throw new Error( "msgid provided is undefined." );
        }
        else if( typeof( msgid ) == null )
        {
            throw new Error( "msgid provided is null." );
        }

        window.GETTEXT_PREFS = window.GETTEXT_PREFS || {};
        if( typeof( TEXTDOMAIN ) === 'undefined' ||
            typeof( TEXTDOMAIN ) == null ||
            TEXTDOMAIN.length == 0 )
        {
            var scripts = document.getElementsByTagName( 'script' );
            var def = null;
            for( var i = 0, l = scripts.length; i < l; i++ )
            {
                var script = scripts[i];
                if( script.getAttribute( 'id' ) == 'gettext' && 
                    script.hasAttribute( 'type' ) && 
                    script.getAttribute( 'type' ) == 'application/json' )
                {
                    try
                    {
                        def = JSON.parse(document.getElementById('gettext').textContent);
                    }
                    catch(e)
                    {
                        throw new Error( "Unable to parse gettext json in script tag: " + e );
                    }
                    break;
                }
            }
            if( typeof( def ) !== 'object' )
            {
                return( '' );
            }
            else if( !def.hasOwnProperty( 'domain' ) )
            {
                throw new Error( "No \"domain\" property defined in the gettext json in the script html tag." );
            }
            else if( def.domain.length == 0 )
            {
                throw new Error( "Domain property found in the gettext json in the script tag is empty." );
            }
            window.TEXTDOMAIN = def.domain;
            window.GETTEXT_PREFS = def;
        }
        var locale = ( document.getElementsByTagName('html')[0].getAttribute('lang') || window.GETTEXT_PREFS.defaultLocale || 'en' );
        var po = new Gettext({
            domain: TEXTDOMAIN,
            locale: locale,
            debug: ( window.GETTEXT_PREFS.debug || false )
        });
        return( po.gettext( msgid ) );
    }

    // XXX MOParser class
    /*
    Adapted from work by Oliver Hamlet (gettext mo parser)
    <https://github.com/Ortham/jed-gettext-parser>
    */
    window.MOParser = POBaseClass.extend(
    {
        __class__: "MOParser",
        // var p = new MOParser();
        // var localeData = p.parse({ buffer: data, encoding: "utf-8" });
        /**
         * Creates and returns a new MOParser instance.
         *
         * @example
         *      new MOParser();
         * 
         * @constructor
         * @param  {Object}  [options]             A set of options
         * @param  {Boolean} options.debug         Whether to output debug info into the
         *                                         console.
         * @return {Object}  A MOParser instance
         */
        init: function( options )
        {
            var self = this;
            // <https://developer.mozilla.org/en-US/docs/Web/API/TextDecoder>
            this.textDecoder = window.TextDecoder;
            this._littleEndian = null;
            this._dataView = null;
            this._encoding = null;
            this.debug = ( options.debug || false );

            this._originalOffset = null;
            this._translationOffset = null;
            this._MAGIC = 0x950412de;
            return( this );
        },

        /**
         * Find out if the binary data used little or big endian and set private object variable _littleEndian
         *
         * @example
         *     p._getEndianness()
         *
         * @return {Boolean} True if little endian or false for big endian
         */
        _getEndianness: function()
        {
            /* MO files can be big or little endian, independent of the source or current platform. Use DataView's optional get*** argument to set the endianness if necessary. */
            if( this._dataView.getUint32(0, true) == this._MAGIC )
            {
                this._littleEndian = true;
            }
            else if( this._dataView.getUint32(0, false) == this._MAGIC )
            {
                this._littleEndian = false;
            }
            else
            {
                throw new Error( 'Not a gettext binary message catalog file.' );
            }
        },

        /**
         * Read header data and parse each field to return an hash of field-value pairs
         *
         * @example
         *     p._parseHeader()
         *
         * @return {Object} Hash of field-value pairs
         */
        _parseHeader: function()
        {
            /* Read translation header. This is stored as a msgstr where the msgid
               is '', so it's the first entry in the translation block, since
               strings are sorted. Assume that the header is in UTF-8.
               */
            var msgBytes = this._readTranslationPair(this._originalOffset, this._translationOffset);

            var headers = {};
            // var language, pluralForms;
            if( msgBytes.id.byteLength == 0 )
            {
                var decoder = new TextDecoder();
                var str = decoder.decode( msgBytes.str );

                str.split("\n").forEach(function(line)
                {
                    /* Header format is like HTTP headers. */
                    var parts = line.split(':');
                    var key = parts.shift().trim();
                    var value = parts.join(':').trim();
                    headers[key] = value;
                });

                /* Get encoding if not given. */
                if( !this._encoding )
                {
                    var pos = headers['Content-Type'].indexOf('charset=');

                    if( pos != -1 && pos + 8 < headers['Content-Type'].length )
                    {
                        /* TextDecoder expects a lowercased encoding name. */
                        this._encoding = headers['Content-Type'].substring(pos + 8).toLowerCase();
                    }
                    if( !this._encoding )
                    {
                        this._encoding = 'utf-8';
                    }
                }

                /* Get language from header. */
                // language = headers['Language'];

                /* Get plural forms from header. */
                // pluralForms = headers['Plural-Forms'];
            }

            return({ '': headers });
        },

        /**
         * Read bytes of data and returns the corresponding msgid and msgstr
         *
         * @example
         *     p._readTranslationPair( originalOffset, translationOffset )
         *
         * @param  {Number} originalOffset       Original offset position
         * @param  {Number} translationOffset    Offset position for the translation
         * @return {Object} Hash of data with 1 id-str pair
         */
        _readTranslationPair: function(originalOffset, translationOffset)
        {
            var length, position, idBytes, strBytes;
            /* Get original byte array, that forms the key. */
            length = this._dataView.getUint32( originalOffset, this._littleEndian );
            position = this._dataView.getUint32( originalOffset + 4, this._littleEndian );
            try
            {
                idBytes = new Uint8Array( this._dataView.buffer, position, length );
            }
            catch(e)
            {
                throw new Error( 'The given ArrayBuffer data is corrupt or incomplete.' );
            }

            /* Get translation byte array, that forms the value. */
            length = this._dataView.getUint32( translationOffset, this._littleEndian );
            position = this._dataView.getUint32( translationOffset + 4, this._littleEndian );
            try
            {
                strBytes = new Uint8Array( this._dataView.buffer, position, length );
            }
            catch(e)
            {
                throw new Error( 'The given ArrayBuffer data is corrupt or incomplete.' );
            }

            return({
                id: idBytes,
                str: strBytes
            });
        },

        /**
         * Split the msgid and msgstr for plurals
         *
         * @example
         *     p._splitPlurals( msgid, msgstr )
         *
         * @return {Object} Hash with 2 keys: id and str each containing an array
         */
        _splitPlurals: function(msgid, msgstr)
        {
            /* Need to handle plurals. Plural translations must be split into an 
               array of strings. We only want the first part of a plural as its
               key. */
            return({
                id: msgid.split('\u0000')[0],
                str: msgstr.split('\u0000')
            });
        },

        /**
         * Parse binary data from .mo (machine object) file and return an hash of msgid-msgstr pairs
         *
         * @example
         *     p.parse( buffer, { domain: "com.example.api", encoding: "utf-8" })
         *
         * @param  {String} domain       A gettext domain name
         * @param  {String} encoding     Character encoding
         * @return {Object} Hash of data with msgid-msgstr pairs
         */
        parse: function(buffer, options)
        {
            /* Leave the encoding undefined if no options are given. */
            options = options || { domain: 'messages' };
            options.domain = options.domain || 'messages';

            if( buffer && buffer.byteLength == 0 )
            {
                throw new Error( 'Given ArrayBuffer is empty.' );
            }

            if( !buffer || Object.prototype.toString.call(buffer) != '[object ArrayBuffer]' )
            {
                throw new Error( 'First argument must be an ArrayBuffer.' );
            }
            var encoding = options.encoding;

            /* A mo file can be empty apart from its magic, revision, strings count,
               offsets and hash table size, but fields for these must all exist, so
               verify the file is large enough. */
            if( buffer.byteLength < 28 )
            {
                throw new Error( 'The given ArrayBuffer is too small to hold a valid .mo file.' );
            }

            this._dataView = new DataView( buffer );
            this._encoding = encoding;

            this._getEndianness();

            /* Get size and offsets. Skip the revision and hash table, they're
               unnecessary. */
            var stringsCount = this._dataView.getUint32( 8, this._littleEndian );
            this._originalOffset = this._dataView.getUint32( 12, this._littleEndian );
            this._translationOffset = this._dataView.getUint32( 16, this._littleEndian );

            /* Parse header for info, and use it to create the locale_data object
               'header'. */
            var localeData = this._parseHeader();

            /* Create a TextDecoder for encoding conversion. */
            var decoder;
            try
            {
                // <https://github.com/inexorabletash/text-encoding>
                decoder = new TextDecoder( this._encoding );
            }
            catch(e)
            {
                throw new Error( "The encoding label provided ('" + this._encoding + "') is invalid." );
            }

            /* Now get translations. */
            var originalOffset = this._originalOffset + 8;
            var translationOffset = this._translationOffset + 8;
            for( var i = 1; i < stringsCount; ++i )
            {
                var msgBytes = this._readTranslationPair( originalOffset, translationOffset );
                var msg = this._splitPlurals( decoder.decode( msgBytes.id ), decoder.decode( msgBytes.str ) );

                localeData[msg.id] = [].concat(msg.str);

                originalOffset += 8;
                translationOffset += 8;
            }
            return( localeData );
        }
    });

    /**
     * Set a new HeaderValue object
     *
     * @example
     *     var headerVal = new HeaderValue( "text/plain", { debug: 3, toString: "text/plain; charset=utf-8" });
     *
     * @param  {Object} HeaderValue      Returns an HeaderValue object
     */
    window.HeaderValue = POGenericClass.extend(
    {
        __class__: "HeaderValue",
        init: function( value, opts )
        {
            this.value  = value;
            this._toString = null;
            this.params = {};

            if( typeof( opts ) === 'undefined' )
            {
                opts = {};
            }

            if( opts.hasOwnProperty( 'debug' ) )
            {
                opts.debug_level = opts.debug;
                delete( opts.debug );
            }
            if( opts.hasOwnProperty( 'toString' ) )
            {
                opts._toString = opts.toString;
                delete( opts.toString );
            }
            this._super( opts );
            return( this );
        },

        getParam: function(name)
        {
            return( this.params[name] );
        },

        getValue: function()
        {
            return( this.value );
        },

        setParam: function(name, value)
        {
            this.params[name] = value;
        },

        setValue: function(value)
        {
            this.value = value;
        },

        toString: function()
        {
            var self = this;
            if( typeof( self._toString ) !== 'string' ||
                self._toString.length == 0 )
            {
                var string = '';
                if( typeof( self.value ) !== 'undefined' )
                {
                    if( !TYPE_REGEXP.test( self.value ) )
                    {
                        throw new TypeError( 'Invalid value "' + self.value + '"' );
                    }
                    string = self.value;
                }

                // Append parameters
                if( self.params && typeof( self.params ) === 'object' )
                {
                    var params = Object.keys( self.params ).sort();
                    for( var i = 0; i < params.length; i++ )
                    {
                        if( !TOKEN_REGEXP.test( params[i] ) )
                        {
                            throw new TypeError( 'Invalid parameter name: "' + params[i] + '"' );
                        }
                        if( string.length > 0 )
                        {
                            string += '; ';
                        }
                        string += params[i] + '=' + self.qstring( self.params[ params[i] ] );
                    }
                }
                self._toString = string;
            }
            return( self._toString );
        },

        /**
         * Quote a string if necessary.
         *
         * @param {string} val
         * @return {string}
         * @private
         */
        qstring: function(val)
        {
            var str = String(val);

            // no need to quote tokens
            if( TOKEN_REGEXP.test(str) )
            {
                return( str );
            }

            if( str.length > 0 && !TEXT_REGEXP.test(str) )
            {
                throw new TypeError( 'Invalid parameter value' );
            }

            return( '"' + str.replace( QUOTE_REGEXP, '\\$1' ) + '"' );
        }
    });
})();

// NOTE: POD
/*
=pod

=encoding utf-8

=head1 NAME

Gettext - A GNU Gettext JavaScript implementation

=head1 SYNOPSIS

    let po = new Gettext({
        domain: "com.example.api",
        // Get the lang attribute value from <html>
        // Can also use document.getElementsByTagName('html')[0].getAttribute('lang')
        // or in jQuery: $(':root').attr('lang')
        locale: document.documentElement.lang,
        // Under which uri can be found the localised data arborescence?
        // Alternatively, you can set a <link rel="gettext" href="/locale" />
        // or even one specific by language:
        // <link rel="gettext" lang="ja_JP" href="/locale/ja" />
        path: "/locale",
        debug: true
    });
    po.ready(function(poObject)
    {
        // Do something
    },
    function(errorObject)
    {
        // Do something
    });

Or:

    po.ready().then(function(poObject)
    {
        // Do something
    }).catch(function(errorObject)
    {
        // Do something
    });

    new Gettext({
        domain: "com.example.api",
        locale: document.documentElement.lang,
        path: "/locale",
        promise: true
    }).then(function(poObject)
    {
        // Do something
    }).catch(function(errorObject)
    {
        // Do something
    });

=head1 VERSION

    v0.4.0

=head1 DESCRIPTION

This is a standalone JavaScript library using class model to enable the reading of json-based po files as well as C<.mo> files. Even though it can read C<.mo> files, it is better to convert the original C<.po> files to json using the C<po.pl> utility that comes in this L<Text::PO> distribution. For example:

    ./po.pl --as-json --output /home/joe/www/locale/ja_JP/com.example.api.json ./ja_JP.po

The class model does not use ES6, but rather one smart invention by John Resig (creator of jQuery), making it usable even on older browser versions.

Because on the service side, in Unix environments, the locale value uses underscore, such as C<ja_JP> while the web-side uses locale with a dash such as C<ja-JP>, to harmonise and given we are dealing with po files, we use internally the underscore version, converting it, if necessary.

See the section L</TESTING> below for testing.

Also, note that this class is ES5 compatible, and uses promise. If promise is not available in your environment, it uses a polyfill as a replacement.

You have to be careful that the C<JSON> po file is loaded before you can start calling C<gettext> or other similar method, or else those method will fail to return the localised string. Thus, it is recommended to either use the C<promise> option upon instantiation, or use the C<ready> method as shown in the synopsis.

=head1 CONSTRUCTOR

=head2 new

Takes the following options and returns a Gettext object.

=over 4

=item * C<domain>

The portable object domain, such as C<com.example.api>

=item * C<locale>

The locale, such as C<ja_JP>, or C<en>, or it could even contain a dash instead of an underscore, such as C<en-GB>. Internally, though, this will be converted to underscore.

=item * C<path>

The uri path where the gettext localised data are.

This is used to form a path along with the locale string. For example, with a locale of C<ja_JP> and a domain of C<com/example.api>, if the path were C</locale>, the data po json data would be fetched from C</locale/ja_JP/com.example.api.json>

You will note that the path does not include C<LC_MESSAGES> since under the web context, it makes no sense at all. See the L<GNU documentation|https://www.gnu.org/software/libc/manual/html_node/Using-gettextized-software.html> for more information on this.

=item * C<promise>

If provided and set to a true value, then the constructor method will return a promise instead of C<Gettext> object.

=back

=head1 CORE METHODS

=head2 gettext

Provided with a C<msgid> represented by a string, and this return a localised version of the string, if any is found and is translated, otherwise returns the C<msgid> that was provided.

    po.gettext( "Hello" );
    # With locale of fr_FR, this would return "Bonjour"

Note that you can also call it with the special function C<_>, such as:

    _("Hello");

See the global function L</_> for more information.

If the C<msgid> is an object that supports stringification (i.e. it has the toString() method), it will be stringified before being used.

From version v0.2.0, this method returns a C<GettextString> object, which inherits from JavaScript standard C<String> class and allows to set the language, if any, of the string returned. If no localised string could be found, the string language would be C<undefined>. For example:

    let localStr = po.gettext( "Hello" );
    // Assuming the language sought is ja-JP and it succeed:
    localStr.getLang(); // returns ja-JP
    localStr.getLocale(); // same; returns ja-JP
    localStr.lang; // also returns ja-JP
    // If no localised string were found:
    localStr.getLang(); // returns undefined
    localStr.getLocale(); // same; returns undefined
    localStr.lang; // also returns undefined

=head2 dgettext

Takes a domain and a message id and returns the equivalent localised string if any, otherwise the original message id.

    po.dgettext( 'com.example.auth', 'Please enter your e-mail address' );
    # Assuming the locale currently set is ja_JP, this would return:
    # 電子メールアドレスをご入力下さい。

From version v0.2.0, the string returned is a C<GettextString> object, which inherits from JavaScript standard C<String> and automatically stringifies. See L</gettext> above for more details.

=head2 ngettext

Takes an original string (a.k.a message id), the plural version of that string, and an integer representing the applicable count. For example:

    po.ngettext( '%d comment awaiting moderation', '%d comments awaiting moderation', 12 );
    # Assuming the locale is ru_RU, this would return:
    # %d комментариев ожидают проверки

From version v0.2.0, the string returned is a C<GettextString> object, which inherits from JavaScript standard C<String> and automatically stringifies. See L</gettext> above for more details.

=head2 dngettext

Same as L</ngettext>, but takes also a domain as first argument. For example:

    po.ngettext( 'com.example.auth', '%d comment awaiting moderation', '%d comments awaiting moderation', 12 );
    # Assuming the locale is ru_RU, this would return:
    # %d комментариев ожидают проверки

From version v0.2.0, the string returned is a C<GettextString> object, which inherits from JavaScript standard C<String> and automatically stringifies. See L</gettext> above for more details.

=head1 EXTENDED METHODS

=head2 gettextf

This is the same as L</gettext>, except it will format the localised string using sprintf and the supplied arguments.

Provided with a C<msgid> represented by a string, and this return a localised version of the string formatted using sprintf and with provided arguments, if any is found and is translated, otherwise returns the C<msgid> that was provided.

    po.gettextf( "Hello %s", "John" );
    # With locale of fr_FR, this would return "Bonjour John"

=head2 addItem

This takes a C<locale>, a message id and its localised version and it will add this to the current dictionary for the current domain.

=head2 charset

Returns a string containing the value of the charset encoding as defined in the C<Content-Type> header.

    p.charset()

=head2 contentEncoding

Returns a string containing the value of the header C<Content-Encoding>.

    p.contentEncoding();

=head2 contentType

Returns a string containing the value of the header C<Content-Type>.

    p.contentType(); # text/plaiin; charset=utf-8

=head2 currentLang

Return the current globally used locale. This is the value found in

    <html lang="fr-FR">

and thus, this is different from the C<locale> set in the Gettext class object using L</setLocale> or upon class object instantiation.

=head2 exists

Provided with a locale, and this returns true if the locale exists in the current domain, or false otherwise.

=head2 fetchLocale

Given an original string (msgid), this returns an array of <span> html element each for one language and its related localised content. For example:

    var array = p.fetchLocale( "Hello!" );
    // Returns:
    <span lang="de-DE">Grüß Gott!</span>
    <span lang="fr-FR">Salut !</span>
    <span lang="ja-JP">今日は！</span>
    <span lang="ko-KR">안녕하세요!</span>

=head2 fetchLocalen

Given a string in singular and plural form and the count value, this will return the appropriate locale version, if any were found.

It will do so for all the languages activated for this particular domain.

Thus, you could do:

    var po = new Gettext({
        domain: self.po_domain,
        locale: "en-GB",
        path: '/public/locale',
        debug: false,
    });

    var po_de = new Gettext({
        domain: self.po_domain,
        locale: "de-DE",
        path: '/public/locale',
        debug: false,
    });

    var po_fr = new Gettext({
        domain: self.po_domain,
        locale: "fr-FR",
        path: '/public/locale',
        debug: false,
    });

    var po_ja = new Gettext({
        domain: self.po_domain,
        locale: "ja-JP",
        path: '/public/locale',
        debug: false,
    });

and then:

    var array = po.fetchLocalen( "%d person", "%d persons", 2 );

    // Returns:
    <span lang="de-DE">2 Personen</span>
    <span lang="en-GB">2 persons</span>
    <span lang="fr-FR">2 personnes</span>
    <span lang="ja-JP">2人</span>

=head2 getData

Takes an hash of options and perform an HTTP query and return a promise. The accepted options are:

=over 4

=item * C<headers>

An hash of field-value pairs to be used in the request header.

=item * C<method>

The HTTP method to be used, such as C<GET> or C<POST>

=item * C<params>

An hash of key-value pairs to be set and encoded in the http request query.

=item * C<responseType>

The content-type expected in response. This is used to set it to C<arraybuffer> to load C<.mo> (machine object) files.

=item * C<url>

The url to make the query to.

=back

=head2 getDataPath

This takes no argument and will check among the C<link> html tags for one with an attribute C<rel> with value C<gettext> and no C<lang> attribute. If found, it will use this in lieu of the I<path> option used during object instantiation.

It returns the value found. This is just a helper method and does not affect the value of the I<path> property set during object instantiation.

=head2 getDaysLong

Returns an array reference containing the 7 days of the week in their long representation.

    var ref = po->getDaysLong();
    // Assuming the locale is fr_FR, this would yield
    console.log ref[0]; // dim.

=head2 getDaysShort

Returns an array reference containing the 7 days of the week in their short representation.

    var ref = po->getDaysShort();
    // Assuming the locale is fr_FR, this would yield
    console.log ref[0]; // dimanche

=head2 getDomainHash

This takes an optional hash of parameters and return the global hash dictionary used by this class to store the localised data.

    // Will use the default domain as set in po.domain
    var data = po.getDomainHash();
    // Explicitly specify another domain
    var data = po.getDomainHash({ domain: net.example.api });
    // Specify a domain and a locale
    var l10n = po.getDomainHash({ domain: com.example.api, locale: "ja_JP" });

Possible options are:

=over 4

=item * C<domain> The domain for the data, such as C<com.example.api>

=item * C<locale> The locale to return the associated dictionary.

=back

=head2 getLangDataPath

This takes a locale as its unique parameter.

Similar to </getDataPath>, this will search among the C<link> html tags for those with the attribute C<rel> with value C<gettext> and an existing C<lang> attribute. If found it returns the value of the C<href> attribute.

This is used internally during object instantiation when the I<path> parameter is not provided.

=head2 getLanguageDict

Provided with a locale, such as C<ja_JP> and this will return the dictionary for the current domain and the given locale.

=head2 getLocale

Returns the locale set for the current object, such as C<fr-FR> or C<ja-JP>

Locale returned are always formatted for the web, which means having an hyphen rather than an underscore like in Unix environment.

=head2 getLocales

Provided with a locale and this will call L</fetchLocale> and return those C<span> tags as a string, joined by a new line

=head2 getLocalesf

This is similar to L</getLocale>, except that it does a sprintf internally before returning the resulting value.

=head2 getMoData

Provided with an uri and this will make an http query to fetch the remove C<.mp> (machine object) file.

It calls L</getData> and returns a promise.

=head2 getMonthsLong

Returns an array reference containing the 12 months in their long representation.

    var ref = po->getMonthsLong();
    // Assuming the locale is fr_FR, this would yield
    console.log ref[0]; // janvier

=head2 getMonthsShort

Returns an array reference containing the 12 months in their short representation.

    var ref = po->getMonthsShort();
    // Assuming the locale is fr_FR, this would yield
    console.log ref[0]; // janv.

=head2 getNumericDict

Returns an hash reference containing the following properties:

    var ref = po->getNumericDict();

=over 4

=item * C<currency> string

(This is not available in the JavaScript interface yet)

Contains the usual currency symbol, such as C<€>, or C<$>, or C<¥>

=item * C<decimal> string

Contains the character used to separate decimal. In English speaking countries, this would typically be a dot.

=item * C<int_currency> string

(This is not available in the JavaScript interface yet)

Contains the 3-letters international currency symbol, such as C<USD>, or C<EUR> or C<JPY>

=item * C<negative_sign> string

(This is not available in the JavaScript interface yet)

Contains the negative sign used for negative number

=item * C<precision> integer

(This is not available in the JavaScript interface yet)

An integer whose value represents the fractional precision allowed for monetary context.

For example, in Japanese, this value would be 0 while in many other countries, it would be 2.

=item * C<thousand> string

Contains the character used to group and separate thousands.

For example, in France, it would be a space, such as :

    1 000 000,00

While in English countries, including Japan, it would be a comma :

    1,000,000.00

=back

=head2 getPlural

Returns the array representing the plural rule for the current domain.

The array returned is composed of 2 elements:

=over 4

=item 1. An integer representing the number of possible plural forms

=item 2. A string representing an expression using C<n> as the count provided. This string is to be evaluated and will return an offset value used to get the right localised plural content in an array of C<msgstr>

The value returned cannot exceed the integer.

=back

=head2 getText

    var str = po.getText( "Hello world" );
    var str = po.getText( "Hello world", 'fr-FR' );

Provided with an original string, and an optional locale, and this will return its localised equivalent if it exists, or by default, it will return the original string.

From version v0.2.0, the string returned is a C<GettextString> object, which inherits from JavaScript standard C<String> and automatically stringifies. See L</gettext> above for more details.

=head2 getTextf

Provided with an original string, and this will get its localised equivalent that wil be used as a template for the sprintf function. The resulting formatted localised content will be returned.

From version v0.2.0, the string returned is a C<GettextString> object, which inherits from JavaScript standard C<String> and automatically stringifies. See L</gettext> above for more details.

=head2 getTextDomain

Returns a string representing the domain currently set, such as C<com.example.api>

=head2 getXhrObject

Return an XMLHttpRequest object compliant with older versions of Microsoft browsers.

=head2 isSupportedLanguage

Provided with a locale and this returns true if the language is supported or false otherwise.

This basically look at the current dictionaries loaded so far for various languages and check if the locale specified in argument is among them.

=head2 language

Returns a string containing the value of the header C<Language>.

    p.language();
    
=head2 languageTeam

Returns a string containing the value of the header C<Language-Team>.

    p.languageTeam();

=head2 lastTranslator

Returns a string containing the value of the header C<Last-Translator>.

    p.lastTranslator();

=head2 loadDomainData

Provided with an hash of options and this will get the data, parse it, save it.

This is called by L</setTextDomain> and L</setLocale>

=head2 mimeVersion

Returns a string containing the value of the header C<MIME-Version>.

    p.mimeVersion();

=head2 pluralForms

Returns a string containing the value of the header C<Plural-Forms>.

    p.pluralForms();

=head2 poRevisionDate

Returns a string containing the value of the header C<PO-Revision-Date>.

    p.poRevisionDate();

=head2 potCreationDate

Returns a string containing the value of the header C<POT-Creation-Date>.

    p.potCreationDate();

=head2 projectIdVersion

Returns a string containing the value of the header C<Project-Id-Version>.

    p.projectIdVersion();

=head2 ready

This takes an optional callback, and error callback, and returns a promise.

If an error occurs, the error callback is called with an error object, and the promise is rejected with that error object.

When the promise resolves, the success callback is called with the C<Gettext> object, and the promise resolves with that C<Gettext> object.

=head2 reportBugsTo

Returns a string containing the value of the header C<Report-Msgid-Bugs-To>.

    p.reportBugsTo();

=head2 setLocale

Sets a new locale to be used looking forward.

    po.setLocale( 'fr_FR' ); # po.setLocale( 'fr-FR' ); would also work

=head2 setTextDomain

Sets a new domain to be used looking forward. Setting a new domain, will trigger the Gettext class to fetch its data by executing an http C<GET> query using L</getData> unless the domain is already registered and loaded.

    po.setTextDomain( 'com.example.auth' );

=head1 PROPERTIES

=head2 category

    var po = new Gettext({
        category: 'LC_MESSAGES',
        domain: 'com.example.api',
        locale: 'en-GB',
        path: "/some/where",
    });
    po.category; // "LC_MESSAGES"

Returns the C<category> value provided upon object instantiation. Defaults to C<LC_MESSAGES>

=head debug

    var po = new Gettext({
        domain: 'com.example.api',
        locale: 'en-GB',
        path: "/some/where",
        debug: true,
    });
    po.debug; // true

Returns the C<debug> value provided upon object instantiation. Defaults to C<false>

=head2 domain

    var po = new Gettext({
        domain: 'com.example.api',
        locale: 'en-GB',
        path: "/some/where",
    });
    po.domain; // "com.example.api"

Returns the C<domain> value provided upon object instantiation. 

=head2 locale

    var po = new Gettext({
        domain: 'com.example.api',
        locale: 'en-GB',
        path: "/some/where",
    });
    po.locale; // "en-GB"

Returns the C<locale> value provided upon object instantiation.

=head2 path

    var po = new Gettext({
        domain: 'com.example.api',
        locale: 'en-GB',
        path: "/some/where",
    });
    po.path; // "/some/where"

Returns the C<path> value provided upon object instantiation.

=head1 GLOBAL FUNCTION

=head2 _

The special function C<_> is standard for gettext. This is a wrapper to the following:

Assuming the global variable TEXTDOMAIN is set, or else that there is a script tag:

    <script id="gettext" type="application/json">
    {
        domain: "com.example.api",
        debug: true,
        defaultLocale: "en_US"
    }
    </script>

If no locale is defined in the json, then it will check for the attribute C<lang> of the C<html> tag, such as:

    <html lang="fr-FR">

And will instantiate a C<Gettext> object, passing it the I<domain>, I<debug> and I<locale> parameters as options, and will return the value returned by C<po.gettext>

If an improper C<msgid> (undefined or null or empty) is provided or there is no C<domain> to be found, an error will be raised.

=head1 CLASS MOParser

=head2 new

Takes an optional hash of options. Currently supported option is I<debug>.

Instantiate a new MOParser object and returns it.

=head2 parse

This takes a buffer and an hash of options and returns an hash representing the msgid-msgstr.

Acceptable options are:

=over 4

=item I<encoding>

Character encoding used to decode data

=back

=head2 _getEndianness

Returns the file endianness used. True if it is little endian or false if it is big endian.

=head2 _parseHeader

Read the binary data and returns an hash of field-value pairs representing the C<.mo> (machine object) file headers.

=head2 _readTranslationPair

Read the binary data and returns an hash with properties C<id> and C<str> corresponding to the next C<msgid> and C<msgstr> found.

=head2 _splitPlurals

Takes a msgid string and a msgstr string and split them to get an array of single and plural representations.

It returns an hash with properties C<id> representing the C<msgid> and C<str> containing an array of C<msgstr>

=head1 TESTING

On the command line, go to the top directory of the L<Text::PO> distribution and launch a small web server using python or anything else you would like:

For Perl:

    # With HTTP::Daemon
    perl -MHTTP::Daemon -e '$d = HTTP::Daemon->new(LocalPort => 8000) or  +die $!; while 
($c = $d->accept) { while ($r = $c->get_request) { +$c->send_file_response(".".$r->url->path) } }'

    # After installing the module HTTP::Server::Brick
    perl -MHTTP::Server::Brick -e '$s=HTTP::Server::Brick->new(port=>8000); $s->mount("/"=>{path=>"."}); $s->start'

    # If you have Plack::App::Directory
    perl -MPlack::App::Directory -e 'Plack::App::Directory->new(root=>".");' -p 8000

    # With IO::All
    perl -MIO::All -e 'io(":8000")->fork->accept->(sub { $_[0] < io(-x $1 +? "./$1 |" : $1) if /^GET \/(.*) / })'

For python 2:

    python -m SimpleHTTPServer

For python 3:

    python3 -m http.server

Or using ruby:

    ruby -run -e httpd -p 8000 . 

Or with php:

    php -S localhost:8000

Or possibly with nodejs if you have it installed:

    # to install http-server
    npm install -g http-server
    # or using brew:
    brew install http-server
    # then
    http-server -c-1 -p 8000

More information L<here|https://www.npmjs.com/package/http-server>

Then, you can go to L<http://localhost:8000/share/test.html>

If all goes well, you will see the result of all the test performed, and they should all be marked B<ok>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Text::PO::Element>, L<Text::PO::MO>

L<https://www.gnu.org/software/gettext/manual/html_node/PO-Files.html>,

L<https://en.wikipedia.org/wiki/Gettext>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020-2023 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut
*/
