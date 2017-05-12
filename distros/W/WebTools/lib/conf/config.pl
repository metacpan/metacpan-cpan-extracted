###################################################################
# Configuration file for "Web Tools" ver 1.27
# Please edit here, don’t do that in Perl scripts!
# For Web based configurator script see install.cgi
###################################################################

#[Name_Of_Project]
$webtools::projectname = 'webtools';   # Name of project!

#[SQL]
$webtools::db_support = 'db_flat';     # Can be: db_mysql, db_access, db_flat
$webtools::sql_host = 'localhost';     # Script will connect to MySQL Server
$webtools::sql_port = '3306';          # Port of SQL server
$webtools::sql_user = 'user';          # using user
$webtools::sql_pass = 'pass';          # and password

#[DataBase]
$webtools::sql_database_sessions =  $webtools::projectname.'db';      # Database name (name some like project!!!)
$webtools::sql_sessions_table =  $webtools::projectname.'_sessions';  # Session table (name: project_sessions)!
$webtools::sql_user_table = $webtools::projectname.'_users';          # Contain all users (and admin too)

#[CHECK]
$webtools::check_module_functions = 'on';       # After first check, please turn this 'off'!

#[Secure]
$webtools::site_is_down = 'off';                # Set to 'on' to prevent execution of scripts
$webtools::wait_attempt = '4';                  # Count of attempts when database is flocked
$webtools::wait_for_open = '2.0';               # Time between two attempts (in sec)
$webtools::sess_time = '2';                     # Expire time on session(2 hours)
$webtools::sys_conf_d = 'hour';                 # time dimenstion (lower case only) and can be:
                                                # second,minute,hour,day,month and year
$webtools::rand_sid_length = '32';              # Length of random SID string!
$webtools::sess_cookie = 'sesstime';            # 'sesstime'(i.e. expire after $sess_time) or
                                                # '0' (i.e. expire when user close browser)

$webtools::l_sid = 'sid';                       # Session ID label used by module

$webtools::cgi_lib_forbid_mulipart = 'off';     # If you want to protect yourself from multipart spam
                                                # turn this 'on' (you will be no longer able to use 
                                                # multipart forms)!
$webtools::cgi_lib_maxdata    = '4194304';      # maximum bytes to accept via POST (4MB)
$webtools::cgi_script_timeout = '120';          # Expiration time of script! (120 seconds default)
$webtools::ip_restrict_mode   = 'off';          # Set 'on' to restrict session on IP! If you get proxy
                                                # problems with restricted IPs, please set 'off' or use
                                                # proper function to set mode of this variable!
$webtools::run_restrict_mode  = 'off';          # Set 'on' to restrict external web user to your scripts.
                                                # If IP's of user not exists in DB/ips.pl WebTools will
                                                # close script immediately!
                                      
#[Debug]
$webtools::debugging = 'on';                    # Debugging mode
$webtools::debug_mail = 'on';                   # Show whether real mail must by send
                                                # or must by saved into mail directory!

#[Mail]
$webtools::sendmail = '/usr/sbin/sendmail';     # sendmail path

#[Other]
$webtools::charset = '3sHAw6Yn5b0xzJKL8mUIvcOPZ2aWytCMlQu7SVBhR9kjdgfq1prEe4oiDFGTNX';
                                           # Please mix well this chars
					   # to get higher security of your session ID :-)

$webtools::cpg_priority = 'cookie';        # Show order of value fetching! There is 2 values: 'cookie' and 'get/post'.
                                           # 'cookie' means that cookie's variable has higher priority!
$webtools::sess_force_flat = 'on';         # Session support via DB or via file! (possible values are: 'on' and 'off')

$webtools::support_email = 'support@your_host.com';  # Support e-mail
$webtools::var_printing_mode = 'buffered';           # Default output is buffered,
                                           # leave this variable empty if you need output
                                           # of your script to flush 
                                           # immediately!
@webtools::treat_htmls_ext = (             # Order of html files location: Default, module first look for:
	            'whtml',               # "whtml","html","htm","cgihtml" and "cgi". If you specify in URL
	            'html',                # ...?file=env.html script will ignore extension and will look for
	            'htm',                 # file with extension orderd in @treat_htmls_ext array
	            'cgihtml',             # If you leave this array empty then no lookups will be made!
	            'cgi',                 # Please read carefull documentation (HELP.html) for additional info.
	           );
# Example:
# @webtools::treat_htmls_ext = (           # If Apache return as plain text your "whtml" file in cgi-bin
#                     'whtml',             # directory, then you can rename your "whtml" file to "cgi"!
#     	              'cgihtml'            # So process.cgi will be able to handle your query:
#                     'html',              # ...?file=test.whtml despite that real name is test.cgi !
#                     'htm',
#                     'cgi',
#  	             );

#[PATHS]
$webtools::tmp = '/tmp/';                        # Temp directory
$webtools::driver_path = './drivers/';           # Driver`s path
$webtools::library_path = './libs/';             # Librarie`s path
$webtools::db_path = './db/';                    # DB`s path
$webtools::mailsender_path = './mail/';          # Mail`s path
$webtools::xreader_path = './jhtml/';            # Path of xreader files(jhtml-s)
$webtools::perl_html_dir = './htmls/';           # Directory were peril’s html files are (/usr/local/apache/perlhtml/)
$webtools::apacheshtdocs = '/var/www/htdocs/';   # '/usr/local/apache/htdocs/'
$webtools::cgi_home_path = Get_CGI_Directory();  # Get webtools cgi-bin directory (exam: '/cgi-bin/webtools/')
					         # NOTE: This path is not absolute and is not an HTTP!!!
$webtools::http_home_path = '/webtools/';        # Please change this to your http path!

@webtools::use_addition_paths = ('./db/');       # Push paths in this array to force using of these
                                                 # directories from Perl

###################################################################
# ------- DO NOT EDIT BELOW THIS LINE!!! -------
###################################################################

# 
# Determinate OS type
# 

unless ($webtools::sys_OS) 
 {
  unless ($webtools::sys_OS = $^O) 
     {
      require Config;
      $webtools::sys_OS = $Config::Config{'osname'};
     }
 }
if    ($webtools::sys_OS =~ /^MSWin/i){$webtools::sys_OS = 'WINDOWS';}
elsif ($webtools::sys_OS =~ /^VMS/i) {$webtools::sys_OS = 'VMS';}
elsif ($webtools::sys_OS =~ /^dos/i) {$webtools::sys_OS = 'DOS';}
elsif ($webtools::sys_OS =~ /^MacOS/i) {$webtools::sys_OS = 'MACINTOSH';}
elsif ($webtools::sys_OS =~ /^os2/i) {$webtools::sys_OS = 'OS2';}
elsif ($webtools::sys_OS =~ /^epoc/i) {$webtools::sys_OS = 'EPOC';}
else  {$webtools::sys_OS = 'UNIX'; }

$webtools::needs_binmode = $webtools::sys_OS=~/^(WINDOWS|DOS|OS2|MSWin)/;

# 
# The path separator is a slash, backslash or semicolon, depending
# on the paltform.
# 

$webtools::SL = {
       UNIX=>'/', OS2=>'\\', EPOC=>'/', 
       WINDOWS=>'\\', DOS=>'\\', MACINTOSH=>':', VMS=>'/'
      }->{$webtools::sys_OS};

# 
# Define the CRLF sequence.
# 

$webtools::sys_EBCDIC = "\t" ne "\011";
if ($webtools::sys_OS eq 'VMS') {$webtools::sys_CRLF = "\n";}
elsif ($webtools::sys_EBCDIC)   {$webtools::sys_CRLF= "\r\n";}
else {$webtools::sys_CRLF = "\015\012";}

$webtools::mysqlbequiet = '1';
%webtools::dts = ('second' => 's','minute' => 'm', 'hour' => 'h', 'day' => 'd', 'month' => 'M', 'year' => 'y');
%webtools::dts_flat = ('second' => 1,'minute' => 60, 'hour' => 3600, 'day' => 86400, 'month' => 2678400, 'year' => 31536000);
$webtools::sys_c_d_h = $webtools::dts{$webtools::sys_conf_d};
$webtools::sesstimead = '+'.$webtools::sess_time.$webtools::sys_c_d_h;
$webtools::sess_datetype = $webtools::sys_conf_d;
$webtools::sys_time_for_flat_sess = $webtools::dts_flat{$webtools::sys_conf_d} * $webtools::sess_time;
$webtools::uni_sep = '©';                            # Col separator
$webtools::uni_sep_t = '\©';                         # Col separator (slashed)
$webtools::uni_gr_sep = ':';                         # Row separator
$webtools::uni_gr_sep_t = '\:';                      # Row separator (slashed)
$webtools::uni_esc = '%';                            # Escape char
$webtools::config_path   = PathMaker('./conf/','../conf/');
$webtools::library_path  = PathMaker($webtools::library_path,'.'.$webtools::library_path);
$webtools::db_path       = PathMaker($webtools::db_path,'.'.$webtools::db_path);
$webtools::driver_path   = PathMaker($webtools::driver_path,'.'.$webtools::driver_path);
$webtools::xreader_path  = PathMaker($webtools::xreader_path,'.'.$webtools::xreader_path);
$webtools::perl_html_dir = PathMaker($webtools::perl_html_dir,'.'.$webtools::perl_html_dir);

my $path;
foreach $path (@webtools::use_addition_paths) { PathMaker($path,$path); }

####################################################################################
# Stop execution of scripts till site is down
####################################################################################
if (($webtools::site_is_down =~ m/^on$/si) and !($ENV{'SCRIPT_NAME'} =~ m/\/install\.cgi$/si))
 {
  CORE::print STDOUT "Content-type: text/html\n\n";
  CORE::print STDOUT "<B><font style='font-size:11pt' face='Verdana'>Dear Visitors,<BR><BR></B>";
  CORE::print STDOUT "<B><font color='red'>";
  CORE::print STDOUT "Sorry for inconvenience but currently this site is down due software reconstructions!<BR><BR>";
  CORE::print STDOUT "It will be back available as soon as possible!<BR>";
  CORE::print STDOUT "</font></B></font>\n";
  CORE::exit;
 }

####################################################################################
# This part check structure of script
# If $check_module_functions equal on 'true' then this check is performed always!!!
# If you have already checked structure please turn this feature off!!!
####################################################################################
if ($webtools::check_module_functions =~ m/^on$/si)
 {
  require 'check.pl';
  check_configuration();
 }

$webtools::loading_cfg_fail = 0;

sub PathMaker                 # Make paths to your base webtools files!
 {
  my $pth = (-e $_[0]) ? $_[0] : $_[1];
  if($_[0] =~ m/^(\\|\/)$/si) {return ('/');}
  if($_[0] ne '')
  {
    eval ("use lib \'$pth\';"); return($pth);
  }
  return ('');
 }
 
sub Get_CGI_Directory         
 {
  my $path =  $ENV{'SCRIPT_NAME'};
  if($path =~ m/^(.*?)\/process\.cgi/is)
   {
    return($1.'/');
   }
  return('');
 }
$webtools::sys_config_pl_loaded = 1;

1;