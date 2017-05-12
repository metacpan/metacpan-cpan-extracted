###################################################
# JavaScript routines
###################################################

### Function N: 1 ########################################################
# Parameters: $form_name - Name of submitting FORM.
#             $action_field - Form FIELD that bring 'action' to CGI script
#             $submit_field - Form FIELD that contain all form data!
#             $separator1 - Separator used from JS functions to separate
#                           different variables!
#             $separator2 - Separator used from JS functions to separate
#                           variables from respective values!

sub JS_submiting_functions
{
 my ($form_name,$action_field,$submit_field,$separator1,$separator2) = @_;
 my $data = << "TERMINATOR_JS";
<script language="JavaScript">
////////////////////////////////////////////////////
// JS Code encapsulating POST method
////////////////////////////////////////////////////
// This JS accumulate data from forms
// into one var! So you need to submit
// only one var instead 2 or more...
//----------------------------------------
// Requirements: Nothing special at all  :-)
// NS 4, IE 4, Mozilla and Opera 4 !
// Note: you can run scripts with evry
// JavaScript Host :-))
//----------------------------------------
// Additional release note:
// If your choise for separator are:
// '|' and '=' then you can't use it for
// name of variables and ofcource they can't
// have for values this separator's chars :|
// However you can change it with other!
// Just set in $separator1 and
// $separator2 wished chars (or even
// STRINGS) :-))

var JS_data_field = '';
var JS_data_separator = '$separator1'
var JS_data_binder    = '$separator2'
var JS_error_state = 0;

function JS_submit_form (cgi_action,val) // That submit one variable and send one
 {					     // 'action' into hidden filed.
  var JS_MIME_str = escape(val);
  document.$form_name.$submit_field.value = JS_MIME_str;
  document.$form_name.$action_field.value = cgi_action;
  document.$form_name.submit();
  return true;
 }
 
function JS_compress_data (Name,NewValue)
{
 var JS_data = new String();           // This string contain POSTed data
 var JS_regexp = new String();         // Our variable search template
 var JS_data = JS_data_field;          // "Compressed" data
 var JS_regexp = JS_data_separator+Name+JS_data_binder;
 var JS_first_index = JS_data.indexOf(JS_regexp);  // Find var for Update!
 if(JS_first_index != -1)                          // exists?
  {
   var JS_before_data = JS_data.substring(0,JS_first_index);  // Get data before var..
   var JS_working_str = JS_data.substring(JS_first_index+JS_regexp.length); // and our var too..
   var JS_next_separator = JS_working_str.indexOf(JS_data_separator);  // Find next separator..
   if(JS_next_separator != -1)                     // Is available?
     {
      var JS_last_data = JS_working_str.substring(JS_next_separator+JS_data_binder.length); // Get last data..
      JS_the_result = JS_before_data+JS_regexp+NewValue+JS_data_separator+JS_last_data; 
      // Thist is final result..and we save in a safe place :-)
     JS_data = JS_the_result;
     }
   else
     {
      JS_data = JS_before_data+JS_regexp+NewValue; // No more data..so save data!
     }
  }
 else  // No previus data..just add!
  {
   JS_data = JS_data_field+JS_regexp+NewValue;
  }
 JS_data_field = JS_data;  // Send our calculated data into global var!
 //alert(JS_data);
}

function JS_delete_data (Name)
{
 var JS_data = new String();           // This string contain POSTed data
 var JS_regexp = new String();         // Our variable search template
 var JS_data = JS_data_field;          // "Compressed" data
 var JS_regexp = JS_data_separator+Name+JS_data_binder;
 var JS_first_index = JS_data.indexOf(JS_regexp);  // Find var for Del!
 if(JS_first_index != -1)                          // exists?
  {
   var JS_before_data = JS_data.substring(0,JS_first_index);  // Get data before var..
   var JS_working_str = JS_data.substring(JS_first_index+JS_regexp.length); // and our var too..
   var JS_next_separator = JS_working_str.indexOf(JS_data_separator);  // Find next separator..
   if(JS_next_separator != -1)                     // Is available?
     {
      var JS_last_data = JS_working_str.substring(JS_next_separator+JS_data_binder.length); // Get last data..
      JS_the_result = JS_before_data+JS_data_separator+JS_last_data; 
      // Thist is final result..and we save in a safe place :-)
     JS_data = JS_the_result;
     }
   else
     {
      JS_data = JS_before_data; // No more data..so save data!
     }
  }
 else  // No previus data..just add!
  {
   JS_data = JS_data_field;
  }
 JS_data_field = JS_data;  // Send our precalculated data into global var!
 //alert(JS_data);
}


// When you use follow two functions you can use mask!
// Mask can define exacly which fileds from form you
// want to "compress"/delete! Note: Mask is binnary!
// Mask can be (and any combination of them):
// 1  - Comress "text" fileds (0 - don`t compress)
// 2  - Comress "hidden" fileds (0 - don`t compress)
// 4  - Comress "password" fileds (0 - don`t compress)
// 8  - Comress "checkbox" fileds (0 - don`t compress)
// 16 - Comress "radio" fileds (0 - don`t compress)
// 32 - Comress "select-one" fileds (0 - don`t compress)
// 64 - Comress "select-multiple" fileds (0 - don`t compress)
// 255 - Comress all fields from form
// (If you do NOT supply mask, then value 255 is used!)


function JS_get_object_value(obj,mask)
 {
  var type = obj.type;
  JS_error_state = 1;
  
  if ((type == 'text') && (mask & 1))
    {
     JS_error_state = 0;
     return(obj.value);
    }
  if ((type == 'hidden') && (mask & 2))
    {
     JS_error_state = 0;
     return(obj.value);
    }
  if ((type == 'password') && (mask & 4))
    {
     JS_error_state = 0;
     return(obj.value);
    }
  if ((type == 'checkbox') && (mask & 8))
    {
     JS_error_state = 0;
     if(obj.checked) { return(1); }
     else { return(0);}
    }
  if ((type == 'radio') && (mask & 16))
    {
     JS_error_state = 0;
     if(obj.checked) { return(1); }
     else { return(0);}
    }
  if ((type == 'select-one') && (mask & 32))
    {
     JS_error_state = 0;
     if(!obj.selectedIndex) return('');
     return(obj.selectedIndex);
    }
  if ((type == 'select-multiple') && (mask & 64))
    {
     JS_error_state = 0;
     if(!obj.selectedIndex) return('');
     return(obj.selectedIndex);
    }
  return('');
 }

function JS_check_proper_type(obj,mask)
 {
  var type = obj.type;
  JS_error_state = 0;
  
  if ((type == 'text') && (mask & 1)) return(1);
  if ((type == 'hidden') && (mask & 2)) return(1);
  if ((type == 'password') && (mask & 4)) return(1);
  if ((type == 'checkbox') && (mask & 8)) return(1);
  if ((type == 'radio') && (mask & 16)) return(1);
  if ((type == 'select-one') && (mask & 32)) return(1);
  if ((type == 'select-multiple') && (mask & 64)) return(1);
  return(0);
 }

function JS_compress_form(frm,mask) // "Compress" all variables from form.
 {
  var JS_index,JS_cnt;
  var JS_data = '';
  var JS_data_name = '';
  JS_cnt = frm.elements.length;
  if(typeof(mask) == 'undefined'){mask = 255;}
  for (JS_index=0;JS_index<JS_cnt;JS_index++)
     {
      JS_data_name = frm.elements[JS_index].name;
      JS_data = JS_get_object_value(frm.elements[JS_index],mask);
      if(!JS_error_state) JS_compress_data(JS_data_name,JS_data);
     }
 }
 
function JS_delete_form(frm,mask) // Delete all vars from form.
 {
  var JS_index,JS_cnt;
  var JS_data_name = '';
  JS_cnt = frm.elements.length;
  if(!mask) {mask = 255;}
  for (JS_index=0;JS_index<JS_cnt;JS_index++)
     {
      JS_data_name = frm.elements[JS_index].name;
      if(JS_check_proper_type(frm.elements[JS_index],mask)) JS_delete_data(JS_data_name);
     }
 }
</script>
TERMINATOR_JS
return($data);
}

### Function N: 2 ########################################################
# Parameters: VOID

sub JS_read_var
{
 my $data = << "TERMINATOR_JS";
<script language="JavaScript">
///////////////////////////////////////////////////////
// Read one variable from document location URL
///////////////////////////////////////////////////////
function ReadVar(name)
 {
  var srch = new String(document.location);
  var query = new String;
  var input = new Array;
  var input2 = new Array();
  var i = 0;
  srch = srch.substr(srch.indexOf('?')+1);
  input = srch.split('&');
  for (i=0; i< input.length; i++)
     {
      if (input[i].match(name+"="))
	{
	 query = input[i];
	 break;
 	}
     }
  if(!query) return('');
  input2 = query.split('=');
  return(unescape(input2[1]));
</script>
TERMINATOR_JS
return($data);
}

### Function N: 3 ########################################################
# Parameters: $index - Main page that contain set of frames(commonly is
#                      'index.html')
#             $page -  Name of cookie that bring target page(commonly is
#                      'page')

sub JS_redirect
{
 my ($index, $page) = @_;
 my $data = << "TERMINATOR_JS";
<script language="JavaScript">
////////////////////////////////////////////////////////////////////////////////////////////
// This code redirect "this" page into main frame
// You need from two or more frames (placed into "index.html")
// One of these frames must by main (frame where will be loaded other web pages)
// Follow code must apear into main frame and the same code into any other pages,
// except: index.html and evry other frame page (except main frame :))
// When one of your web pages is loaded directly into browser window(not into main frame),
// then "this" page will send cookie and redirect browser to html page contained frameset of
// your site( commonly index.html). That act will load index.html and all frames in. Because
// in main frame this code apear, it will read sent cookie and redirect page to caller... so
// page wrote a cookie will be loaded into main frame!
////////////////////////////////////////////////////////////////////////////////////////////

var index = '$index';
var page = '$page';
function read_cookie(name)
  {
    var stop,index;
    
    index = document.cookie.indexOf(name + "=");
    if (index == -1) return (0);
    index = document.cookie.indexOf("=", index) + 1;
    stop = document.cookie.indexOf(";", index);
    if (stop == -1) stop = document.cookie.length;
    return(unescape(document.cookie.substring(index, stop)));
  }
function write_cookie(name,value)
  {
    var cookie = name + "=" + value + ";";
    document.cookie = cookie;
  }
function delete_cookie(name)
  {
    var date = new Date;
    date.setDate(date.getDate() - 1);
    var cookie = name + "=; " + "expires=" + date.toGMTString();
    document.cookie = cookie;
    return(1);
  }
function redirect()
  {
    var framed = top.location == self.location ? 0 : 1;
    var cookied = read_cookie(page);
    if (cookied == 0 || cookied == "") cookied=0;
    if (framed)
      {
      	if (cookied != 0)
      	  {
      	    delete_cookie(page);
      	    self.location = cookied;
      	  }
      }
    else
      {
      	if (cookied != 0)
      	  {
      	    delete_cookie(page);
      	    window.location = index;
      	  }
      	else
      	  {
      	    var loc = self.location;
      	    write_cookie(page,loc);
      	    window.location = index;
      	  }     	
      }
  }
</script>
TERMINATOR_JS
return($data);
}

### Function N: 4 ########################################################
# Parameters: $expire - expire time in seconds,
#             $last_minutes - remaining time before session expiration!
# 	      $notify - Message that will notify user that his session 
#                       will expire after few minutes.
#             $alert -  Message that will notify user that session is
#                       already expired! :(
#             $refresh_url - Url that updates expiration time (of session).

sub session_expire_notify
{
 my ($expire, $last_minutes, $notify, $alert, $refresh_url) = @_;
 my $data = << "TERMINATOR_JS";
<script language="JavaScript">
////////////////////////////////////////////////////
// JS Code: Notify user when session will expire
////////////////////////////////////////////////////
// This JS set timer to expiration time and wait
// session to expire. So when session going to
// expire (some minutes before) it notify user and
// suggess user to update it's expiration time
// (i.e. to click button (this will call script
// that update expiration time))!
////////////////////////////////////////////////////
 var Expire_session_time = $expire; // In seconds!!!
 var Expire_timer;
 function Notify_User_for_expiration()
 {
  var last_time = $last_minutes;
  Expire_session_time -= 60;
  if (Expire_session_time <= 0)
    {
      clearTimeout(Expire_timer);
      alert("$alert"); // Sorry, session expired!
      return(0);
    }
  if (Expire_session_time <= (last_time*60))
    {
      conf_res = confirm ("$notify"); // Please update your session!
      if(conf_res)
       {
         Expire_session_time = $expire; // In seconds!!!
         self.location = '$refresh_url';
       }
    }
  Expire_timer = setTimeout('Notify_User_for_expiration()',60000);  // Check evry minute!
 }

 Expire_timer = setTimeout('Notify_User_for_expiration()',60000);   // Check evry minute!
</script>
TERMINATOR_JS
return($data);
}

$webtools::loaded_functions = $webtools::loaded_functions | 2048;

1;