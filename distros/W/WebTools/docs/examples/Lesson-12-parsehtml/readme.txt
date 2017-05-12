~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!		                       	 HTML Parser			  			!
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                                        

 This example show you powerful template functions that are able to fill out HTML forms(files).
Using perl hash consisting from FROM filed names (and respective default values for each element).
These functions allow you to set value (fetched from hash) to specific form element (input,
textarea,select and so on..). This may be useful because names of form fields corespond to 
respective hash keys.

%data = ( 'field_name' => 'field_value' [, ...]);

Example: %hash = ('user'=>'admin','pass'=>'current password');

$parsed_html = html_parse($html,%data);

Result of this function will contain "parsed" html and all keys from the hash will be used to
substitute form elements.

$parsed_html = html_parse_form($form,$html,%data);
 
This function is equivalent to previous but values from hash will be set to all form fileds in
only one FORM, specified as first parameter.
 

Example:

*******************************
  1. Installation
*******************************

  Please make sub directory 'parser' into your WebTools/htmls and copy file: parser.whtml there.
Ok, now run mail.whtml:
 
 http://www.july.bg/cgi-bin/webtools/process.cgi?file=parser/parser.whtml

 where: "http://www.july.bg/"  is your host
        "cgi-bin"  is your perl script directory,
        and "webtools" is your WebTools directory!

 NOTE: process.cgi is a base (system) script for me (respective you :)
       YOU ALWAYS NEED TO USE IT!!! (IT IS YOUR Perl/HTML COMPILER :)

 NOTE: See that extension of script is .whtml
       process.cgi support follow extensions: .html .hml .whtml .cgihtml .cgi ,
       but with .whtml and .cgihtml you can use highlightings in UltraEdit 
       (nice text editor for programmers :-)


*******************************
  2. Example explanation
*******************************
  
Example offered to you is a really simple.
There are two forms with single input filed in. With first call to html_parse() we
parse html with whole FORMs. But next call to html_parse_form() will parse only
second form (see example)

*******************************
  3. Author
*******************************

 Julian Lishev,

 Sofia, Bulgaria,

 e-mail: julian@proscriptum.com