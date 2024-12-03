// -*- coding: utf-8; -*-
// Package WCom.Modal
WCom.Modal = (function() {
   const keyCodes = { enter: 13, escape: 27 };
   const modalList = (() => {
      let modals = [];
      return {
         add(id) {
            if (modals.indexOf(id) === -1) modals.push(id);
         },
         isTopModal(id) {
            return modals[modals.length - 1] === id;
         },
         remove(id) {
            modals = modals.filter(m => m !== id);
         }
      }
   })();
   class Backdrop {
      constructor(options) {
         this.popupBackground = null;
         this.popupContainer = null;
         if (options) this.zIndex = opts.zIndex || null;
      }
      add(el) {
         this.popupContainer = this.h.div({
            className: 'modal-container out'
         }, el);
         this.popupBackground = this.h.div({
            className: 'modal-outer-wrapper',
            style: this.zIndex ? `z-index: ${this.zIndex}` : ''
         }, this.popupContainer);
         document.body.appendChild(this.popupBackground);
         setTimeout(() => {
            this.popupContainer.classList.add('in');
            this.popupContainer.classList.remove('out');
         }, 50);
      }
      remove(el) {
         if (!el) return;
         const popupParent = this.popupBackground.parentNode;
         if (popupParent) popupParent.removeChild(this.popupBackground);
         const elParent = el.parentNode;
         elParent.classList.add('out');
         elParent.classList.remove('in');
      }
   }
   Object.assign(Backdrop.prototype, WCom.Util.Markup);
   class Button {
      buttonConfig;
      constructor(args = {}) {
         const isButton = !args.url;
         const type = isButton ? 'button' : 'a';
         let classes = 'button';
         if (args.modifiers) {
            classes += args.modifiers.map(m => ` button-${m}`).join('');
         }
         const attrs = { className: classes };
         ['id', 'onclick', 'title', 'type'].forEach((a) => {
            if (args[a]) attrs[a] = args[a];
         });
         if (args.data) {
            for (const a of Object.keys(args.data))
               attrs[`data-${a}`] = args.data[a];
         }
         if (!isButton) attrs.href = args.url;
         this.text = document.createTextNode(args.text || '');
         this.elm = this.h[type](attrs, this.h.span([this.text]));
         if (args.parent) args.parent.appendChild(this.elm);
      }
      activate() {
         this.elm.classList.add('button-active');
      }
      deactivate() {
         this.elm.classList.remove('button-active');
      }
      disable() {
         this.elm.disabled = true;
      }
      element() {
         return this.elm;
      }
      enable() {
         this.elm.disabled = false;
      }
      updateText(text) {
         this.text.nodeValue = text;
      }
   }
   Object.assign(Button.prototype, WCom.Util.Markup);
   class Drag {
      constructor(args) {
         this.drag = {};
         this.dragNodeX = null;
         this.dragNodeY = null;
         this.scrollWrapper = document.querySelector(args.scrollWrapper);
      }
      autoScrollHandler(event) {
         const { drag } = this;
         const threshold = drag.autoScroll;
         if (!threshold || threshold < 1) return;
         const y = event.pageY;
         const body = document.body;
         const minY = body.scrollTop;
         const maxY = minY + drag.viewportHeight;
         let scrollDirection = 'noScroll';
         if (y + threshold > maxY) scrollDirection = 'down';
         if (y - threshold < minY) scrollDirection = 'up';
         if (drag.scrollDirection !== scrollDirection) {
            drag.scrollDirection = scrollDirection;
            setScrollInterval();
         }
      }
      clearScrollInterval() {
         if (this.drag.scrollInterval) clearInterval(this.drag.scrollInterval);
      }
      dragHandler(event, options = {}) {
         const { drag } = this;
         if (drag.autoScroll) this.autoScrollHandler(event);
         if (drag.moveCallback) drag.moveCallback(event, drag.dragNode);
         if (drag.updateDropNodePositions) this.updateDropNodePositions();
         this.dragNodeX = event.pageX;
         this.dragNodeY = event.pageY;
         if (drag.fixLeft) this.dragNodeX = drag.fixLeft;
         const { constraints } = drag;
         if (constraints) {
            if (constraints.top)
               this.dragNodeY = Math.max(this.dragNodeY, constraints.top);
            if (constraints.bottom)
               this.dragNodeY = Math.min(this.dragNodeY, constraints.bottom);
            if (constraints.left)
               this.dragNodeX = Math.max(this.dragNodeX, constraints.left);
            if (constraints.right)
               this.dragNodeX = Math.min(this.dragNodeX, constraints.right);
         }
         this.updateHoveredNode(event);
         if (drag.dragNodeOffset) {
            this.dragNodeX -= drag.dragNodeOffset.x;
            this.dragNodeY -= drag.dragNodeOffset.y;
         }
         if (drag.dragNode) {
            drag.dragNode.style.left = this.dragNodeX + 'px';
            drag.dragNode.style.top = this.dragNodeY + 'px';
         }
      }
      dropHandler(event) {
         const { drag } = this;
         if (drag.currentDropNode)
            this.leaveHandler(event, drag.currentDropNode);
         if (drag.dropCallback)
            drag.dropCallback(drag.currentDropNode, drag.dragNode);
         this.stopDrag();
      }
      hoverHandler(event, node) {
         const { drag } = this;
         if (drag.hoverClass) node.classList.add(drag.hoverClass);
         if (drag.hoverCallback) drag.hoverCallback(node, drag.dragNode, true);
      }
      leaveHandler(event, node) {
         const { drag } = this;
         if (drag.hoverClass) node.classList.remove(drag.hoverClass);
         if (drag.hoverCallback) drag.hoverCallback(node, drag.dragNode, false);
      }
      scrollHandler(event) {
         this.updateDropNodePositions();
         this.updateHoveredNode(event);
      }
      setScrollInterval() {
         this.clearScrollInterval();
         const { drag } = this;
         if (drag.scrollDirection === 'noScroll') return;
         const scrollByValue = drag.scrollDirection === 'down'
               ? drag.autoScrollStep : -drag.autoScrollStep;
         drag.scrollInterval = setInterval(function() {
            this.scrollWrapper.scrollBy(0, scrollByValue);
         }.bind(this), drag.autoScrollSpeed);
      }
      start(event, options = {}) {
         if (!event) throw new Error('Event not specified');
         event.preventDefault();
         this.stopDrag();
         const autoScroll = options.autoScroll === true
               ? 80 : options.autoScroll || false;
         this.drag = {
            autoScroll: autoScroll,
            autoScrollSpeed: options.autoScrollSpeed || 10,
            autoScrollStep: options.autoScrollStep || 5,
            constraints: options.constraints,
            currentDropNode: null,
            documentHeight: this.h.getDimensions(document).height,
            dragNode: options.dragNode,
            dragNodeOffset: options.dragNodeOffset,
            dropCallback: options.dropCallback,
            dropNodes: options.dropTargets || {},
            fixLeft: options.fixLeft,
            hoverCallback: options.hoverCallback,
            hoverClass: options.hoverClass,
            moveCallback: options.moveCallback,
            viewportHeight: this.h.getDimensions(window).height
         };
         const { drag, scrollWrapper } = this;
         if (options.offsetDragNode) {
            const position = this.h.getOffset(event.target);
            drag.dragNodeOffset = {
               x: event.pageX - position.left,
               y: event.pageY - position.top,
            };
         }
         if (drag.dragNode) drag.dragNode.style.position = 'absolute';
         document.addEventListener('mousemove', this.dragHandler.bind(this));
         document.addEventListener('mouseup', this.dropHandler.bind(this));
         document.addEventListener('wheel', this.wheelHandler.bind(this));
         scrollWrapper.addEventListener('scroll', this.scrollHandler.bind(this));
         this.updateDropNodePositions();
         this.dragHandler(event);
      }
      state() {
         return this.drag;
      }
      stopDrag() {
         this.scrollWrapper.removeEventListener('scroll', this.scrollHandler);
         document.removeEventListener('wheel', this.wheelHandler);
         document.removeEventListener('mouseup', this.dropHandler);
         document.removeEventListener('mousemove', this.dragHandler);
         this.clearScrollInterval();
         const { drag } = this;
         if (drag.dragNode) {
            drag.dragNode.style.left = null;
            drag.dragNode.style.position = null;
            drag.dragNode.style.top = null;
         }
         this.drag = {};
      }
      updateDropNodePositions() {
         const { drag } = this;
         drag.dropNodePositions = [];
         drag.dropNodes.forEach(function(node) {
            const offsets = this.h.getOffset(node);
            const dimensions = this.h.getDimensions(node);
            drag.dropNodePositions.push({
               bottom: offsets.top + dimensions.height,
               left: offsets.left,
               node: node,
               right: offsets.left + dimensions.width,
               top: offsets.top
            });
         }.bind(this));
         drag.updateDropNodePositions = false;
      }
      updateHoveredNode(event) {
         let hoveredNode = null;
         const { drag, dragNodeX, dragNodeY } = this;
         drag.dropNodePositions ||= [];
         for (const target of drag.dropNodePositions) {
            if (dragNodeX > target.left
                && dragNodeX < target.right
                && dragNodeY > target.top
                && dragNodeY < target.bottom
                && target.node[0] != drag.dragNode[0]) {
               hoveredNode = target;
               break;
            }
         }
         if (hoveredNode != drag.currentDropNode) {
            if (drag.currentDropNode)
               this.leaveHandler(event, drag.currentDropNode);
            if (hoveredNode) this.hoverHandler(event, hoveredNode);
            drag.currentDropNode = hoveredNode;
         }
      }
      wheelHandler(event) {
         this.scrollWrapper.scrollBy(0, Math.floor(event.deltaY / 7));
      }
   }
   Object.assign(Drag.prototype, WCom.Util.Markup);
   class Modal {
      constructor(title, content, buttons, setup) {
         this.buttonClass = setup.buttonClass;
         this.buttons = buttons;
         this.classList = setup.classList;
         this.closeCallback = setup.closeCallback;
         this.content = content;
         this.dragScrollWrapper = setup.dragScrollWrapper || '.standard';
         this.icons = setup.icons;
         this.ident = this.guid();
         this.open = true;
         this.resizeElement = setup.resizeElement;
         this.title = title;
         modalList.add(this.ident);
         this.keyHandler = this.keyHandler.bind(this);
         window.addEventListener('keydown', this.keyHandler);
      }
      buttonHandler(buttonConfig) {
         if (buttonConfig.onclick(this) !== false) this.close();
      }
      close() {
         if (!this.open) return;
         this.open = false;
         modalList.remove(this.ident);
         window.removeEventListener('keydown', this.keyHandler);
         this.backdrop.remove(this.el);
         this.backdrop = null;
         if (this.closeCallback) this.closeCallback();
      }
      keyHandler(event) {
         const { keyCode } = event;
         if (!modalList.isTopModal(this.ident)) return;
         const btn = this.buttons.find(b => b.key && keyCodes[b.key] === keyCode);
         if (btn) this.buttonHandler(btn);
         else if (keyCode === keyCodes['escape']) this.close();
      }
      render() {
         const classes = this.classList || '';
         this.el = this.h.div({ className: 'modal ' + classes });
         this.modalHeader = this.h.div({
            className: 'modal-header', onmousedown: this._clickHandler(this.el)
         }, [
            this.h.h1({ className: 'modal-title' }, this.title),
            this._createCloseIcon()
         ]);
         this.modalHeader.setAttribute('draggable', 'draggable');
         this.el.appendChild(this.modalHeader);
         this.content = this.h.div(
            { className: 'modal-content-wrapper' },
            this.h.div({ className: 'modal-content' }, this.content)
         );
         this.el.appendChild(this.content);
         if (this.buttons.length) this._renderButtons(this.el);
         this.backdrop = new Backdrop();
         this.backdrop.add(this.el);
      }
      _createCloseIcon() {
         const attr = {
            className: 'button-icon modal-close',
            onclick: function(event) {
               event.preventDefault();
               this.close();
            }.bind(this)
         };
         const icons = this.icons;
         if (!icons) return this.h.span(attr, 'X');
         return this.h.span(attr, this.h.icon({
            className: 'close-icon', icons, name: 'close'
         }));
      }
      _clickHandler(el) {
         return function(event) {
            if (event.target.tagName === 'BUTTON') return;
            if (event.target.tagName === 'SPAN') return;
            const { left, top } = this.modalHeader.getBoundingClientRect();
            const { scrollTop } = document.documentElement || document.body;
            const drag = new Drag({ scrollWrapper: this.dragScrollWrapper });
            drag.start(event, {
               dragNode: el,
               dropTargets: [],
               dragNodeOffset: {
                  x: event.clientX - left,
                  y: (event.clientY + scrollTop) - top
               }
            });
         }.bind(this);
      }
      _renderButtons(el) {
         this.buttonBox = this.h.div({ className: 'modal-footer' });
         if (this.resizeElement) {
            const resizeSouth = this.h.div({ className: 'resize-south' });
            const resizeSE = this.h.div({ className: 'resize-south-east' });
            this.buttonBox.appendChild(resizeSouth);
            this.buttonBox.appendChild(resizeSE);
            new Resizer(resizeSouth, this.resizeElement, el, { v: true });
            new Resizer(
               resizeSE, this.resizeElement, el,
               { h: true, v: true }, { w: 320 }
            );
         }
         this.buttons.forEach((button, i) => {
            const modifiers = [];
            if (this.buttons.length >= 2 && !button.greyButton && !i)
               modifiers.push(this.buttonClass || 'primary');
            const onclick = () => this.buttonHandler(button);
            const buttonEl = new Button({
               modifiers, onclick, parent: this.buttonBox, text: button.label
            }).element();
            buttonEl.buttonConfig = button;
         });
         this.animateButtons(this.buttonBox);
         el.appendChild(this.buttonBox);
      }
   }
   Object.assign(Modal.prototype, WCom.Util.Markup);
   Object.assign(Modal.prototype, WCom.Util.String);
   class ModalUtil {
      constructor(args, onSubmit) {
         const {
            formClass = 'classic',
            icons = '/icons.svg',
            initValue,
            url,
            valueStore = {}
         } = args;
         this.icons = icons;
         this.url = url;
         this.formClass = formClass;
         this.initValue = initValue;
         this.valueStore = valueStore;
         this.onSubmit = onSubmit;
      }
      createModalContainer() {
         const spinner = this._createSpinner();
         const loader = this.h.div({ className: 'modal-loader' }, spinner);
         this.frame = this.h.div({
            className: 'selector',
            id: 'selector-frame',
            style: 'visibility:hidden;'
         });
         const container = this.h.div(
            { className: 'modal-frame-container' }, [loader, this.frame]
         );
         const options = {
            formClass: this.formClass,
            onSubmit: this.onSubmit,
            renderLocation: function(href) {
               this._loadFrameContent(href);
            }.bind(this)
         };
         this.selector = new Selector(this.frame);
         this.onload = function() {
            loader.style.display = 'none';
            const selector = this.selector;
            if (this.initValue)
               selector.setModalValue(this.initValue, this.valueStore);
            for (const anchor of this.frame.querySelectorAll('a')) {
               anchor.addEventListener('click', function(event) {
                  this.valueStore = selector.setValueStore(this.valueStore);
                  this.initValue = this.valueStore.value;
               }.bind(this));
            };
            WCom.Navigation.manager.scan(this.frame, options);
            this.frame.style.visibility = 'visible';
         }.bind(this);
         this._loadFrameContent(this.url);
         return container;
      }
      getModalValue(success) {
         return this.selector.getModalValue(success);
      }
      _createSpinner(modifierClass = '') {
         const icon = this.h.icon({
            name: 'spinner', className: 'loading-icon', icons: this.icons
         });
         return this.h.span({
            className: `loading ${modifierClass}`
         }, this.h.span({ className: 'loading-spinner' }, icon));
      }
      async _loadFrameContent(url) {
         const opt = { headers: { prefer: 'render=partial' }, response: 'text'};
         const { location, text } = await this.bitch.sucks(url, opt);
         if (text && text.length > 0) {
            this.frame.innerHTML = text;
         }
         else if (location) {
            // TODO: Deal with
         }
         else {
            console.warn('Neither content nor redirect in response to get');
         }
         if (this.onload) this.onload();
      }
   }
   Object.assign(ModalUtil.prototype, WCom.Util.Bitch);
   Object.assign(ModalUtil.prototype, WCom.Util.Markup);
   class Resizer {
      constructor(el, resizeEl, alsoResize, dir) {
         el.addEventListener('mousedown', function(event) {
            this.startDrag(event, resizeEl, alsoResize, dir.h, dir.v)
         }.bind(this));
         this.drag = {};
      }
      dragHandler(event) {
         event.preventDefault();
         const { drag } = this;
         if (drag.h) {
            const width = Math.max(0, drag.width + event.pageX - drag.x);
            drag.resizeEl.style.width = width + 'px';
         }
         if (drag.v) {
            const height = Math.max(0, drag.height + event.pageY - drag.y);
            drag.resizeEl.style.height = height + 'px';
         }
         if (drag.alsoResize) {
            drag.alsoResize.each(function() {
               if (this != drag.resizeEl[0]) {
                  if (drag.h) this.style.width = width + 'px';
                  if (drag.v) this.style.height = height + 'px';
               }
            });
         }
      }
      startDrag(event, resizeEl, alsoResize, h, v) {
         event.preventDefault();
         const style = {
            height: '100px', position: 'absolute',
            width: window.getComputedStyle(resizeEl).width
         };
         const shim = this.h.div({ style: style });
         shim.insertBefore(event.target);
         const dimensions = this.h.getDimensions(resizeEl);
         this.drag = {
            alsoResize: alsoResize, h: h, height: dimensions.height,
            resizeEl: resizeEl, shim: shim, v: v, width: dimensions.width,
            x: event.pageX, y: event.pageY
         }
         document.addEventListener('mousemove', this.dragHandler.bind(this));
         document.addEventListener('mouseup', function(event) {
            if (this.drag.shim) {
               this.drag.shim.remove();
               delete this.drag.shim;
            }
            document.removeEventListener('mousemove', this.dragHandler);
         }.bind(this));
      }
   }
   Object.assign(Resizer.prototype, WCom.Util.Markup);
   class Selector {
      constructor(frame) {
         this.frame = frame;
         this.tableClass = 'state-table';
         this.displayAttribute = 'object_display';
      }
      getModalValue(success) {
         if (!success) return null;
         const els = this._selectionEls();
         const selected = [];
         const values = [];
         for (const el of els) {
            if (el.checked) selected.push(el);
            values.push(el.value);
         }
         if (this.type == 'checkbox') {
            this.valueStore = {
               display: null,
               value: this._removeUnchecked(this._addIDs(selected), els)
            };
         }
         else if (this.type == 'radio') {
            if (selected && selected.length > 0) {
               this.valueStore = {
                  display: selected[0].getAttribute(this.displayAttribute),
                  value: selected[0].value
               };
            }
            if (this.valueStore && this.valueStore.value !== undefined) {
               const tempHash = {};
               tempHash[this.valueStore.value] = 1;
               this.valueStore = {
                  display: this.valueStore.display,
                  value: this._removeUnchecked(tempHash, els)
               };
            }
            else this.valueStore = null;
         }
         else if (this.type == 'text') {
            this.valueStore = { display: null, value: values };
         }
         else if (this.type == 'file') {
            this.valueStore = { display: null, files: els[0].files };
         }
         return this.valueStore;
      }
      setModalValue(value, valueHash) {
         if (!value) return;
         this.valueStore = valueHash;
         const values = value.split(',');
         WCom.Modal.clientTablePrecheckedValues = values;
         let el;
         if (this.type === 'radio') {
            for (const selected of this._selectionEls()) {
               if (selected.value == value) {
                  el = selected;
                  break;
               }
            }
         }
         else {
            for (const selected of this._selectionEls()) {
               if (values.includes(selected.value)) {
                  el = selected;
                  break;
               }
            }
         }
         if (!el) return;
         el.setAttribute('checked', false);
         el.click();
      }
      setValueStore(valueStore) {
         this.valueStore = valueStore;
         return this.getModalValue(true);
      }
      _addIDs(selected) {
         const values = this.valueStore && this.valueStore.value
               ? this.valueStore.value.split(',') : [];
         const newValues = [];
         if (selected && selected.length > 0) {
            for (const el of selected) newValues.push(el.value);
         }
         const valueHash = {};
         if (values.length || newValues.length) {
            for (const v of [...values, ...newValues]) valueHash[v] = v;
         }
         return valueHash;
      }
      _removeUnchecked(values, els) {
         if (values.length === 0) return '';
         for (const el of els) {
            if (values[el.value] && !el.checked) delete values[el.value];
         }
         return Object.keys(values).join(',');
      }
      _selectionEls() {
         let pattern = 'input[type=';
         const table = this.frame.querySelector('.' + this.tableClass);
         if (table) pattern = '.' + this.tableClass + ' ' + pattern;
         const selector = this.frame.querySelectorAll.bind(this.frame);
         if (this.type !== undefined) {
            return selector(pattern + this.type + ']');
         }
         let els = selector(pattern + 'radio]');
         if (els && els.length > 0) {
            this.type = 'radio';
            return els;
         }
         els = selector(pattern + 'checkbox]');
         if (els && els.length > 0) {
            this.type = 'checkbox';
            return els;
         }
         els = selector(pattern + 'text]');
         if (els && els.length > 0) {
            this.type = 'text';
            return els;
         }
         els = selector(pattern + 'file]');
         if (els && els.length > 0) {
            this.type = 'file';
            return els;
         }
         throw new Error(
            'Selectors need either a radio, checkbox, text, or file input'
         );
      }
   }
   const create = function(args) {
      const {
         buttonClass,
         callback = () => {},
         cancelCallback,
         classList = false,
         labels = ['Cancel', 'OK'],
         noButtons = false,
         title,
         validateForm
      } = args;
      let modal;
      const onSubmit = function(event) { modal.close() };
      const util = new ModalUtil(args, onSubmit);
      const container = util.createModalContainer();
      let buttons = [];
      if (!noButtons) {
         buttons = [{
            label: labels[0],
            onclick(modalObj) {
               try { callback(false, modalObj, util.getModalValue(false))}
               catch(e) {}
               if (cancelCallback) return cancelCallback();
               return true;
            }
         }, {
            label: labels[1],
            onclick(modalObj) {
               const modalValue = util.getModalValue(true);
               if (validateForm && !validateForm(modalObj, modalValue))
                  return false;
               return callback(true, modalObj, modalValue);
            }
         }];
      }
      const options = {
         buttonClass, classList, icons: util.icons, noInner: true
      };
      if (args.closeCallback) options.closeCallback = args.closeCallback;
      modal = new Modal(title, container, buttons, options);
      modal.render();
      return modal;
   };
   return {
      create,
      createAlert: function(args) {
         const {
            callback = () => {},
            classList,
            icon = 'info',
            label = 'Okay',
            text = '',
            title
         } = args;
         const content = document.createElement('div');
         content.classList.add(`popup-alert-${icon}`);
         content.appendChild(document.createTextNode(text));
         const buttons = [{ label, onclick: callback }];
         const options = { animate: 'jump', fadeSpeed: 200, classList };
         const modal = new Modal(title, content, buttons, options);
         modal.render();
         return modal;
      },
      createSelector: function(args) {
         const { icons, onchange, target, title = 'Select Item', url } = args;
         const callback = function(ok, modal, result) {
            if (!ok) return;
            const el = document.getElementById(target);
            const newValue = result.value.replace(/!/g, '/');
            if (onchange && el.value != newValue)
               eval(onchange.replace(/%value/g, result.value));
            el.value = newValue;
            if (el.focus) el.focus();
         }.bind(this);
         return create({ callback, icons, title, url });
      }
   };
})();
