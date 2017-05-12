~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!	                                Session example				   		!
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                                        

These days the heart of web applications are sessions. Almost in any case you can't do anything
without session support in your web pages. Now you will see how easy is that to be done with
webtools module.
WebTools use Php-like mechanism when it deals with cookies. I.e. at first time WebTools send 
"session id" via cookie and through links/actions. If cookie not accpted, next time WebTools send 
session id on same way! But, if cookie was accepted then WebTools stop to send "session id"
(till session id is correct and has not expired!)

Example:

*******************************
  1. Installation
*******************************

  Please make sub directory 'session' into your WebTools/htmls and copy file: sess.whtml there.
Ok, now run sess.whtml:
 
 http://www.july.bg/cgi-bin/webtools/process.cgi?file=session/sess.whtml 

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
  
  Now let look at source of 'sess.whtml':

  $coded_buffer = '';
  if($sess_force_flat =~ m/^on$/)
    {
     $dbh = '';             # We don't need database connection when session's functions use flat files!
    }
  else
    {
     $dbh = sql_connect();  # In this case we need database handler for session's functions!
    }

  $myid = session_start($dbh);  # Start session and return session id. If old session not present or if this
                                # session expired, new one will be created.

  $i = read_scalar ('counter'); # Read one registrated scalar with "this" session. If previous registration
                                # avalible then value of this variable will be returned!
  $i++;
  if($i == 1)
   {
    print "Session Started!<BR>"; # First time when session were started we print this fact :-)
   }
  if($i > 4)                      # After 5th time you refresh this "web page" we destory session!
   {
    print "Session destroyed!<BR>";
    session_destroy($dbh);
   }
  else                            # ..or we reregister "counter" variable with this session!
   {
    $coded_buffer .= register_var('scalar','counter',$i);
    session_register($coded_buffer,$dbh);
   }
All implemented session's functions you can see in HELP.doc file

*******************************
  3. Author
*******************************

 Julian Lishev,

 Sofia, Bulgaria,

 e-mail: julian@proscriptum.com