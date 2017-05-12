~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!                                        COOKIES EXAMPLE					!
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                                        

1. Installation
2. Explanation
3. Autor of this help file

*******************************
  1. Installation
*******************************

 Please make a subdirectory 'cookies' into your WebTools/htmls and copy the file: 'cookies.whtml'
 into it. After that you can run it on this way:
 
 http://www.july.bg/cgi-bin/webtools/process.cgi?file=cookies/cookies.whtml

 where: "http://www.july.bg/"  is your host,
        "cgi-bin"  is your perl script directory,
        and "webtools" is your WebTools directory!

 NOTE: process.cgi is a base (system) script for me (respective you :)
       YOU ALWAYS HAVE TO USE IT!!! (IT IS YOUR Perl/HTML COMPILER :)

 NOTE: See that extension of script is .whtml
       process.cgi support follow extensions: .html .hml .whtml .cgihtml .cgi ,
       but with .whtml and .cgihtml you can use highlightings in UltraEdit 
       (nice text editor for programmers :-)

 File "cookies.html" contain <FORM> and respective ACTION has value: /cgi-bin/webtools/process.cgi?file=...
 Please skim this file for HREF and ACTION, and edit where is needful!

*******************************
  2. Explanation
*******************************

Here is a cookie example. I will show you how to Set or Delete cookies!

I hope you've seen the cookies.whtml file :))

... and now we're starting the explaining the code.

Using CSS styles sheets the page will looks more cool.
One form is used,it contains a lot of buttons :

With the help of JavaScript we'll set the value of the hidden field 'action' and then submit the form.
The 'action' field indicates us what we'll do later.

<input type="HIDDEN" value="" name="action">

action is 'set'
<input type="SUBMIT" value="Set Cookie" name="SUBMIT" onclick="this.form.action.value='set';this.form.submit();">

action is 'del'
<input type="BUTTON" value="Del Cookie" name="B2" onclick="this.form.action.value='del';this.form.submit();">

action is 'refresh'
<input type="BUTTON" value="Refresh" name="B1" onclick="this.form.action.value='refresh';this.form.submit();">

The text between this code, is treated as perl code. 

<!-- PERL: Hide Perl`s script
<?perl 

 ?>
//-->

Used functions: 
  'write_cookie' 
  'delete_cookie' 

NOTE: See the 'HELP.DOC' file for more detailed syntax of the functions.

We want to print the content type with cyrilic support.
 Header(type=>'Content',val=>'text/html; charset=Windows-1251');  

Checking 'action' field ...

We'll set a cookie ...
-----------------------------------------------------------------------------------
syntax: write_cookie ($name,$value,$expr_date,$path,$domain);
 if ($action eq 'set')
   {
     write_cookie($cookie_name,$cookie_value);     
   }
-----------------------------------------------------------------------------------

We'll delete a cookie ...   
-----------------------------------------------------------------------------------
 if ($action eq 'del')
   {
     delete_cookie($cookie_name);
   }
-----------------------------------------------------------------------------------

if none of the actions above are choosen the page will refresh and show the cookies that we're set.
Because we can't set and read cookies at same time, i.e. the cookie is set and the next time when the page
reloads the cookie will be accessible.

 if ($action eq 'refresh')
   {
     # 
   }

Displaying of the cookies if there are some ...
-----------------------------------------------------------------------------------
 if (%sess_cookies)
   {
     print "These are your current cookies:<BR>\n";
     while ( ($cookie_name,$cookie_value) = each( %sess_cookies) )
       {
         print "$cookie_name = <B>$cookie_value</B> <BR>\n";
       }
   }
-----------------------------------------------------------------------------------


*******************************
  3. Autor of this help file
*******************************

 Svetoslav Marinov,
 Sofia, Bulgaria

 e-mail: svetoslavm@bulgaria.com
