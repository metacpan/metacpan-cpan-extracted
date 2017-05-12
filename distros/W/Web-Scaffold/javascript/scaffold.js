//
// scaffold.js   version 1.03 8-5-06
//
// COPYRIGHT AND LICENCE
//
// Copyright 2006, Michael Robinton <michael@bizsystems.com>
// 
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. 

var page = "";
function npg(page) {
  document.silent.page.value = page;
  document.silent.submit();
  return false;
}
function headOut() {
  t = 1;
  self.status = '';
  return delayHide();
}
function headOver(page,menuNum) {
  popMenu(menuNum);
  self.status = page;
  return true;
}
function linkOut() {
  t = 1;
  self.status = '';
  return delayHide();
}
function linkOver(page) {
  t = 2;
  self.status = page;
  return true;
}
function oneOver(page) {
  self.status = page;
  if (oldDomSMenu) {
    oldDomSMenu.visibility = 'hidden';
    oldDomSMenu.zIndex = '0';
    oldDomSMenu = null;
  }
  return true;
}
function linkClick(page) {
  t = 0;
  delayHide();
  return npg(page);
}
