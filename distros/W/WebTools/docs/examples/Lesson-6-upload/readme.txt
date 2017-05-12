~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!	                            Upload files via cgi script 				!
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                                        

 This example will regards Upload and Mail capability of Webtools! Here we will send e-mail with two attached files.

Example:

*******************************
  1. Installation
*******************************

  Please make sub directory 'upload' into your WebTools/htmls and copy file: upload.whtml there.
Ok, now run upload.whtml:
 
 http://www.july.bg/cgi-bin/webtools/process.cgi?file=upload/upload.whtml 

 where: "http://www.july.bg/"  is your host
        "cgi-bin"  is your perl script directory,
        and "webtools" is your WebTools directory!

 NOTE: process.cgi is a base (system) script for me (respective you :)
       YOU ALWAYS NEED TO USE IT!!! (IT IS YOUR Perl/HTML COMPILER :)

 NOTE: See that extension of script is .whtml
       process.cgi support follow extensions: .html .hml .whtml .cgihtml .cgi ,
       but with .whtml and .cgihtml you can use highlightings in UltraEdit 
       (nice text editor for programmers :-)

 File "upload.html" contain <FORM> and respective ACTION has value: /cgi-bin/webtools/process.cgi?file=...
 Please skim this file for HREF and ACTION, and edit where is needful!

*******************************
  2. Example explanation
*******************************
  
  Now let look at source of 'upload.whtml':

 We have two main parts:

 (1) When 'subm' variable is not defined ('subm' will be defined when upload form is printed and user had submitted)
 (2) User had submitted form and pray his mail to be sent.

 In first case we must print upload form and wait user to submit form. When User submit form webtools will upload files
 and after that will send e-mail with attachments. 
 It is very imortaint for upload process to call function set_script_timeout(5*60). We realy need 5 minutes (or more),
 because upload process can take much more minutes depending of your internet speed and size of uploaded files!

 Functions needed for e-mail support can be found into mail.pl library (written by K.Krystev and modified by S.Marinov)
 In example you can find how to use these functions.

 NOTE:
   -  Maximum upload file size via POST method can be set in "config.pl" (default 1MB)

 IMPORTAN:
   -  Script DON'T SEND REAL E-MAILS till $debug_mail is 'on' (default) and $sendmail is not configured properly.
      In "debug_mail" mode your e-mails are saved into "webtools/mail" directory (check out).
      Change "config.pl" file to start your scripts mail normal!

 Enjoy!


*******************************
  3. Author
*******************************

 Julian Lishev,

 Sofia, Bulgaria,

 e-mail: julian@proscriptum.com