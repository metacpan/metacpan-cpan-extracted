~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!	                            Download file via cgi script				!
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                                        

 This task is very popular in Web. Currently most of downloads are very simple: Web developer just
put in html page links to files and user download these files. Ofcourse there is and other way: Via cgi script.
If you use cgi script you can find download status i.e. to find out whether download were successful or not?!

 Now with webtools you can download file easly. Also you can set maximum speed limit of downloading process.

Example:

*******************************
  1. Installation
*******************************

  Please make sub directory 'download' into your WebTools/htmls and copy file: download.whtml there.
Copy 'd.html' into your htdocs directory (root html directory of your Web server)! Also you need to
find on your system some .zip or .gz file and please copy it to your webtools directory (where you can
find and your process.cgi file!). After you've copied this file you need to rename it to: this.zip
Ok, now you can start d.html:
 
 http://www.july.bg/d.hmtl

 where: "http://www.july.bg/"  is your host


 NOTE: d.html contain row like this:

      /cgi-bin/webtools/process.cgi?file=download/download.whtml

 where: "cgi-bin"  is your perl script directory,
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
  
  Now look at source of 'download.whtml':

  require 'downloader.pl';

With this line you load needed functions and definitions for download.


  ClearBuffer();                     # Clear buffers
  ClearHeader();
  flush_print(1);                    # flush_print (not real: 1 - clear mode)

When we going to download file, we don't want to send any data different of required download file, so 
it is good idea to clear all buffers and flush permanent (but not real: flush_print() with parameter 1!!!)
before real download.


  set_printing_mode('nonbuffered');  # Force non-buffered print

When download some file we are obliged to set non buffered mode.


  if (download_file('this.zip',10))  # Download file with 10kb/s
   {
    open(FF,'>'.$tmp.'done.txt');close FF;   # Create file showing successful download.
   }
  else 
   {
    open(FF,'>'.$tmp.'error.txt');close FF;   # Error occure throught download process.
   }
  exit;

download_file() return 1 on successful download and 0 on error!



*******************************
  3. Author
*******************************

 Julian Lishev,

 Sofia, Bulgaria,

 e-mail: julian@proscriptum.com