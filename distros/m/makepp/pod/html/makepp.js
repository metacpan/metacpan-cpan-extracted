// toggle nav bar left or right
function lr( cur ) {
  document.cookie =
    (cur.parentNode.parentNode.className = cur.parentNode.parentNode.className ? '' : 'right') ?
      'makepp_nav=right;expires=01/01/2099 00:00:00' :
      'makepp_nav=;expires=01/01/1970 00:00:00';
}

// check if nav bar should be right (in Chrome needs --enable-file-cookies)
function r() {
  if( document.cookie.indexOf('makepp_nav=right') >= 0 ) {
    document.getElementsByTagName('ul')[0].className = 'right';
  }
}

// turn off nav bar
function nonav( cur ) {
  cur.parentNode.parentNode.className = 'none';
}

// roll in or out all parts of nav bar
function roll( cur, out ) {
  var now = out ? 'fold' : 'unfold';
  var then = out ? 'unfold' : 'fold';
  var lis = cur.parentNode.parentNode.childNodes;
  for( var i = 1; i < lis.length; i++ )
    if( lis[i].className == now )
      lis[i].className = then;
}

// roll in or out current part of nav bar
function fold( cur ) {
  cur.className = (cur.className=='fold') ? 'unfold' : 'fold';
}