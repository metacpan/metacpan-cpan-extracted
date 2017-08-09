function getnav() {
  return document.getElementsByTagName('nav')[0];
}
// toggle nav bar left or right
function lr() {
  document.cookie =
    (getnav().className = getnav().className ? '' : 'right') ?
      'makepp_nav=right;expires=01/01/2099 00:00:00' :
      'makepp_nav=;expires=01/01/1970 00:00:00';
}

// check if nav bar should be right (in Chrome needs --enable-file-cookies)
function r() {
  if( document.cookie.indexOf('makepp_nav=right') >= 0 ) {
    getnav().className = 'right';
  }
}

// turn off nav bar
function nonav() {
  getnav().className = 'none';
}

// roll in or out all parts of nav bar
function roll( out ) {
  var now = out ? 'fold' : 'unfold';
  var then = out ? 'unfold' : 'fold';
  var lis = getnav().childNodes[0].childNodes;
  for( var i = 1; i < lis.length; i++ )
    if( lis[i].className == now )
      lis[i].className = then;
}

// roll in or out current part of nav bar
function fold( cur ) {
  cur.className = (cur.className=='fold') ? 'unfold' : 'fold';
}
