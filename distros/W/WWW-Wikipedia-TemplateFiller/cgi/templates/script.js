function changeType(p) {
  var curType = p.options[p.selectedIndex].value;
}

function hideElem(id) {
  e(id).style.display = 'none';
}

function showElem(id) {
  e(id).style.display = 'inline';
}

function e(id) { return document.getElementById(id) }
