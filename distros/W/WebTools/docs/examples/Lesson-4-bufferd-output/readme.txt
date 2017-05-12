~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!	                             Buffered output to browser 				!
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                                        

 In Perl world there are couple of modules that capture STDOUT handler. For Webtools however
this is a base feature and I can't miss this example :)

Example:

*******************************
  1. Installation
*******************************

  Please make sub directory 'buffer' into your WebTools/htmls and copy file: buf.whtml there.
Now you can start buf.whtml:
 
 http://www.july.bg/cgi-bin/webtools/process.cgi?file=buffer/buf.whtml

 where: "http://www.july.bg/"  is your host
        "cgi-bin"  is your perl script directory,
        and "webtools" is your WebTools directory!

 NOTE: See that extension of script is .whtml
       process.cgi support follow extensions: .html .hml .whtml .cgihtml .cgi ,
       but with .whtml and .cgihtml you can use highlightings in UltraEdit 
       (nice text editor for programmers :-)

 NOTE: process.cgi is a base (system) script for me (respective you :)
       YOU ALWAYS NEED TO USE IT!!! (IT IS YOUR Perl/HTML COMPILER :)



*******************************
  2. Example explanation
*******************************
  
  If this example evrything is clear:

  set_printing_mode('');
 
This set non buffered mode i.e. you can print direct to browser, and follow line set buffered mode:
  
  set_printing_mode('buffered');

In example you see difference between these modes.



*******************************
  3. Author
*******************************

 Julian Lishev,

 Sofia, Bulgaria,

 e-mail: julian@proscriptum.com