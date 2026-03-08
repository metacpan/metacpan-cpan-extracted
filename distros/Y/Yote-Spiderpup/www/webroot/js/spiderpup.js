const onMounts = [];
const moduleRegistry = [];
if (typeof window !== 'undefined') window.moduleRegistry = moduleRegistry;

// Global reactive store
const store = {
  _state: {},
  _watchers: {},

  get(key) {
    return this._state[key];
  },

  set(key, value) {
    const oldValue = this._state[key];
    if (oldValue !== value) {
      this._state[key] = value;
      // Call store watcher if defined
      if (this._watchers[key]) {
        this._watchers[key](value, oldValue);
      }
      // Mark all components dirty and refresh
      this._notifyAll();
    }
  },

  // Initialize multiple keys at once
  init(obj) {
    for (const [key, value] of Object.entries(obj)) {
      this._state[key] = value;
    }
  },

  // Watch for changes to a specific key
  watch(key, callback) {
    this._watchers[key] = callback;
  },

  // Notify all components to refresh
  _notifyAll() {
    for (const module of moduleRegistry) {
      module.dirty = true;
      module.refresh();
    }
  }
};

if (typeof window !== 'undefined') window.store = store;

// Get base path from server config (normalized with leading slash, no trailing slash)
function getBasePath() {
    let base = (typeof window !== 'undefined' && window.SPIDERPUP_BASE_PATH) || '';
    if (base && !base.startsWith('/')) {
        base = '/' + base;
    }
    // Remove trailing slash
    if (base.endsWith('/')) {
        base = base.slice(0, -1);
    }
    return base;
}

// Global router instance
let globalRouter = null;
if (typeof window !== 'undefined') {
    Object.defineProperty(window, 'globalRouter', {
        get: () => globalRouter,
        set: (v) => { globalRouter = v; }
    });
}

// SPA Router
class SpiderpupRouter {
    constructor(routes, viewEl, pageInstance) {
        this.routes = routes;
        this.viewEl = viewEl;
        this.pageInstance = pageInstance;
        this.currentInstance = null;
        globalRouter = this;
        window.addEventListener('popstate', () => this.handleRoute());
    }

    matchRoute(path) {
        const base = getBasePath();
        let matchPath = path;
        if (base && matchPath.startsWith(base)) {
            matchPath = matchPath.slice(base.length) || '/';
        }
        // Strip .html suffix for route matching
        matchPath = matchPath.replace(/\.html$/, '') || '/';
        if (!matchPath.startsWith('/')) matchPath = '/' + matchPath;

        for (const route of this.routes) {
            const match = matchPath.match(route.pattern);
            if (match) {
                const params = {};
                route.params.forEach((name, i) => {
                    params[name] = match[i + 1];
                });
                return { route, params };
            }
        }
        return null;
    }

    navigate(path) {
        const base = getBasePath();
        // Use .html suffix so reloads serve the static file
        const htmlPath = (path === '/') ? '/' : path + '.html';
        const fullPath = base + htmlPath;
        history.pushState(null, '', fullPath);
        this.handleRoute();
    }

    handleRoute() {
        const match = this.matchRoute(location.pathname);
        if (match) {
            this.renderRoute(match);
        }
    }

    renderRoute(match) {
        // Destroy old component
        if (this.currentInstance) {
            this.currentInstance.destroy();
            // Remove from moduleRegistry
            const idx = moduleRegistry.indexOf(this.currentInstance);
            if (idx !== -1) moduleRegistry.splice(idx, 1);
        }

        // Clear the view element
        empty(this.viewEl);

        // Instantiate the route component
        const ComponentClass = match.route.component;
        const instance = new ComponentClass();
        instance._injectCss();
        instance.parentModule = this.pageInstance;
        instance.moduleId = moduleRegistry.length;
        moduleRegistry.push(instance);

        // Set route params as vars
        for (const [key, val] of Object.entries(match.params)) {
            if (key in instance.vars) {
                instance.vars[key] = val;
            }
        }

        // Render the component's children into the view element
        const children = instance.structure.children;
        for (let idx = 0; idx < children.length; idx++) {
            instance.render(this.viewEl, children, idx);
        }

        // Schedule onMount
        if (instance.onMount) {
            setTimeout(() => instance.onMount.call(instance.me()), 0);
        }

        this.currentInstance = instance;
    }
}

// Transition CSS (injected once)
const transitionStyles = `
.sp-fade-enter { opacity: 0; }
.sp-fade-enter-active { transition: opacity 0.3s ease; }
.sp-fade-leave { opacity: 1; }
.sp-fade-leave-active { opacity: 0; transition: opacity 0.3s ease; }
.sp-slide-enter { transform: translateX(100%); }
.sp-slide-enter-active { transition: transform 0.3s ease; }
.sp-slide-leave { transform: translateX(0); }
.sp-slide-leave-active { transform: translateX(-100%); transition: transform 0.3s ease; }
`;

let transitionStylesInjected = false;
function injectTransitionStyles() {
    if (transitionStylesInjected) return;
    const style = document.createElement('style');
    style.textContent = transitionStyles;
    document.head.appendChild(style);
    transitionStylesInjected = true;
}

// Error overlay for runtime errors
const errorOverlayStyles = `
.sp-error-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.9);
    color: #fff;
    font-family: monospace;
    padding: 40px;
    overflow: auto;
    z-index: 99999;
}
.sp-error-title {
    color: #ff6b6b;
    font-size: 24px;
    margin-bottom: 20px;
}
.sp-error-message {
    background: #1a1a2e;
    padding: 20px;
    border-radius: 8px;
    border-left: 4px solid #ff6b6b;
    white-space: pre-wrap;
    line-height: 1.6;
    margin-bottom: 20px;
}
.sp-error-stack {
    background: #16213e;
    padding: 15px;
    border-radius: 8px;
    font-size: 12px;
    color: #a0a0a0;
}
.sp-error-close {
    position: absolute;
    top: 20px;
    right: 20px;
    background: #ff6b6b;
    color: #fff;
    border: none;
    padding: 10px 20px;
    cursor: pointer;
    border-radius: 4px;
}
`;

let errorOverlayInjected = false;
function showErrorOverlay(message, stack) {
    // Create head if it doesn't exist
    if (!document.head) {
        document.documentElement.insertBefore(document.createElement('head'), document.documentElement.firstChild);
    }

    // Create body if it doesn't exist
    if (!document.body) {
        document.documentElement.appendChild(document.createElement('body'));
    }

    if (!errorOverlayInjected) {
        const style = document.createElement('style');
        style.textContent = errorOverlayStyles;
        document.head.appendChild(style);
        errorOverlayInjected = true;
    }

    // Remove existing overlay
    const existing = document.querySelector('.sp-error-overlay');
    if (existing) existing.remove();

    const overlay = document.createElement('div');
    overlay.className = 'sp-error-overlay';
    overlay.innerHTML = `
        <button class="sp-error-close" onclick="this.parentElement.remove()">Dismiss</button>
        <div class="sp-error-title">⚠️ Runtime Error</div>
        <div class="sp-error-message">${escapeHtml(message)}</div>
        ${stack ? `<div class="sp-error-stack">${escapeHtml(stack)}</div>` : ''}
    `;
    document.body.appendChild(overlay);
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Global error handlers
if (typeof window !== 'undefined') {
    window.addEventListener('error', (event) => {
        showErrorOverlay(event.message, event.error?.stack);
    });

    window.addEventListener('unhandledrejection', (event) => {
        const reason = event.reason;
        const message = reason?.message || String(reason);
        const stack = reason?.stack;
        showErrorOverlay(`Unhandled Promise Rejection: ${message}`, stack);
    });
} // Global error handlers

// Event class for bubbling events
class SpiderpupEvent {
    constructor(name, data, source) {
        this.name = name;
        this.data = data;
        this.source = source;
        this.propagationStopped = false;
    }

    stopPropagation() {
        this.propagationStopped = true;
    }
} //SpiderPupEvent


function empty(el) {
  while (el.firstChild) {
    el.removeChild(el.firstChild);
  }
}

// Skip whitespace-only text nodes in cursor during hydration
function advancePastWhitespace(cursor) {
  while (cursor.childIdx < cursor.parent.childNodes.length) {
    const node = cursor.parent.childNodes[cursor.childIdx];
    if (node.nodeType === 3 && node.textContent.trim() === '') {
      cursor.childIdx++;
    } else {
      break;
    }
  }
}

// HTML boolean attributes that should be present/absent, not set to "true"/"false"
const booleanAttrs = new Set([
  'selected', 'disabled', 'checked', 'readonly', 'required', 'hidden',
  'multiple', 'autofocus', 'autoplay', 'controls', 'loop', 'muted', 'open'
]);

// DOM properties that must be set via el.prop = val (not setAttribute).
// Textarea/input .value must use the property; setAttribute('value',...) only
// sets the default value and doesn't update the displayed content after user edits.
const domProperties = new Set(['value']);

function setAttribute( el, attr, val ) {
  if (attr === 'textcontent') {
    el.textContent = val;
  } else if (booleanAttrs.has(attr)) {
    // Boolean attributes: add if truthy, remove if falsy
    if (val) {
      el.setAttribute(attr, '');
    } else {
      el.removeAttribute(attr);
    }
  } else if (domProperties.has(attr)) {
    // Form control properties: set via DOM property, not HTML attribute.
    // Only update if changed to avoid resetting cursor position.
    if (el[attr] !== val) el[attr] = val;
  } else {
    el.setAttribute( attr, val );
  }
}

class Recipe {
  attrBindings = [];  // For dynamic function-based attributes
  bindings = [];  // For two-way binding
  classBindings = [];  // For class:* bindings
  conditions = [];
  dirty = false;
  eventHandlers = [];
  eventListeners = {};  // For on/emit events
  handlers = [];
  imports = {};
  loops = [];
  moduleId = null;
  parentModule = null;  // For event bubbling
  receivers = {};  // For broadcast/receive messaging
  refs = {};
  seenConditionals = {}; // structure idx -> true if elseif/else branch is processed
  defaultSlot = null;
  namedSlots = {};
  styleBindings = [];  // For style:* bindings
  updatableElements = []; // list of [structure node, element] pairs
  updatableRecipes = []; //  list of recipe instance objects
  _routerViewEl = null;
  instances = {};  // Named component instances via @name attribute
  _childByNode = null;  // Map: structureNode -> componentInstance (for shared re-render)
  vars = {};
  watchers = {};
  yamlPath = '';  // Path to YAML source file

  static _cssInjected = new Set();

  _injectCss() {
    const cssText = this._css;
    if (!cssText) return;
    const className = this.constructor.name;
    if (Recipe._cssInjected.has(className)) return;
    Recipe._cssInjected.add(className);
    const style = document.createElement('style');
    style.setAttribute('data-spiderpup-module', className);
    style.textContent = cssText;
    document.head.appendChild(style);
  }

  constructor(el) {
    this.rootEl = el;
  }

  me() { return this; }

  // Get full URL to this module's YAML source
  get yamlUrl() {
    if (!this.yamlPath) return '';
    const base = getBasePath();
    return base + '/' + this.yamlPath;
  }

  // Register an event listener (for bubbling events)
  on(eventName, handler) {
    if (!this.eventListeners[eventName]) {
      this.eventListeners[eventName] = [];
    }
    this.eventListeners[eventName].push(handler);
  }

  // Remove an event listener
  off(eventName, handler) {
    if (!this.eventListeners[eventName]) return;
    if (handler) {
      this.eventListeners[eventName] = this.eventListeners[eventName].filter(h => h !== handler);
    } else {
      delete this.eventListeners[eventName];
    }
  }

  // Emit an event that bubbles up to parent modules
  emit(eventName, data) {
    const event = new SpiderpupEvent(eventName, data, this);
    this._bubbleEvent(event);
    return event;
  }

  // Internal: bubble event up the parent chain
  _bubbleEvent(event) {
    // Start with parent (don't handle on self)
    let current = this.parentModule;

    while (current && !event.propagationStopped) {
      // Check if this module has listeners for this event
      if (current.eventListeners && current.eventListeners[event.name]) {
        for (const handler of current.eventListeners[event.name]) {
          // Call handler with event
          const result = handler.call(current, event);
          // If handler returns false, stop propagation
          if (result === false) {
            event.stopPropagation();
          }
          if (event.propagationStopped) break;
        }
      }
      // Move up to next parent
      current = current.parentModule;
    }
  }

  // Register a receiver for a channel
  receive(channel, callback) {
    if (!this.receivers[channel]) {
      this.receivers[channel] = [];
    }
    this.receivers[channel].push(callback);
  }

  // Broadcast a message to all modules except self
  broadcast(channel, data) {
    for (const module of moduleRegistry) {
      // Skip self
      if (module.moduleId === this.moduleId) continue;
      // Skip modules without receivers for this channel
      if (!module.receivers || !module.receivers[channel]) continue;
      // Call all receivers for this channel
      for (const callback of module.receivers[channel]) {
        callback.call(module.me(), data, this);
      }
    }
  }
  
  get(name, defaultValue) {
    if (!(name in this.vars)) {
      this.vars[name] = defaultValue;
      this.dirty = true;
    }
    return this.vars[name];
  }

  set(name, value) {
    const oldValue = this.vars[name];
    if (oldValue !== value) {
      this.vars[name] = value;
      this.dirty = true;
      // Call watcher if defined
      if (this.watchers && this.watchers[name]) {
        this.watchers[name].call(this.me(), value, oldValue);
      }
      // Refresh all modules so conditionals/loops re-evaluate
      store._notifyAll();
    }
  }

  initUI() {
    this._injectCss();
    this.moduleId = moduleRegistry.length;
    moduleRegistry.push( this );
    
    const children = this.structure.children;
    for (let idx = 0; idx < children.length; idx++) {
      this.render( document.body, children, idx );
    }
    // Initialize router if routes are defined and a router-view exists
    if (this.routes && this._routerViewEl) {
      new SpiderpupRouter(this.routes, this._routerViewEl, this);
      globalRouter.handleRoute();
    }
    // Call onMount lifecycle hook
    if (this.onMount) {
      onMounts.push( () => setTimeout(() => this.onMount.call(this.me()), 0) );
    }

    onMounts.forEach( om => om() );
    // Clear after execution to prevent callbacks from accumulating across multiple initUI calls
    onMounts.length = 0;
  }

  // Hydrate SSR-rendered content instead of building from scratch
  hydrateUI() {
    this._injectCss();
    this.moduleId = moduleRegistry.length;
    moduleRegistry.push(this);

    const cursor = { parent: document.body, childIdx: 0 };
    const children = this.structure.children;
    for (let idx = 0; idx < children.length; idx++) {
      this.hydrate(cursor, children, idx);
    }

    // Initialize router if routes are defined and a router-view exists
    if (this.routes && this._routerViewEl) {
      new SpiderpupRouter(this.routes, this._routerViewEl, this);
      globalRouter.handleRoute();
    }

    if (this.onMount) {
      onMounts.push(() => setTimeout(() => this.onMount.call(this.me()), 0));
    }
    onMounts.forEach(om => om());
    onMounts.length = 0;
  }

  // Adopt existing DOM nodes via cursor, attaching event listeners and reactivity
  hydrate(cursor, structure_nodes, structure_idx, loop_item, loop_idx, scope) {
    const structureNode = structure_nodes[structure_idx];
    const tag = structureNode.tag;
    const attrs = structureNode.attributes;
    const children = structureNode.children;
    const me = scope || this.me();

    // Skip whitespace-only text nodes before adopting
    advancePastWhitespace(cursor);

    // Text node
    if (structureNode.content || structureNode['*content']) {
      const domNode = cursor.parent.childNodes[cursor.childIdx++];
      if (!domNode || domNode.nodeType !== 3) {
        // Mismatch: fall back to render
        cursor.childIdx--;
        this.render(cursor.parent, structure_nodes, structure_idx, loop_item, loop_idx, scope);
        cursor.childIdx++;
        return;
      }
      if (typeof structureNode.content === 'function') {
        domNode.textContent = structureNode.content.call(me, me, loop_item, loop_idx);
        this.updatableElements.push([structureNode, domNode, scope]);
      }
      return;
    }

    if (tag === 'if') {
      // Adopt the placeholder div
      const el = cursor.parent.childNodes[cursor.childIdx++];
      if (!el || !el.hasAttribute || !el.hasAttribute('data-sp-if')) {
        cursor.childIdx--;
        this.render(cursor.parent, structure_nodes, structure_idx, loop_item, loop_idx, scope);
        cursor.childIdx++;
        // Mark elseif/else as seen
        let c_idx = structure_idx + 1;
        while (structure_nodes[c_idx]) {
          if (structure_nodes[c_idx].tag === 'elseif') {
            this.seenConditionals[c_idx] = true;
          } else if (structure_nodes[c_idx].tag === 'else') {
            this.seenConditionals[c_idx] = true;
            break;
          } else break;
          c_idx++;
        }
        return;
      }

      const ifnode = new RecipeConditional(el);
      ifnode.parentModule = this;
      ifnode.scope = scope;
      ifnode.addBranch(structureNode);
      this.updatableRecipes.push(ifnode);

      let c_idx = structure_idx + 1;
      while (structure_nodes[c_idx]) {
        if (structure_nodes[c_idx].tag === 'elseif') {
          this.seenConditionals[c_idx] = true;
          ifnode.addBranch(structure_nodes[c_idx]);
        } else if (structure_nodes[c_idx].tag === 'else') {
          this.seenConditionals[c_idx] = true;
          ifnode.addBranch(structure_nodes[c_idx]);
          break;
        } else break;
        c_idx++;
      }
      // SSR left it empty, render the active branch now
      ifnode.renderIf(loop_item, loop_idx);
      return;
    }

    if ((tag === 'elseif' || tag === 'else') && !this.seenConditionals[structure_idx]) {
      throw new Error(`'${tag}' without preceding if`);
    }

    if (this.seenConditionals[structure_idx]) return;

    // Imported component (walk parent chain for slot content imports)
    let ImportedClass = this.imports[tag];
    if (!ImportedClass) {
      let ancestor = this.parentModule;
      while (ancestor && !ImportedClass) {
        ImportedClass = ancestor.imports[tag];
        ancestor = ancestor.parentModule;
      }
    }
    if (ImportedClass) {
      const existingName = attrs['!name'];
      const existingByName = existingName && this.instances[existingName];
      const existingByNode = this._childByNode && this._childByNode.get(structureNode);
      const existingInstance = existingByName || existingByNode;

      if (existingInstance) {
        // REUSE — re-hydrate template at existing DOM location
        const componentInstance = existingInstance;
        const inst_children = componentInstance.structure.children;
        for (let idx = 0; idx < inst_children.length; idx++) {
          componentInstance.hydrate(cursor, inst_children, idx, loop_item, loop_idx);
        }
        if (children.length) {
          componentInstance.renderSlots(cursor.parent, loop_item, loop_idx);
        }
      } else {
        // FIRST TIME — create new instance
        const componentInstance = new ImportedClass();
        componentInstance._injectCss();
        componentInstance.parentModule = this;
        componentInstance.moduleId = moduleRegistry.length;
        moduleRegistry.push(componentInstance);

        if (attrs['!name']) {
          this.instances[attrs['!name']] = componentInstance;
        }
        if (!this._childByNode) this._childByNode = new Map();
        this._childByNode.set(structureNode, componentInstance);

        // Use variant structure if specified
        if (structureNode.variant && componentInstance.structures &&
            componentInstance.structures[structureNode.variant]) {
          componentInstance.structure = componentInstance.structures[structureNode.variant];
        }

        for (const [attr, val] of Object.entries(attrs)) {
          if (attr.startsWith('!')) continue;
          if (attr in componentInstance.vars) {
            componentInstance.vars[attr] = typeof val === 'function' ? val.call(me, me, loop_item, loop_idx) : val;
          }
        }
        this.updatableRecipes.push(componentInstance);

        // Components render without a wrapper — hydrate using the SAME parent cursor
        const inst_children = componentInstance.structure.children;
        for (let idx = 0; idx < inst_children.length; idx++) {
          componentInstance.hydrate(cursor, inst_children, idx, loop_item, loop_idx);
        }

        if (children.length) {
          const hasExplicitSlots = componentInstance.defaultSlot || Object.keys(componentInstance.namedSlots).length > 0;
          if (hasExplicitSlots) {
            children.forEach(slotNode => {
              componentInstance.plugin(slotNode);
            });
            componentInstance.renderSlots(cursor.parent, loop_item, loop_idx);
          } else {
            // No explicit slots: hydrate children using parent scope
            // 'this' is the parent where the component tag was written
            for (let idx = 0; idx < children.length; idx++) {
              componentInstance.hydrate(cursor, children, idx, loop_item, loop_idx, this);
            }
          }
        }

        if (componentInstance.onMount) {
          onMounts.push(() => setTimeout(() => componentInstance.onMount.call(componentInstance.me()), 0));
        }
      }
      return;
    }

    // Router link: adopt <a> at cursor, attach click handler
    if (tag === 'link') {
      const el = cursor.parent.childNodes[cursor.childIdx++];
      if (!el || el.nodeType !== 1) {
        cursor.childIdx--;
        this.render(cursor.parent, structure_nodes, structure_idx, loop_item, loop_idx, scope);
        cursor.childIdx++;
        return;
      }
      const toPath = attrs.to || '/';
      const htmlPath = (toPath === '/') ? '/' : toPath + '.html';
      el.addEventListener('click', (e) => {
        e.preventDefault();
        if (globalRouter) {
          globalRouter.navigate(toPath);
        } else {
          window.location.href = getBasePath() + htmlPath;
        }
      });
      // Hydrate children within the <a>
      const childCursor = { parent: el, childIdx: 0 };
      for (let idx = 0; idx < children.length; idx++) {
        this.hydrate(childCursor, children, idx, loop_item, loop_idx, scope);
      }
      return;
    }

    // Router view: adopt <div data-router-view> at cursor
    if (tag === 'router') {
      const el = cursor.parent.childNodes[cursor.childIdx++];
      if (!el || el.nodeType !== 1) {
        cursor.childIdx--;
        this.render(cursor.parent, structure_nodes, structure_idx, loop_item, loop_idx, scope);
        cursor.childIdx++;
        return;
      }
      this._routerViewEl = el;
      return;
    }

    // Regular tag: adopt element at cursor
    const el = cursor.parent.childNodes[cursor.childIdx++];
    if (!el || el.nodeType !== 1) {
      // Mismatch: fall back
      cursor.childIdx--;
      this.render(cursor.parent, structure_nodes, structure_idx, loop_item, loop_idx, scope);
      cursor.childIdx++;
      return;
    }

    this.rootEl = cursor.parent;

    // Attach event listeners and register dynamic attrs
    for (const [attr, val] of Object.entries(attrs)) {
      if (attr !== 'for' && attr !== 'slot') {
        if (typeof val === 'function') {
          if (attr.startsWith('on')) {
            const eventName = attr.substring(2).toLowerCase();
            const handler = (e) => { val.call(me, e, loop_item, loop_idx); this.refresh(loop_item, loop_idx); };
            el.addEventListener(eventName, handler);
            this.eventHandlers.push({ node: el, eventName, handler });
          } else {
            setAttribute(el, attr, val.call(me, me, loop_item, loop_idx));
            this.updatableElements.push([structureNode, el, scope]);
          }
        }
      }
    }

    if (attrs.for) {
      // For loop: SSR left it empty, adopt container and render normally
      const looper = new RecipeLoop(el, structureNode);
      looper.parentModule = this;
      looper.scope = scope;
      looper.renderLoop(loop_item, loop_idx);
      this.updatableRecipes.push(looper);
    } else if (tag === 'slot') {
      let recipeInstance = new RecipeSlot(el);
      recipeInstance.parentModule = this;
      if (attrs.name) {
        this.namedSlots[attrs.name] = recipeInstance;
      } else {
        this.defaultSlot = recipeInstance;
      }
    } else {
      // Recurse into children with a new child cursor
      const childCursor = { parent: el, childIdx: 0 };
      for (let idx = 0; idx < children.length; idx++) {
        this.hydrate(childCursor, children, idx, loop_item, loop_idx, scope);
      }
    }
  }

  // builds the UI
  // scope: optional override for variable resolution (used by slot content)
  render(attach_to, structure_nodes, structure_idx, loop_item, loop_idx, scope) {

    this.rootEl = attach_to;

    const structureNode = structure_nodes[structure_idx];
    const tag = structureNode.tag;

    const attrs = structureNode.attributes;
    const children = structureNode.children;
    const me = scope || this.me();
    let el;

    // check if text node. these have no children
    if (structureNode.content) {
      const con = structureNode.content;
      let text;
      if (typeof con === 'function') {
        el = document.createTextNode(con.call(me, me, loop_item,loop_idx));
        // a pair - the second refreshes the first
        this.updatableElements.push( [structureNode, el, scope ]);
      } else {
        el = document.createTextNode(con);
      }
      attach_to.append(el);
    }
 
    else if (tag === 'if') {

      const ifstruct = structure_nodes[structure_idx];
      if (!ifstruct.attributes.condition) {
        throw new Error( "if without condition attribute" );
      }

      // gets a div container
      el = document.createElement('div');
      const ifnode = new RecipeConditional(el);
      ifnode.parentModule = this;
      ifnode.scope = scope;
      ifnode.addBranch( ifstruct );
      this.updatableRecipes.push( ifnode );
      //check for elseif, else and slurp those in
      let done = false;
      let c_idx = structure_idx + 1;

      while (!done) {
        if (structure_nodes[c_idx]) {
          if (structure_nodes[c_idx].tag === 'elseif') {
            this.seenConditionals[c_idx] = true;
            const elstruct = structure_nodes[c_idx];
            if (!elstruct.attributes.condition) {
              throw new Error( "elseif without condition attribute" );
            }
            ///, loop_item, loop_idx
            ifnode.addBranch( elstruct );
          } 
          else if (structure_nodes[c_idx].tag === 'else') {
            this.seenConditionals[c_idx] = true;
            ifnode.addBranch( structure_nodes[c_idx] );
            done = true;
          }
        } else {
          done = true;
        }
        c_idx++;
      }
      attach_to.append(el);
      ifnode.renderIf(loop_item,loop_idx);
    }
    else if ((tag === 'elseif' || tag === 'else') && !this.seenConditionals[structure_idx]) {
      throw new Error( `'${tag}' without preceeding if` );
    }

    else if (!this.seenConditionals[structure_idx]) { // skip else if, else
      // the instance has slots that will be filled.
      // Handle dot notation: myzippy.clicker -> look up "myzippy.clicker" in imports
      // Walk parent chain for import resolution (slot content may reference parent imports)
      let ImportedClass = this.imports[tag];
      if (!ImportedClass) {
        let ancestor = this.parentModule;
        while (ancestor && !ImportedClass) {
          ImportedClass = ancestor.imports[tag];
          ancestor = ancestor.parentModule;
        }
      }
      if (ImportedClass) {
        const existingName = attrs['!name'];
        const existingByName = existingName && this.instances[existingName];
        const existingByNode = this._childByNode && this._childByNode.get(structureNode);
        const existingInstance = existingByName || existingByNode;

        if (existingInstance) {
          // REUSE — re-render template at new DOM location
          const componentInstance = existingInstance;
          const inst_children = componentInstance.structure.children;
          for (let idx = 0; idx < inst_children.length; idx++) {
            componentInstance.render(attach_to, inst_children, idx, loop_item, loop_idx);
          }
          // Re-plug slot content into newly created slot elements
          if (children.length) {
            children.forEach( slotNode => {
              componentInstance.plugin( slotNode );
            });
          }
          componentInstance.renderSlots(attach_to, loop_item, loop_idx);
          // NO: new instance, moduleRegistry, updatableRecipes push, onMount
        } else {
          // FIRST TIME — create new instance
          const componentInstance = new ImportedClass(el);
          componentInstance._injectCss();
          // Walk past RecipeConditional/RecipeLoop helpers to find the actual recipe
          let parent = this;
          while (parent instanceof RecipeConditional || parent instanceof RecipeLoop) {
            parent = parent.parentModule;
          }
          componentInstance.parentModule = parent;
          componentInstance.moduleId = moduleRegistry.length;
          moduleRegistry.push( componentInstance );

          // Check for !name attribute and register instance
          if (attrs['!name']) {
            this.instances[attrs['!name']] = componentInstance;
          }
          if (!this._childByNode) this._childByNode = new Map();
          this._childByNode.set(structureNode, componentInstance);

          // Use variant structure if specified
          if (structureNode.variant && componentInstance.structures &&
              componentInstance.structures[structureNode.variant]) {
            componentInstance.structure = componentInstance.structures[structureNode.variant];
          }

          // attributes become vars for ImportedClass (skip !-prefixed special attributes)
          for (const [attr,val] of Object.entries(attrs)) {
            if (attr.startsWith('!')) continue;  // Skip special attributes like !name
            if (attr in componentInstance.vars) {
              componentInstance.vars[attr] = typeof val === 'function' ? val.call(me, me, loop_item,loop_idx) : val;
            }
          }
          this.updatableRecipes.push( componentInstance );

          const inst_children = componentInstance.structure.children;
          for (let idx = 0; idx < inst_children.length; idx++) {
            componentInstance.render( attach_to, inst_children, idx, loop_item, loop_idx );
          }

          if (children.length) {

            // plug in the slots, then they can be rendered
            children.forEach( slotNode => {
              componentInstance.plugin( slotNode );
            });

            // now render the slots
            componentInstance.renderSlots(attach_to,loop_item, loop_idx);
          }
          // Call onMount lifecycle hook after DOM is ready
          if (componentInstance.onMount) {
            onMounts.push( () => setTimeout(() => componentInstance.onMount.call(componentInstance.me()), 0) );
          }
        }
      }
      else if (tag === 'link') {
        // Router link: render as <a> with click handler for SPA navigation
        el = document.createElement('a');
        const toPath = attrs.to || '/';
        const htmlPath = (toPath === '/') ? '/' : toPath + '.html';
        el.setAttribute('href', getBasePath() + htmlPath);
        el.addEventListener('click', (e) => {
          e.preventDefault();
          if (globalRouter) {
            globalRouter.navigate(toPath);
          } else {
            window.location.href = getBasePath() + toPath;
          }
        });
        attach_to.append(el);
        for (let idx = 0; idx < children.length; idx++) {
          this.render(el, children, idx, loop_item, loop_idx, scope);
        }
      }
      else if (tag === 'router') {
        // Router view placeholder
        el = document.createElement('div');
        el.setAttribute('data-router-view', '');
        attach_to.append(el);
        this._routerViewEl = el;
      }
      else if (tag === 'slot') {
        // Slot definition: register as target for projected content
        el = document.createElement('slot');
        attach_to.append(el);
        const recipeInstance = new RecipeSlot(el);
        recipeInstance.parentModule = this;
        if (attrs.name) {
          this.namedSlots[attrs.name] = recipeInstance;
        } else {
          this.defaultSlot = recipeInstance;
        }
      }
      else { // normal tag. apply attributes
        el = document.createElement(tag);
        attach_to.append( el );
        for (const [attr,val] of Object.entries(attrs)) {
          if (attr !== 'for' && attr !== 'slot') {
            if (typeof val === 'function') {
              if (attr.startsWith('on') ) {
                // Store handler info for cleanup in destroy() - addEventListener returns undefined
                const eventName = attr.substring(2).toLowerCase();
                const handler = (e) => { val.call(me,e, loop_item, loop_idx); this.refresh(loop_item, loop_idx) };
                el.addEventListener(eventName, handler);
                this.eventHandlers.push({ node: el, eventName, handler });
              } else {
                setAttribute( el, attr, val.call(me, me, loop_item,loop_idx) );
                this.updatableElements.push( [structureNode, el, scope ] );
              }
            } else {
              setAttribute( el, attr, val );
            }
          }
        }
        if (attrs.for) {
          // needs to be its own thingy for updatable purposes
          const looper = new RecipeLoop(el,structureNode);
          looper.parentModule = this;
          looper.scope = scope;
          looper.renderLoop( el, loop_item, loop_idx);
          this.updatableRecipes.push( looper );
        }
        else { //normal children
          for (let idx = 0; idx < children.length; idx++) {
            this.render( el, children, idx, loop_item, loop_idx, scope );
          }
        }
      }
    }
  } //render

  // refreshes built UI
  refresh(loop_item, loop_idx) {
    // refresh updatable elements in this recipe
    if (this.dirty) {
      for (const pair of this.updatableElements) {
        const [node, el, scope] = pair;
        const me = scope || this.me();
        if (node.content) {
          el.textContent = node.content.call(me, me, loop_item, loop_idx);
        } else {
          const attrs = node.attributes;
          for (const [attr,val] of Object.entries(attrs)) {
            if (attr !== 'for'  &&
                attr !== 'slot' &&
                !attr.startsWith('on')
                && typeof val === 'function') {
              setAttribute( el, attr, val.call(me, me, loop_item, loop_idx));
            }
          }
        }
      }
      // refresh child recipe instances
      for (const instance of this.updatableRecipes) {
        instance.refresh( loop_item, loop_idx );
      }
      this.dirty = false;
    }
  } //refresh

  destroy() {
    // Call onDestroy lifecycle hook
    if (this.onDestroy) {
      this.onDestroy.call(this);
    }
    // Remove event listeners
    for (const { node, eventName, handler } of this.eventHandlers) {
      node.removeEventListener(eventName, handler);
    }
    // Note: plural 'updatableElements' to match the property name defined on line 190
    this.updatableElements = [];
    this.updatableRecipes = [];
  } //destroy

  plugin( struct ) {
    if (struct.attributes &&
        struct.attributes.slot &&
        this.namedSlots[struct.attributes.slot]) {
      this.namedSlots[struct.attributes.slot].insert(struct);
    } else {
      if (!this.defaultSlot) {
        // if no slot defined, use the rootEl as the default slot
        this.defaultSlot = new RecipeSlot(this.rootEl);
        this.defaultSlot.parentModule = this;
      }
      this.defaultSlot.insert( struct );
    }
  }

  renderSlots(attach_to, loop_item, loop_idx ) {
    Object.values( this.namedSlots )
      .forEach( ns => ns.renderSlot(attach_to, loop_item, loop_idx) );
    this.defaultSlot && this.defaultSlot.renderSlot(attach_to, loop_item, loop_idx);
  }


} // class Recipe

class RecipeSlot extends Recipe {

  contents = [];

  me() { return this.parentModule; }

  insert( struct ) {
    this.contents.push( struct );
  }

  renderSlot(attach_to, loop_item, loop_idx) {
    const target = this.rootEl || attach_to;
    const children = this.contents;
    // Slot content resolves variables from the scope where the component was used,
    // i.e., the slot-owning component's parent (one level up)
    const scope = this.parentModule.parentModule || this.parentModule;
    for (let idx = 0; idx < children.length; idx++) {
      this.parentModule.render( target, children, idx, loop_item, loop_idx, scope );
    }
  }
} //class RecipeSlot

class RecipeLoop extends Recipe {
  constructor(el, node) {
    super(el);
    this._containerEl = el;
    this.loopNode = node;
  }
  me() {
    if (this.scope) return this.scope;
    // Walk past intermediate RC/RL helpers to find the actual Recipe component
    let p = this.parentModule;
    while (p instanceof RecipeConditional || p instanceof RecipeLoop) {
      p = p.parentModule;
    }
    return p;
  }
  renderLoop( loop_item, loop_idx ) {
    // the attributes are already adjusted for attach_to before this is called
    const forItems = this.loopNode.attributes.for.call(this.me(), this.me(), loop_item, loop_idx);
    const loopKids = this.loopNode.children;
    forItems.forEach( (l_item,l_idx) => {
      for (let idx=0; idx < loopKids.length; idx++) {
        this.render( this._containerEl, loopKids, idx, l_item, l_idx, this.scope );
      }
    } );
  }

  refresh(loop_item, loop_idx ) {
    empty(this._containerEl);
    this.renderLoop( loop_item, loop_idx );
  }
} //class RecipeLoop

class RecipeConditional extends Recipe {
  branches = [];
  lastBranchIdx = undefined;
  _containerEl = null;
  constructor(el) {
    super(el);
    this._containerEl = el;
  }
  me() {
    if (this.scope) return this.scope;
    // Walk past intermediate RC/RL helpers to find the actual Recipe component
    let p = this.parentModule;
    while (p instanceof RecipeConditional || p instanceof RecipeLoop) {
      p = p.parentModule;
    }
    return p;
  }
  addBranch( ifstruct ) {
    this.branches.push( ifstruct );
  }

  pickBranchIdx( loop_item, loop_idx ) {
    for (const idx in this.branches) {
      const branch = this.branches[idx];
      const cond = branch.attributes.condition;
      if (branch.tag === 'else' || (typeof cond  === 'function' ? cond.call( this.me(), this.me(), loop_item, loop_idx ) : cond) ) {
        return idx;
      }
    }

  }

  renderIf( loop_item, loop_idx ) {
    this.lastBranchIdx = undefined;
    const idx = this.pickBranchIdx( loop_item, loop_idx );
    if (idx !== undefined) {
      const branch = this.branches[idx];
      for (let idx = 0; idx < branch.children.length; idx++ ) {
        this.render( this._containerEl, branch.children, idx, loop_item, loop_idx, this.scope );
      }
      this.lastBranchIdx = idx;
    }
  } //renderIf

  refresh(loop_item, loop_idx ) {
    const idx = this.pickBranchIdx( loop_item, loop_idx );
    if (idx === this.lastBranchIdx) {
      if (this.lastBranchIdx !== undefined) {
        if (this.parentModule.dirty) this.dirty = true;
        super.refresh(loop_item, loop_idx);
      }
    } else {
      empty( this._containerEl );
      this.updatableElements = [];
      this.updatableRecipes = [];
      this.renderIf( loop_item, loop_idx );
    }
  }

} //class RecipeConditional
