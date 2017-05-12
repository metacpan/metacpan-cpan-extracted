~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!                                Global variables exporting EXAMPLE				!
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                                        

Here I want to demonstrate how you can access variables become from GET/POST


 Rule Number 1:

- All variables authomaticly become global with this module! (there is only one exception),
  so you don't need to call parse subprogram.


 Rule Number 2:

- Cookies that have same names as variables from GET/POST rewrite this vars only if in config.pl file is set: 
  $webtools::cpg_priority = 'cookie';    # In this case cookies has higher priority!

  If set 'get/post' then GET/POST vars has higher priority than cookies!

  
 Rules Number 3:

- If you use multipart method, then file names of uploaded files (saved on server) are found
  in %uploaded_files.A real name of files, posted via form (<input name="..." type="file">)
  can be used throught %uploaded_original_file_names hash. In both cases use for a hash key
  "name" of input form element i.e <input name="...hash_key..." type="file">


 Rule Number 4:

- Principle you can use any normal name for variable in your FORM or cookie
  name, except reserved into modlues (for example you can`t use name 'file' it is
  reserved with process.cgi)!


 Rule Number 5:

- You can't have for name global variable that not mach regular expr: ^[A-Za-z0-9_]+$
  Also you can't use (global) names starting with 'sys_' because they are reserved!
  If you prefer, you can fetch your data throught read_form_array(). It accept one 
  parameter: number of varible in input array. Return result is array with follow structure:
  first element is a name of variable and second element is it's value.
  (multipart data are not global exported, so don't worry about it..see Rule 3)


 Rule Number 6:

- Your variable may become global (if match previus rules) and then it will be saved
  in scalar variable!
  >>> BUT <<<  WebTools can also to export global HASHes,
  if only it match follow condition:

  %inputhash_nameOfHash_keyOfHash

  where: 
  %inputhash_  - is magical. All your global hashes should start with this sequence in
                         name. That rule is security dependent!
  nameOfHash  - is name of your hash (infact your real hash names always will start
                         with %inputhash_ plus your personal name: nameOfHash) !
                         nameOfHash must be construct of follow chars: [A-Za-z0-9]
  _                   - is separator between hash name and hash key!

  keyOfHash     - is hash key. It must be construct of follow chars: [A-Za-z0-9_]

  Follow HTML code is valid:
  <input type="text" name="%inputhash_example_first_name" value="Desi">
  <input type="text" name="%inputhash_example_age" value="20">

  If post these form elements to WebTools script, then you will be able to
  use them through global hash: %inputhash_example and these two values you
  can access via:
  $inputhash_example{'first_name'} and $inputhash_example{'age'}


Global Variables (Example):

*******************************
  1. Installation
*******************************

 Please make sub dir 'global' into your WebTools/htmls and copy file: glob.whtml there
 after this you can run it on this way:
 
 http://www.july.bg/cgi-bin/webtools/process.cgi?file=global/glob.whtml

 where: "http://www.july.bg/"  is your host,
        "cgi-bin"  is your perl script directory,
        and "webtools" is your WebTools directory!

 NOTE: process.cgi is a base (system) script for me (respective you :)
       YOU ALWAYS NEED TO USE IT!!! (IT IS YOUR Perl/HTML COMPILER :)

 NOTE: See that extension of script is .whtml
       process.cgi support follow extensions: .html .hml .whtml .cgihtml .cgi ,
       but with .whtml and .cgihtml you can use highlightings in UltraEdit 
       (nice text editor for programmers :-)

 File "glob.html" contain <FORM> and respective ACTION has value: /cgi-bin/webtools/process.cgi?file=...
 Please skim this file for HREF and ACTION, and edit where is needful!


*******************************
  2. Example explanation
*******************************
  
 
	 <!-- PERL: Hide Perl`s script
	 <?perl 

 This set begining of perl script and ...
 
	 ?>
	 //-->

 this is set the end of script. 

Also you can use follow pair instead previous:

         <?perl
         
         and
    
         ?>

 but I don't recommend that style to you, because in many cases you can confuse yourself! 
 You can have as many as you wish "scripts" like this in your "html" file!
 Of course this is not a real "html"! This is a mix of Perl code and HTML code in one pretty 
 file. (Just like in PHP stuff)

 Well lets go back over our code:


	 <!-- PERL: Hide Perl`s script
	 <?perl 
	   Header(type=>'content',val=>'text/html; charset=Windows-1251');  # HTTP Content-type header
	 ?>
	 //-->
 
 This pice of code send HTTP Header to browser (common we send Content-type: text/html)
 If you forgot to supply second parameter (val) script will send for you authomaticly
 follow header line: "Content-type: text/html\n"

 If you need to send one custom header line you can use follow syntax:

	 Header(type=>"raw", val="Your_HEADER_Line_terminated_with_\n");

 Also you need to know, that you can post as many as you want headers at all the script runnig time
(You can post header even after you had printed some piece of body, because the output is buffered
(on default)!)

 In our example we check directly variable $method
	 
	 if ($method eq 'get') ...

 because all variables from links/forms and cookies are global exported!

NOTE: You can mix Perl and HTML even in "if", "for", "while" statements and so on, and so on...
 
 Example:
        <!-- PERL: Hide Perl`s script
	<?perl  
 
          for ($i=1; $i <= 10; $i++)
             {  
 
              ?>
	      //-->

	    	 Current line is:

              <!-- PERL: Hide Perl`s script
	      <?perl
               print  "$i <BR>\n";

	     }

        ?>
        //-->

 Please learn this example(glob.pl) very carefuly (espacialy methods: GET/POST and enctype: 'multipart/form-data')

 If you have any problem with executed script (Perl/HTML file) you can always turn $debugging = 'on' in your 
 config.pl to view all errors in browser`s window.

*******************************
  3. Author
*******************************

 Julian Lishev,

 Sofia, Bulgaria,

 e-mail: julian@proscriptum.com