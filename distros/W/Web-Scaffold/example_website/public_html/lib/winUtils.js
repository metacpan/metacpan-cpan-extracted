// library winUtils.js
//
// version 1.02, 3-8-05
// Copyright, Michael Robinton <michael@bizsystems.com> and others (see below)
// You may use this library for any purpose as long as it includes this
// and other required copyright notices (see below).
//

// synopsis
//
// objectTag	= finDom(object_ID, with/without_style 1/0);
// mouse	= findCoords(e); returns mouse.x, mouse.y, mouse.valid
// wp		= findWinProp(); returns wp.winx, wp.winy, wp.offx, wp.offy, wp.docx, wp.docy, wp.invalid

// Browser type
var isNS = 0;
var isOpera = 0;
var isIE = 0;
var isOtherBrowser = 0;
var isNav4 = window.Event ? true : false;
// true use passed in reference
// else use window.event

if ((navigator.appName.indexOf('Netscape')) != -1) {
  isNS = 1;
} else if ((navigator.appName.indexOf('Opera')) != -1) {
  isOpera = 1;
} else if ((navigator.appName.indexOf('MicroSoft')) != -1) {
    isIE = 0;
} else {
    isOtherBrowser = 1;
}

// DOM support
var isDHTML = 0;
var isLayers = 0;
var isAll = 0;
var isID = 0;
if (document.getElementById) {
  isID = 1; isDHTML = 1;
} else {
  if (document.all) {
    isAll = 1; isDHTML = 1;
}  else {
    browserVersion = parseInt(navigator.appVersion);
    if ((navigator.appName.indexOf('Netscape')) != -1 && (browserVersion == 4)) {
      isLayers = 1; isDHTML = 1;
    }
  }
}

// return a DOM object tag
// call as 
//	"objTag = finDom(object id, with/without style 1/0)"
//
function finDom(objID,withStyle) {
  if (withStyle == 1) {
    if (isID) {
      return (document.getElementById(objID).style);
    }
    if (isAll) {
      return (document.all[objID].style);
    }
    if (isLayers) {
      return (document.layers[objID]);
    }
  } else {
    if (isID) {
      return (document.getElementById(objID));
    }
    if (isAll) {
      return (document.all[objID]);
    }
    if (isLayers) {
      return (document.layers[objID]);
    }
  }
}

// xy mouse position
// taken from: http://evolt.org/article/Mission_Impossible_mouse_position/17/23335/index.html?format=print&rating=true&comments=true
//
// returns an object containing the event mouse coordinates and type where type is:
// usage:
//	e_coord = findCoords(e);
//	x = e_coord.x
//	y = e_coord.y
//	valid = e_coord.valid
// where valid type is:
//	-1 = no coord's found
//	 1 = pageX,Y
//	 2 = Opera, InScript, KDE w/ documentElement
//	 3 = Opera, InScript, KDE w/ body
//	 4 = just clientX,Y
//
//
/* NOTE: don't think this works right -- COMMENT OUT

function findCoords(e) {
  if( !e ) {
    e = window.event; 
  }
  var coord = new Object();
  coord.x = 0; coord.y = 0; coord.valid = -1;
  if( !e || ( typeof( e.pageX ) != 'number' && typeof( e.clientX ) != 'number' ) ) {
    return coord;
  }
  if( typeof( e.pageX ) == 'number' ) {
    coord.x = e.pageX; coord.y = e.pageY; coord.valid = 1;
    return coord;
  } 
  coord.x = e.clientX; coord.y = e.clientY; coord.valid = 4;
  if( !( ( window.navigator.userAgent.indexOf( 'Opera' ) + 1 ) || ( window.ScriptEngine && ScriptEngine().indexOf( 'InScript' ) + 1 ) || window.navigator.vendor == 'KDE' ) ) {
    if( document.documentElement && ( document.documentElement.scrollTop || document.documentElement.scrollLeft ) ) {
      coord.x += document.documentElement.scrollLeft;
      coord.y += document.documentElement.scrollTop;
      coord.valid = 2;
    } 
    else if( document.body && ( document.body.scrollTop || document.body.scrollLeft ) ) {
      coord.x += document.body.scrollLeft;
      coord.y += document.body.scrollTop;
      coord.valid = 3;
    }
  }
  return coord;
}
 */

// returns an object containing the event mouse coordinates and type where type is:
// usage:
//	e_coord = findCoords(e);
//	y = e_coord.y
//	valid = e_coord.valid
// where valid type is:
//	-1 = no coord's found
//	 1 = pageX,Y
//	 2 = clientX,Y
//	 3 = clientX,Y with pageX,Yoffset
//	 4 = clientX,Y with body.scrollLeft,Top
//	 5 = clientX,Y with documentElementscrollLeft,Top
//
function findCoords(e) {
  if (!e) {
    e = window.event;
  }
  var coord = new Object();
  coord.x = 0; coord.y = 0; coord.valid = -1;
  if (!e) {			// big OOPS!
    return coord;
  }
// for browsers that support pageX,Y just return the coords
  if (typeof(e.pageX) == 'number') {
    coord.x = e.pageX; coord.y = e.pageY;
    coord.valid = 1;
  }
  else if (typeof(e.clientX) == 'number') {
    coord.x = e.clientX; coord.y = e.clientY;
    coord.valid = 2;
    if (typeof(window.pageXoffset) == 'number') {
      coord.x += window.pageXoffset;
      coord.y += window.pageYoffset;
      coord.valid = 3; 
    }
    else if (document.body) {
      coord.x += document.body.scrollLeft;
      coord.y += document.body.scrollTop;
      coord.valid = 4;
    }
    else if (document.documentElement) {
      coord.x += document.documentElement.scrollLeft;
      coord.y +=  document.documentElement.scrollTop;
      coord.valid = 5;
    }
  }
  return coord;
}


// ******************************************************
// adapted from script at: 
// http://www.quirksmode.org/viewport/compatibility.html
//
// Copyright 2004, Peter-Paul Koch
// Page last changed 15 months ago
// This page is supposed to be in my frameset.
// 
// I don't believe in copyrights for JavaScript or CSS solutions. 
// This means my site is largely free of boring copyright notices. 
// Largely, not entirely. There are a few exceptions.
// You may
// 
// You may copy, tweak, rewrite, sell or lease any code example 
// on this site, with one single exception.
// 
// You may translate any page you like to any language you like, provided
// 
//    1. the translation will be available online free of charge
//    2. you prominently display a link to the original at the 
//       top of your translation
//    3. you send me the URL when the translation is ready. 
//       I will link to your translation from my original page
// 
// You may not
// 
// You may not copy complete pages or this entire site and put 
// them online on a publicly accessible web space. The only 
// public URL of this site is http://www.quirksmode.org
// 
// The Usable Forms script is copyrighted. It is perhaps the most 
// important script I ever wrote, not for what it does but for the 
// way it does it. Therefore I wish to claim the credits. Use it in 
// any way you like as long as you leave my copyright notice intact.
//
// ****************************************************************

// window and document position properties
// usage:
//	winprop = findWinProp();
// window size
//	x = winprop.winx
//	y = winprop.winy
// window scroll offset
//	x = winprop.offx
//	y = winprop.offy
// window document size
//	x = winprop.docx
//	y = winprop.docy
// did the script work?
// where winprop.invalid is:
//	0 = results are valid
//	1 = failed in height/width section
//	2 = failed in ofset section
//

function findWinProp() {
  var winprop = new Object();
  winprop.invalid = 0;
// window width / height as winx / winy
  if (self.innerHeight) {			// all except Explorer
    winprop.winx = self.innerWidth;
    winprop.winy = self.innerHeight;
  }
  // Explorer 6 Strict Mode
  else if (document.documentElement && document.documentElement.clientHeight) {
    winprop.winx = document.documentElement.clientWidth;
    winprop.winy = document.documentElement.clientHeight;
  }
  else if (document.body) {			// other Explorers
    winprop.winx = document.body.clientWidth;
    winprop.winy = document.body.clientHeight;
  }
  else {					// don't know
    winprop.winx = 0;
    winprop.winy = 0;
    winprop.invalid = 1;
  }
// window scroll offset offx / offy
  if (self.pageYOffset | self.pageXOffset) {	// all except Explorer
    winprop.offx = self.pageXOffset;
    winprop.offy = self.pageYOffset;
  }
  //  Explorer 6 Strict
  else if (document.documentElement && document.documentElement.scrollTop) {
    winprop.offx = document.documentElement.scrollLeft;
    winprop.offy = document.documentElement.scrollTop;
  }
  else if (document.body) {			// all other Explorers
    winprop.offx = document.body.scrollLeft;
    winprop.offy = document.body.scrollTop;
  }
  else {
    winprop.offx = 0;
    winprop.offy = 0;
    winprop.invalid = 2;
  }
// document dimensions docx / docy
//
// This is a tricky one, some browsers require scrollHeight, 
// others offsetHeight, but all browsers support both properties. 
// Therefore I see which property has the larger value. This 
// means the page height the script below gives is never smaller 
// than the window height.
//
  var test1 = document.body.scrollHeight;
  var test2 = document.body.offsetHeight
  if (test1 > test2) {				// all but Explorer Mac
    winprop.docx = document.body.scrollWidth;
    winprop.docy = document.body.scrollHeight;
  }
  else { // Explorer Mac, would also work in Explorer 6 Strict, Mozilla and Safari
    winprop.docx = document.body.offsetWidth;
    winprop.docy = document.body.offsetHeight;
  }
  return winprop;
}
