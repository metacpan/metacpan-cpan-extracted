// library winMenus.js
//
// version 1.02, 7-15-06 michael@bizsystems.com
// scripts adapted from Jason Cranford Teague's DHTML and CSS for the world wide web

var menuTop = 45;
var menuLeft = 400;
var domSMenu = null;
var domMenuOpt = null;
var oldDomSMenu = null;
var t = 0;
var lDelay = 5;
var lCount = 0;
var pause = 100;

function popMenu(linkNum) {
  if (isDHTML) {
    var idMenu = 'mh';
    var domMenu = finDom(idMenu,0);
    var idMenuOpt = 'L' + linkNum;
    domMenuOpt = finDom(idMenuOpt,0);
    var idSMenu = 'menu' + linkNum;
    domSMenu = finDom(idSMenu,1);

    t = 2;
    if (oldDomSMenu) {
      if (oldDomSMenu == domSMenu) {
        return null;
      }
      oldDomSMenu.visibility = 'hidden';
      oldDomSMenu.zIndex = '0';
      lCount = 0;
    }

    if(isID || isAll) {
      menuLeft = (domMenu.offsetLeft) + (domMenuOpt.offsetLeft) -5;
      menuTop = (domMenu.offsetTop) + (domMenu.offsetHeight);
    }
    if (isLayers) {
      menuLeft = document.layers[idMenu].layers[idMenuOpt].pageX -5;
      menuTop = domMenu.pageY + domMenu.clip.height -5;
    }
    if (oldDomSMenu != domSMenu) {
      domSMenu.left = menuLeft;
      domSMenu.top = menuTop;
      domSMenu.visibility = 'visible';
      domSMenu.zIndex = '100';
      oldDomSMenu = domSMenu;
    } else {
      oldDomSMenu = null;
    }
  } else {
    return null;
  }
}

function delayHide() {
  if ((oldDomSMenu) && t == 0) {
    oldDomSMenu.visibility = 'hidden';
    oldDomSMenu.zIndex = '0';
    oldDomSMenu = null;
    lCount = 0;
    return false;
  }
  if (t > 2) {
    lCount = 0;
    t = 1;
  }
  if (t == 2) {
    lCount = 0;
    return false;
  }
  lCount = lCount + 1;
  if (lDelay <= lCount)
    t = 0;

  setTimeout('delayHide()',pause);
  return true;
}

