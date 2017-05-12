~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!	                              Database example 				   		!
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                                        

 Database is realy powerfull "toy" for programmers, so we will show how to access database with 
webtools.

Example:

*******************************
  1. Installation
*******************************

  Please make sub directory 'db' into your WebTools/htmls and copy file: dbtest.whtml there.
Ok, now run dbtest.whtml:
 
 http://www.july.bg/cgi-bin/webtools/process.cgi?file=db/dbtest.whtml 

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
  
  Now let look at source of 'dbtest.whtml':

  $hnd = sql_connect();
That function try to connect script to database using default user/password from config.pl As result
it return database handler used from other sql functions. Also you can use sql_connect() with 6 
paramerters (for more information see Help.doc)
 
  $mypass = sql_quote('mytestpass',$hnd);
With this function you can quote any string/binary data. For example:
$mystr = 'some data..';
$qstr = sql_quote($mystr,$hnd); 
$qstr will contain follow data: "'some data..'"

  $res = sql_query($q, $hnd);
With that function you can execute one query to db. $q is string contain one sql query. $hnd is 
database handler.
Note: All sql querys should be compatible with SQL standarts (MySQL,ODBC)

You can use additional SQL functions with webtools (see Help.doc) .Also if you need sql functions that 
not implemented with webtools you can use directly $hnd as DBI/Mysql handler!

Additional info:
---------------
If you wandered how to make auto increment field with flat database, you can do that indirect, 
for example with follow query:

  $q = "INSERT INTO some_table VALUES(MAXVAL('ID|some_table'),'some data1','some data2',.....)";

 Where in MAXVAL('ID|some_table'), 'ID' is coulum that should be auto increment and 'some_table' is
table where you want to insert row.

NOTE: That method is deliveryed with WebTools and it is not compatible with SQL standards, but that feature 
can be used not only with Flat DB, it can be used with MySQL and Access driver (for compatibility)

All implemented sql_ functions you can skim in HELP.doc file

*******************************
  3. Author
*******************************

 Julian Lishev,

 Sofia, Bulgaria,

 e-mail: julian@proscriptum.com