// -*- coding: utf-8; -*-
// Package WCom.Navigation
WCom.Navigation = (function() {
   const navId  = 'navigation';
   const dsName = 'navigationConfig';
   class Navigation {
      constructor(container, config) {
         this.container        = container;
         this.moniker          = config['moniker'];
         this.properties       = config['properties'];
         this.baseURL          = this.properties['base-url'];
         this.confirm          = this.properties['confirm'];
         this.containerLayout  = this.properties['container-layout'];
         this.containerName    = this.properties['container-name'];
         this.contentName      = this.properties['content-name'];
         this.controlIcon      = this.properties['control-icon'];
         this.icons            = this.properties['icons'];
         this.linkDisplay      = this.properties['link-display'];
         this.location         = this.properties['location'];
         this.logo             = this.properties['logo'];
         this.mediaBreak       = this.properties['media-break'];
         this.skin             = this.properties['skin'];
         this.title            = this.properties['title'];
         this.titleAbbrev      = this.properties['title-abbrev'];
         this.token            = this.properties['verify-token'];
         this.version          = this.properties['version'];
         this.contentContainer = document.getElementById(this.containerName);
         this.contentPanel     = document.getElementById(this.contentName);
         this.menu             = new Menus(this, config['menus']);
         this.messages         = new Messages(config['messages']);
         this.titleEntry       = 'Loading';
         const head = (document.getElementsByTagName('head'))[0];
         this.titleElement     = head.querySelector('title');
         container.append(this.renderTitle());
         window.addEventListener('popstate', this.popstateHandler());
         window.addEventListener('resize', this.resizeHandler());
      }
      addEventListeners(container, options = {}) {
         const url = this.baseURL;
         for (const link of container.getElementsByTagName('a')) {
            const href = link.href + '';
            if (href.length && url == href.substring(0, url.length)
                && !link.getAttribute('clicklistener')) {
               const handler = this.menu.clickHandler(href, options);
               link.addEventListener('click', handler);
               link.setAttribute('clicklistener', true);
            }
         }
         for (const form of container.getElementsByTagName('form')) {
            const action = form.action + '';
            if (action.length && url == action.substring(0, url.length)
                && !form.getAttribute('submitlistener')) {
               const handler = this.menu.submitHandler(form, options);
               form.addEventListener('submit', handler);
            }
         }
      }
      popstateHandler() {
         return function(event) {
            const state = event.state;
            if (state && state.href) this.renderLocation(state.href);
         }.bind(this);
      }
      async process(action, form) {
         const options = { headers: { Prefer: 'render=partial' }, form: form };
         const { location, reload, text }
               = await this.bitch.blows(action, options);
         if (location) {
            if (reload) { window.location.href = location }
            else {
               this.renderLocation(location);
               this.messages.render(location);
            }
         }
         else if (text) { this.renderHTML(text) }
         else {
            console.warn('Neither content nor redirect in response to post');
         }
      }
      async redirectAfterGet(href, location) {
         const locationURL = new URL(location);
         locationURL.searchParams.delete('mid');
         if (locationURL != href) {
            console.log('Redirect after get to ' + location);
            await this.renderLocation(location);
            return;
         }
         const state = history.state;
         console.log('Redirect after get to self ' + location);
         console.log('Current state ' + state.href);
         let count = 0;
         while (href == state.href) {
            history.back();
            if (++count > 3) break;
         }
         console.log('Recovered state ' + count + ' ' + state.href);
      }
      render() {
         this.messages.render(window.location.href);
         this.menu.render();
         this.scan(this.contentPanel);
      }
      async renderHTML(html) {
         let className = this.containerName;
         if (this.containerLayout) className += ' ' + this.containerLayout;
         this.contentContainer.setAttribute('class', className);
         const attr = { id: this.contentName, className: this.contentName };
         const panel = this.h.div(attr);
         panel.innerHTML = html;
         await this.scan(panel);
         this.contentPanel = document.getElementById(this.contentName);
         this.contentPanel = this.display(
            this.contentContainer, 'contentPanel', panel
         );
      }
      async renderLocation(href) {
         const url = new URL(href);
         url.searchParams.delete('mid');
         const opt = { headers: { prefer: 'render=partial' }, response: 'text'};
         const { location, text } = await this.bitch.sucks(url, opt);
         if (text && text.length > 0) {
            await this.menu.loadMenuData(url);
            await this.renderHTML(text);
            this.setHeadTitle();
            this.menu.render();
         }
         else if (location) {
            this.messages.render(location);
            this.redirectAfterGet(href, location);
         }
         else {
            console.warn('Neither content nor redirect in response to get');
         }
      }
      renderTitle() {
         const title = this.logo.length ? [this.menu.iconImage(this.logo)] : [];
         title.push(this.h.span({ className: 'title-text' }, this.title));
         return this.h.div({ className: 'nav-title' }, title);
      }
      resizeHandler() {
         return function(event) {
            const linkDisplay = this.linkDisplay;
            const navigation = document.getElementById('navigation');
            const sidebar = document.getElementById('sidebar');
            const frame = document.getElementById('frame');
            const className = 'link-display-' + this.linkDisplay;
            navigation.classList.remove(className);
            sidebar.classList.remove(className);
            frame.classList.remove(className);
            if (window.innerWidth <= this.mediaBreak) {
               navigation.classList.add('link-display-icon');
               sidebar.classList.add('link-display-icon');
               frame.classList.add('link-display-icon');
               this.linkDisplay = 'icon';
            }
            else {
               const original = this.properties['link-display'];
               navigation.classList.add('link-display-' + original);
               sidebar.classList.add('link-display-' + original);
               frame.classList.add('link-display-' + original);
               this.linkDisplay = original;
            }
            if (linkDisplay != this.linkDisplay) this.menu.render();
         }.bind(this);
      }
      async scan(panel, options = {}) {
         for (const scanCallback of WCom.Util.Event.onloadCallbacks())
            await scanCallback(panel, options);
         this.addEventListeners(panel, options);
      }
      setHeadTitle() {
         const entry = this.capitalise(this.titleEntry);
         this.titleElement.innerHTML = this.titleAbbrev + ' - ' + entry;
      }
   }
   Object.assign(Navigation.prototype, WCom.Util.Bitch);
   Object.assign(Navigation.prototype, WCom.Util.Markup);
   Object.assign(Navigation.prototype, WCom.Util.String);
   class Menus {
      constructor(navigation, config) {
         this.config        = config;
         this.navigation    = navigation;
         this.container     = navigation.container;
         this.controlIcon   = navigation.controlIcon || 'settings';
         this.icons         = navigation.icons;
         this.linkDisplay   = navigation.linkDisplay;
         this.location      = navigation.location;
         this.token         = navigation.token;
         this.contextPanels = {};
         this.headerMenu;
         this.globalMenu;
      }
      addSelected(item) {
         item.classList.add('selected');
         return true;
      }
      clickHandler(href, options) {
         return function(event) {
            event.preventDefault();
            if (options.onUnload) options.onUnload();
            else {
               for (const cb of WCom.Util.Event.onunloadCallbacks()) cb();
            }
            if (options.renderLocation) options.renderLocation(href);
            else this.navigation.renderLocation(href);
         }.bind(this);
      }
      confirmHandler(name) {
         return function(event) {
            if (this.confirm) {
               if (confirm(this.confirm.replace(/\*/, name))) return true;
            }
            else if (confirm()) return true;
            event.preventDefault();
            return false;
         }.bind(this);
      }
      iconImage(icon) {
         if (icon && icon.match(/:/)) return this.h.img({ src: icon });
         else if (icon) {
            const icons = this.icons;
            if (!icons) return this.h.span({ className: 'text' }, '≡');
            return this.h.icon({ className: 'icon', icons, name: icon });
         }
         return icon;
      }
      isCurrentHref(href) {
         return history.state && history.state.href.split('?')[0]
            == href.split('?')[0] ? true : false;
      }
      async loadMenuData(url) {
         const state = { href: url + '' };
         history.pushState(state, 'Unused', url); // API Darwin award
         url.searchParams.set('navigation', true);
         const { object } = await this.bitch.sucks(url);
         if (!object || !object['menus']) return;
         this.config = object['menus'];
         this.token = object['verify-token'];
         this.navigation.containerLayout = object['container-layout'];
         this.navigation.titleEntry = object['title-entry'];
      }
      render() {
         if (!this.config) return;
         const content = [this.renderControl()];
         if (!this.config['_global']) return;
         const global = this.renderList(this.config['_global'], 'global');
         if (this.location == 'header') content.unshift(global);
         const cMenu = this.h.nav({ className: 'nav-menu' }, content);
         this.headerMenu = this.display(this.container, 'headerMenu', cMenu);
         if (this.location == 'header') return;
         const container = document.getElementById(this.location);
         const gMenu = this.h.nav({ className: 'nav-menu' }, global);
         this.globalMenu = this.display(container, 'globalMenu', gMenu);
      }
      renderControl() {
         if (!this.config['_control']) return;
         const panelAttr = { className: 'nav-panel control-panel' };
         const list = this.renderList(this.config['_control'], 'control');
         this.contextPanels['control'] = this.h.div(panelAttr, list);
         const controlAttr = { className: 'nav-control' };
         const link = this.h.a(this.renderControlIcon());
         return this.h.div(controlAttr, [link, this.contextPanels['control']]);
      }
      renderControlIcon() {
         const icons = this.icons;
         if (!icons)
            return this.h.span({ className: 'nav-control-label text' }, '≡');
         const name = this.controlIcon;
         const icon = this.h.icon({
            className: 'settings-icon', height: 24, icons, name, width: 24
         });
         return this.h.span({ className: 'nav-control-label' }, icon);
      }
      renderItem(item, menuName) {
         const [text, href, icon] = item;
         const iconImage = this.iconImage(icon);
         const title = iconImage && this.linkDisplay == 'icon' ? text : '';
         const itemAttr = { className: menuName, title };
         if (typeof text != 'object') {
            const label = this.renderLabel(icon, text);
            if (href) {
               const onclick = this.clickHandler(href, {});
               const link = this.h.a({ href, onclick }, label);
               link.setAttribute('clicklistener', true);
               return this.h.li(itemAttr, link);
            }
            const labelAttr = { className: 'drop-menu' };
            return this.h.li(itemAttr, this.h.span(labelAttr, label));
         }
         if (!text || text['method'] != 'post') return;
         const verify = this.h.hidden({ name: '_verify', value: this.token });
         const formAttr = { action: href, className: 'inline', method: 'post' };
         const form = this.h.form(formAttr, verify);
         form.addEventListener('submit', this.submitHandler(form, {}));
         const onclick = this.confirmHandler(name);
         const buttonAttr = { className: 'form-button', onclick };
         const label = this.h.span(this.renderLabel(icon, text['name']));
         form.append(this.h.button(buttonAttr, label));
         return this.h.li(itemAttr, form);
      }
      renderLabel(icon, text) {
         const iconImage = this.iconImage(icon);
         return {
            both: [iconImage, text],
            icon: iconImage ? iconImage : text,
            text: text
         }[this.linkDisplay];
      }
      renderList(list, menuName) {
         const [title, itemList] = list;
         if (!itemList.length) return this.h.span({ className: 'empty-list' });
         const items = [];
         let context = false;
         let isSelected = false;
         for (const item of itemList) {
            if (typeof item == 'string' && this.config[item]) {
               let className = 'nav-panel';
               if (menuName == 'context' || menuName == 'control')
                  className = 'slide-out';
               const rendered = this.renderList(this.config[item], 'context');
               this.contextPanels[item] = this.h.div({ className }, rendered);
               context = item;
               continue;
            }
            const listItem = this.renderItem(item, menuName);
            if (context) {
               const panel = this.contextPanels[context];
               if (panel.firstChild.classList.contains('selected'))
                  isSelected = this.addSelected(listItem);
               listItem.append(panel);
               context = false;
            }
            if (this.isCurrentHref(item[1]))
               isSelected = this.addSelected(listItem);
            items.push(listItem);
         }
         const navList = this.h.ul({ className: 'nav-list' }, items);
         if (menuName) navList.classList.add(menuName);
         if (isSelected) navList.classList.add('selected');
         return navList;
      }
      submitHandler(form, options = {}) {
         form.setAttribute('submitlistener', true);
         const action = form.action;
         return function(event) {
            event.preventDefault();
            if (options.onUnload) options.onUnload();
            else {
               for (const cb of WCom.Util.Event.onunloadCallbacks()) cb();
            }
            form.setAttribute('submitter', event.submitter.value);
            this.navigation.process(action, form);
         }.bind(this);
      }
   }
   Object.assign(Menus.prototype, WCom.Util.Bitch);
   Object.assign(Menus.prototype, WCom.Util.Markup);
   class Messages {
      constructor(config) {
         this.bufferLimit = config['buffer-limit'] || 3;
         this.displayTime = config['display-time'] || 20;
         this.messagesURL = config['messages-url'];
         this.items = [];
         this.panel = this.h.div({
            className: 'messages-panel', id: 'messages'
         });
         document.body.append(this.panel);
      }
      animate(item) {
         setTimeout(function() {
            item.classList.add('fade');
         }, 1000 * this.displayTime);
      }
      async render(href) {
         const url = new URL(href);
         const mid = url.searchParams.get('mid');
         if (!mid) return;
         const messagesURL = new URL(this.messagesURL);
         messagesURL.searchParams.set('mid', mid);
         const { object } = await this.bitch.sucks(messagesURL);
         if (!object) return;
         for (const message of object) {
            if (!message) continue;
            const item = this.h.div({ className: 'message-item' }, message);
            item.addEventListener('click', function(event) {
               item.classList.add('hide');
            });
            this.panel.append(item);
            this.items.unshift(item);
            this.animate(item);
         }
         while (this.items.length > this.bufferLimit) {
            this.items.pop().remove();
         }
      }
   }
   Object.assign(Messages.prototype, WCom.Util.Bitch);
   Object.assign(Messages.prototype, WCom.Util.Markup);
   class Manager {
      constructor() {
         this.navigator;
         WCom.Util.Event.onReady(
            function() { this.createNavigation() }.bind(this)
         );
      }
      createNavigation() {
         const el = document.getElementById(navId);
         if (!el) return;
         this.navigator = new Navigation(el, JSON.parse(el.dataset[dsName]));
         this.navigator.render();
      }
      onContentLoad() {
         if (!this.navigator) return;
         const el = document.getElementById(this.navigator.contentName);
         if (el) this.navigator.addEventListeners(el);
      }
      renderLocation(href) {
         if (this.navigator) this.navigator.renderLocation(href);
      }
      renderMessage(href) {
         if (this.navigator) this.navigator.messages.render(href);
      }
      scan(el, options) {
         if (el && this.navigator) this.navigator.scan(el, options);
      }
   }
   return {
      manager: new Manager()
   };
})();
