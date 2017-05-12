~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!	                               Attach Variables						!
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                                        

 Hey I'm happy to see you here again. This time I want to demonstrate how you can attach variables
throught cookies and/or GET/POST!

 Almost evrytime you need to bring some variables from page to page, so now you can attach variables
to your script's output via links/forms and via cookies!

Example:

*******************************
  1. Installation
*******************************

  Please make sub directory 'attach' into your WebTools/htmls and copy file: attach.whtml there
 after this you can run it on this way:
 
 http://www.july.bg/cgi-bin/webtools/process.cgi?file=attach/attach.whtml

 where: "http://www.july.bg/"  is your host,
        "cgi-bin"  is your perl script directory,
        and "webtools" is your WebTools directory!

 NOTE: process.cgi is a base (system) script for me (respective you :)
       YOU ALWAYS NEED TO USE IT!!! (IT IS YOUR Perl/HTML COMPILER :)

 NOTE: See that extension of script is .whtml
       process.cgi support follow extensions: .html .hml .whtml .cgihtml .cgi ,
       but with .whtml and .cgihtml you can use highlightings in UltraEdit 
       (nice text editor for programmers :-)

 File "attach.html" contain <FORM> and respective ACTION has value: /cgi-bin/webtools/process.cgi?file=...
 Please skim this file for HREF and ACTION, and edit where is needful!


*******************************
  2. Example explanation
*******************************
  

  Before I start code explanation you may need to look over browser's output... Done I thing now evrything is
 clear?!?...
 Well maby you need some hint? :-)))
 First of all take a look at this pice of code:
 
 if ($action eq '')
  {
   ?>
   //-->
   <body bgcol....

 I have decided to define one variable ($action) that may show to as what we (must) doing. For example when
 this value is undefined or just empty an HTML code will be printed in browser window. But when:
 
 if ($action eq '1') 
 
 then we going to main page i.e. the page were we can save name of our visitor (ofcource if visitor have been 
 entried it`s name). Here we can attach name of visitor to link, and/or to a cookie (THIS CHOICE WILL BE AUTOMATHICLY
 MADE, DEPENDING OF BROWSER SETTINGS (depend of cookie accepting policy))

 attach_var('visitor_name',$visitor_name);
 
 This pice of code will attach variable with name 'visitor_name' and take value brought throught var $visitor_name.
 Now you may ask yourself how you can fetch the value of attached variable in next page where you may need of?
 Well that is very simple: Evry vars from form/link or cookie become global variable! (If you wnat you can use 
 read_var('name') to read wished var from input form/link/cookie).

 When you click over link "logout", script jump to logout page ( $action eq '2'), there you have name of visitor
 because var $visitor_name has value retrieved from cookie/link/form...

 At the end of script you must call detach_var('visitor_name') to clean up attached var (especialy when browser 
 supprt cookies).


*******************************
  3. Author
*******************************

 Julian Lishev,

 Sofia, Bulgaria,

 e-mail: julian@proscriptum.com