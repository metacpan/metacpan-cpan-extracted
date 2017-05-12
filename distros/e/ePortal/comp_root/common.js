var ErrorDisplayedOnce = false;

function open_acl_window(id,ref)
{
//	window.showModalDialog('/acl.htm?objid='+id+'&objtype='+ref,'',
//		'status:no;center:yes;help:no;minimize:no;maximize:no;border:thin;statusbar:no;dialogWidth:300px;dialogHeight:225px');
	var remote = window.open('/acl.htm?objid='+id+'&objtype='+ref, 'acl_window', 
		'width=350,height=260,left=100,top=150,resizable=yes,scrollbars=no,status=0,toolbar=0,location=no,menubar=0');
	if (remote != null)	{
		if (remote.opener == null)
			remote.opener = self;
	}
	if (navigator.appVersion.charAt(0) == 4) {
		remote.focus();
	}

}

/*
 DateSelector used to pick up a date from popup calendar.
 See Support.pm::htmlField() for details.
 Parameters:
 	field_name - name of field in the form
 	form_name - (optional) a form name. If empty then first form of 
	the document is used.
 */
function DateSelector(field_name, form_name)
{
	var theForm;
	if (form_name != '') {
		theForm = document.forms[form_name];
	}
	if ( theForm == null ) {
		theForm = document.forms[0];
		if ( theForm == null ) { return; }
	}

	var control = theForm.elements[field_name];
	if ( control == null ) {
		alert('Form element ' + field_name + ' not found');
		return;
	}

	var remote=window.open('/popup/calendar.htm?field='+field_name+'&cal_date='+control.value,
		'calendar', 'width=160,height=160,left=200,top=150,resizable=yes,scrollbars=no,status=0,toolbar=0,location=no,menubar=0');
	//var remote=window.showModalDialog('/popup/calendar.htm?field='+field_name+'&value='+control.value,
	//	null, 'width=160,height=160,left=200,top=150,resizable=yes,scrollbars=no,status=0,toolbar=0,location=no,menubar=0');

	if (remote != null)	{
		if (remote.opener == null)
			remote.opener = self;
		remote.focus();
	}
}
/*
 This is continuation of DateSelector(). This function is used to
 store chusen date from calendar to form element.
 */
function SelectDate(field, date_value)
{
	if ( window.opener == null ) return;
	if ( window.opener.document == null ) return;
	
	var control = window.opener.document.all(field);
	if ( control != null ) {
		control.value = date_value;
		control.focus();
	}
	window.close();
}

/*****************************************************************
	This function is used for on-line date validation and correction
 Parameters:
 	field_name - name of field in the form
 	form_name - (optional) a form name. If empty then first form of 
	the document is used.
*****************************************************************/
function ValidateDate( field_name, form_name ) {
	var theForm;
	var now = new Date();

	if (form_name != '') {  theForm = document.forms[form_name];	}
	if ( theForm == null ) {theForm = document.forms[0];	}

	var control = theForm.elements[field_name];
	if ( control == null ) {
		alert('Form element ' + field_name + ' not found');
		return;
	}

	// Empty field
	var old_value = control.value;
	if ( old_value == '' ) {	return;	}

	// Replace all separators with '.'
	old_value = str_replace(old_value, ',', '.');
	old_value = str_replace(old_value, '-', '.');
	old_value = str_replace(old_value, '/', '.');
	old_value = str_replace(old_value, ':', '.');
	old_value = str_replace(old_value, ' ', '');

	// Get date parts
	var day_num = _get_date_part(old_value, 1, now.getDate());
	var mon_num = _get_date_part(old_value, 2, now.getMonth()+1);
	var year_num = _get_date_part(old_value, 3, now.getFullYear());

	// adjust date parts with proper values
  if ( year_num < 70 ) { year_num = 2000 + year_num*1; }
	if ( year_num < 100 ){ year_num = 1900 + year_num*1; }
	if ( year_num < 1000){ year_num = 1000 + year_num*1; }

	if ( day_num > 31 || mon_num > 12) {
		alert("Дата введена неправильно");
		control.focus();
		return;
	}

	control.value = day_num + '.' + mon_num + '.' + year_num;
}  // ValidateDate



/*****************************************************************
	This function is used for on-line date validation and correction
 Parameters:
 	field_name - name of field in the form
 	form_name - (optional) a form name. If empty then first form of 
	the document is used.
*****************************************************************/
function ValidateTime( field_name, form_name ) {
	var theForm;
	var now = new Date();

	if (form_name != '') { theForm = document.forms[form_name];	}
	if ( theForm == null ) { theForm = document.forms[0];	}

	var control = theForm.elements[field_name];
	if ( control == null ) {
		alert('Form element ' + field_name + ' not found');
		return;
	}

	// Empty field
	var old_value = control.value;
	if ( old_value == '' ) {	return;	}

	// Replace all separators with '.'
	old_value = str_replace(old_value, ',', ':');
	old_value = str_replace(old_value, '.', ':');
	old_value = str_replace(old_value, '-', ':');
	old_value = str_replace(old_value, '/', ':');
	old_value = str_replace(old_value, ' ', '');

	// Get date parts
	var hour_num = _get_date_part(old_value, 1, now.getHours()+1);
	var min_num = _get_date_part(old_value, 2, 0); //now.getMinutes()+1);
	var sec_num = _get_date_part(old_value, 3, 0); //now.getSeconds()+1);

	if ( hour_num > 23 || min_num > 59 || sec_num > 59) {
		alert("Время введено неправильно");
		control.focus();
		return;
	}

	control.value = hour_num + ':' + min_num + ':' + sec_num;
}  // ValidateTime

// Internal function
function _get_date_part( date_string, part_number, default_value ) {
	var pos, found;
	while ( true ) {
		pos = date_string.indexOf('.');
		if ( pos == -1 ) { pos = date_string.indexOf(':'); }

		if ( pos == -1) {
			if ( part_number <= 1 ) {
				found = date_string;
				break;
			} else {
				found =  null;
				break;
			}
		}
		if ( part_number <= 1 ) {
			found = date_string.substring(0,pos);
			break;
		}
		part_number = part_number - 1;
		date_string = date_string.substr(pos+1);
	}

	if ( found == null || found == 0 || isNaN(found)) {
		found = default_value;
	} 
	found = found * 1;

	if ( found < 10 ) {
		found = '0' + found;
	}

	return found;
}  // _get_date_part



/*****************************************************************
	str - source string
 str1 - what to find
 str - replace to 
*****************************************************************/
function str_replace( str, str1, str2 ) {
	var pos;
	do {
		pos = str.indexOf(str1);
		if ( pos >= 0 ) {
			str = str.substring(0,pos) + str2 + str.substr(pos + str1.length);
		}
	} while (pos >= 0)
	return str;
}  // str_replace

/*******************************************************************
 CheckAll( (true|false), ['form_name'] )
 Checks or unchecks all checkboxes in the form. If no form_name is 
 given then 'theForm' is implied
 */
function CheckAll(checked, form_name) {
	var i, the_form;
	if ( form_name == '' ) {
		form_name = 'theForm';
	}
	the_form = document.forms[form_name];
	if ( the_form == null ) {
		return;
	}

	for (i=0; the_form.elements[i]; i++) {
		if (the_form.elements[i].type == "checkbox" &&
			the_form.elements[i].name == "list_chbox") {
				the_form.elements[i].checked = checked;
		}
	}
}


/*
 Tree manipulation
 */

var img_plus = new Image();
img_plus.src = "/images/ePortal/plus.gif";
var img_minus = new Image();
img_minus.src = "/images/ePortal/minus.gif";

/* -----------------19.10.2001 9:59------------------
srcID - is ID of tree branch
expand = [1|0|null] if null then turn
 Image with id of srcIDi will be loaded with new src (plus or minus)
 SPAN with id of srcIDs will be hidden or shown
 --------------------------------------------------*/
function expand_tree(srcID, expand) {
  var e, i, item;

	if ( srcID == 'all' ) {	// expand or collapse all items
			// Iterate images with id like 'TR#_###i'
		for(i=0; i<document.images.length; i++) {
			item = document.images[i];
			if ( item != null && 
						item.id.length > 0 &&
						item.id.substr(0,2) == 'TR' && 
						item.id.substr(item.id.length-1,2) == 'i') {
				expand_tree(item.id.substring(0, item.id.length-1), expand);
			}
		}
		// End with 'all'
		return;
	}

	e = document.all(srcID + 's');
	i = document.all(srcID + 'i');

	if (e == null) { 
		if (ErrorDisplayedOnce) {return;}
		ErrorDisplayedOnce = true;
		alert('span ' + srcID + ' not found'); 
		return; 
	}
	if (i == null) { 
		if (ErrorDisplayedOnce) {return;}
		ErrorDisplayedOnce = true;
		alert('image ' + srcID + 'not found'); 
		return; 
	}

	if ( expand == null ) {	// turn expand|collapse
  	if (e.style.display == "none") {			
			expand = 1;
		} else {
			expand = 0;
		}
	}

  if (expand != 0) {			
		e.style.display = "";
		if (i != null) { i.src = img_minus.src; }
	} else {
		e.style.display = "none";
		if (i != null) { i.src = img_plus.src; }
	}
}





/*
 TreeSelector used to pick up a popup window with tree of data.
 See Support.pm::htmlField() for details.
 */
function TreeSelector(field_name, objid, objtype)
{
	var control = document.all(field_name);
	if ( control == null ) {
		alert('Form element ' + field_name + ' not found');
		return;
	}

	var remote=window.open('/popup/tree.htm?'+
			'field='+field_name+
			'&objid='+objid +
			'&objtype='+objtype +
			'&fielddata='+control.value + '#' + control.value, //control.value,
		'tree_selector', 'width=400,height=400,left=100,top=100,resizable=yes,scrollbars=yes,status=0,toolbar=0,location=no,menubar=0');
	//var remote=window.showModalDialog('/popup/calendar.htm?field='+field_name+'&value='+control.value,
	//	null, 'width=160,height=160,left=200,top=150,resizable=yes,scrollbars=no,status=0,toolbar=0,location=no,menubar=0');

	if (remote != null)	{
		if (remote.opener == null) remote.opener = self;
		remote.focus();
	}
}


/*
 Generic onMouseDown function:
 - Remove Popup Menu if it is present
 */
function body_mouse_down() {
	var pm = document.all('PopupMenu');
	if ( pm != null ) {
		if ( pm.style.display.indexOf('inline') >= 0 ) {
			//pm.style.display = 'none';
			//alert('111');
		} 
	}
	//return true;
}  // body_mouse_down




/* -----------------13.06.2002 16:20-----------------
 Collection of functions to work with PopupMenu
 --------------------------------------------------*/
function show_popup_menu(event, menuname, objid, objid2) {
	// create menu object
	var pm = document.all('PopupMenu');
	if ( pm == null ) return;
	
	// Initialize menu
	if (menuname != null) {
		var ma_is_object = (typeof eval('PopupMenu_' + menuname) == 'object');
		if (ma_is_object) {
			// menu array
			var ma = eval('PopupMenu_' + menuname);
			for(i=0; i<=9; i++) {
				if (typeof ma[i] == 'object') {
					// prepare label, replace #id# with objid in href
					var label = ma[i][0];
					var href = ma[i][1];
					href = str_replace(href, '#id#', objid);
					href = str_replace(href, '#id2#', objid2);
					
					// If menu label eq 'html' then output it
					if ( label == 'html' ) {
						document.all('PopupMenuA_' + i).href = 'javascript:void(0);';
						document.all('PopupMenuA_' + i).innerHTML = href;
					} else {
						document.all('PopupMenuA_' + i).href = href;
						document.all('PopupMenuA_' + i).innerHTML = '&nbsp;' + label + '&nbsp;';
					}
					document.all('PopupMenuTR_' + i).style.display = 'inline';

				} else {	// not visible element
					document.all('PopupMenuTR_' + i).style.display = 'none';
				}	
			}
		}
	}

  // make menu visible
  pm.style.display = 'inline';

  // position menu object
  if ( event != null ) {
    //alert(document.body.scrollTop);
    
    if ( event.clientX + pm.offsetWidth > document.body.clientWidth ) {
      pm.style.left = event.clientX - pm.offsetWidth + document.body.scrollLeft + 6;
    } else {
      pm.style.left = event.clientX + document.body.scrollLeft - 6;
    }

    if ( event.clientY + pm.offsetHeight > document.body.clientHeight ) {
      pm.style.top = event.clientY - pm.offsetHeight + document.body.scrollTop + 6;
    } else {
      pm.style.top = event.clientY + document.body.scrollTop - 6;
    }
  }

}  // show_popup_menu


function hide_popup_menu() {
	var pm = document.all('PopupMenu');
	if ( pm == null ) return;
	
	if(pm.contains(event.toElement)) return;

	pm.style.display = 'none';
}

/*
 on_change_xacl_combo(xacl)
 xacl is the name of xacl field, ie 'xacl_read'

 Used to show/hide dialog box controls when user change 
 selection in popup_menu.
 Show xacl_uid text field for uid: 
 Show xacl_did popup_menu field for gid: 

 This function is used from htmlField()
 */
function on_change_xacl_combo( xacl ) {
  // this is combo box(popup_menu) with xacl
  var combo = document.all(xacl);
  if ( combo == null ) return;

  // show/hide xacl_uid text field
  if ( combo.value == 'uid' ) {
    document.all(xacl + '_uidspan').style.display = "inline";
  } else {
    document.all(xacl + '_uidspan').style.display = "none";
  }

  // show/hide xacl_gid popup_menu
  if ( combo.value == 'gid' ) {
    document.all(xacl + '_gidspan').style.display = "inline";
  } else {
    document.all(xacl + '_gidspan').style.display = "none";
  }
}  // on_change_xacl_combo


/*
 Change some style properties of item with ID
 */
function style_display( item_id, display_style, font_weight ) {
  var i = document.all(item_id);
  if ( i != null && display_style != null) {
    i.style.display = display_style;
  }
  if ( i != null && font_weight != null) {
    i.style.fontWeight = font_weight;
  }
  return i;
}  // style_display

<%attr>
Layout => 'Nothing'
</%attr>
