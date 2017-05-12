#!/usr/bin/perl
# Change shebang if script refuse to work!

# ===----- PLEASE CONFIGURE "INSTALL" SCRIPT -----===

# This variable show whether this script should run!
# Set this variable to '1' if you want to permit this
# script to run via WEB!
# After sucessful install please set this variable back
# to '0' to protect yourself from external interventions!
# This is a very important for your security!

# PLEASE BE RESPONSIBLE ABOUT YOUR SECURITY!
my $install_script_available = '0';

# This is ADMIN USER for 'install' script. Please EDIT!
# user name must match /^[A-Za-z0-9_]*$/
my $install_only_user = 'admin';

# This is default PASSWORD for 'install' script. Please EDIT!
my $install_only_pass = '';

# Note: YOU CAN'T LEAVE THESE DEFAULT SETTINGS UNTOUCHED!

# All these variables protect your 'config.pl' file from
# external (WEB) users (hackers). That is needful because
# this script view/edit(configure) your config.pl file!

# ===----- DO NOT EDIT BELOW THIS LINE! -----===

##########################################################

# Copyright (c) 2001, Julian Lishev, Sofia 2002
# All rights reserved.
# This code is free software; you can redistribute
# it and/or modify it under the same terms 
# as Perl itself.

##########################################################
use strict;
##########################################################
local $| = 1;
my $config = './conf/';
my $f_b = '<font face="Verdana, Arial, Helvetica, sans-serif" size="2">';
my $f_e = '</font>';

##########################################################


# ---------------- Main check routine ----------------

if($install_script_available ne '1')
 {
  print "Content-type: text/html\n\n";
  print << "END_OF_HTML";
  $f_b
  <H3><U>WebTools Configure</U></H3>
  <table width="100%"><TR><TD width="100%" bgcolor="#D0D080">$f_b
  <B><center>Powered by <A href="http://www.proscriptum.com/">www.proscriptum.com</A></center></B>$f_e
  </TD></TR></TABLE><BR>
  $f_e
END_OF_HTML
  print $f_b."<B>Access denied!<BR><BR>";
  print "<font color='red'>Reason: Variable \$install_script_available is set to: $install_script_available</font><BR><BR>";
  print "Hint: Edit file 'install.cgi' and set \$install_script_available variable to '1'</B>";
  print << "END_OF_HTML";
  $f_b
  <BR><BR>
  <table width="100%"><TR><TD width="100%" bgcolor="#D0D080">$f_b
  <B><center>All rights reserved by <A href="http://www.proscriptum.com/">Julian Lishev</A> , Sofia 2002</center></B>$f_e
  </TD></TR></TABLE><BR>
  $f_e
END_OF_HTML
  exit;
 }

if(!(-e $config.'config.pl'))
 {
  print "Content-type: text/html\n\n";
  print << "END_OF_HTML";
  $f_b
  <H3><U>WebTools Configure</U></H3>
  <table width="100%"><TR><TD width="100%" bgcolor="#D0D080">$f_b
  <B><center>Powered by <A href="http://www.proscriptum.com/">www.proscriptum.com</A></center></B>$f_e
  </TD></TR></TABLE><BR>
  $f_e
END_OF_HTML
  print $f_b."<B>Error!<BR><BR>";
  print "<font color='red'>Can't find ./conf/config.pl file!</font> This package is not installed properly!<BR><BR>";
  print "Hint: See whether you have in your 'webtools' directory ./conf/config.pl file!</B>".$f_e;
  print << "END_OF_HTML";
  $f_b
  <BR><BR>
  <table width="100%"><TR><TD width="100%" bgcolor="#D0D080">$f_b
  <B><center>All rights reserved by <A href="http://www.proscriptum.com/">Julian Lishev</A> , Sofia 2002</center></B>$f_e
  </TD></TR></TABLE><BR>
  $f_e
END_OF_HTML
  exit;
 }

if(DirectoryRights($config,3) ne 'ok')
 {
  print "Content-type: text/html\n\n";
  print << "END_OF_HTML";
  $f_b
  <H3><U>WebTools Configure</U></H3>
  <table width="100%"><TR><TD width="100%" bgcolor="#D0D080">$f_b
  <B><center>Powered by <A href="http://www.proscriptum.com/">www.proscriptum.com</A></center></B>$f_e
  </TD></TR></TABLE><BR>
  $f_e
END_OF_HTML
  print $f_b."<B>Error!<BR><BR>";
  print "<font color='red'>conf/ directory is not readable/writeable!</font><BR><BR>";
  print "Hint: See whether mode of conf/ directory is 755! If it isn't please execute follow command:<BR>";
  print "<font color='red'>chmod 755 conf/</font></B><BR>";
  print "(If apache run scripts with it's user you may need to ";
  print "chmod directory to 777) </B>".$f_e;
  print << "END_OF_HTML";
  $f_b
  <BR><BR>
  <table width="100%"><TR><TD width="100%" bgcolor="#D0D080">$f_b
  <B><center>All rights reserved by <A href="http://www.proscriptum.com/">Julian Lishev</A> , Sofia 2002</center></B>$f_e
  </TD></TR></TABLE><BR>
  $f_e
END_OF_HTML
  exit;
 }

my $conf_code = load_file($config.'config.pl');
my $res = 0;

if($conf_code != -1)
 {
  $res = 1;
  if(save_file($config.'config.pl',$conf_code) > 0)
   {
    $res = 3;
   }
 }

if($res != 3)
 {
  print "Content-type: text/html\n\n";
  print << "END_OF_HTML";
  $f_b
  <H3><U>WebTools Configure</U></H3>
  <table width="100%"><TR><TD width="100%" bgcolor="#D0D080">$f_b
  <B><center>Powered by <A href="http://www.proscriptum.com/">www.proscriptum.com</A></center></B>$f_e
  </TD></TR></TABLE><BR>
  $f_e
END_OF_HTML
  print $f_b."<B>Error!<BR><BR>";
  print "<font color='red'>conf/config.pl file is not readable/writeable!</font><BR><BR>";
  print "Hint: See whether mode of conf/config.pl file is 644! If it isn't please execute follow command:<BR>";
  print "<font color='red'>chmod 644 conf/config.pl</font><BR>";
  print "(If apache run scripts with it's user you may need to ";
  print "chmod file to 777) </B>".$f_e;
  print << "END_OF_HTML";
  $f_b
  <BR><BR>
  <table width="100%"><TR><TD width="100%" bgcolor="#D0D080">$f_b
  <B><center>All rights reserved by <A href="http://www.proscriptum.com/">Julian Lishev</A> , Sofia 2002</center></B>$f_e
  </TD></TR></TABLE><BR>
  $f_e
END_OF_HTML
  exit;
 }

if(($install_only_user =~ m/^admin$/si) and ($install_only_pass eq ''))
 {
  print "Content-type: text/html\n\n";
  print << "END_OF_HTML";
  $f_b
  <H3><U>WebTools Configure</U></H3>
  <table width="100%"><TR><TD width="100%" bgcolor="#D0D080">$f_b
  <B><center>Powered by <A href="http://www.proscriptum.com/">www.proscriptum.com</A></center></B>$f_e
  </TD></TR></TABLE><BR>
  $f_e
END_OF_HTML
  print $f_b."<B>Everything looks good, but I have to deny your access till security problem occured!<BR><BR>";
  print "<font color='red'>Reason: Your user name and password are set to default!</font><BR><BR>";
  print "Hint: Edit file 'install.cgi' and change deafault user name and/or password!</B>";
  print $f_e;
  print << "END_OF_HTML";
  $f_b
  <BR><BR>
  <table width="100%"><TR><TD width="100%" bgcolor="#D0D080">$f_b
  <B><center>All rights reserved by <A href="http://www.proscriptum.com/">Julian Lishev</A> , Sofia 2002</center></B>$f_e
  </TD></TR></TABLE><BR>
  $f_e
END_OF_HTML
  exit;
 }

# --------- If Perl is here that is a good sign! :-) ----------
print "Expires: Mon, 26 Jul 1997 05:00:00 GMT\n";
print "Cache-Control: no-cache, must-revalidate, post-check=0, pre-check=0\n";
print "Pragma: no-cache\n";
print "Content-type: text/html\n";

# Parse input data:

use CGI;
my $input = new CGI;
my $action = $input->param('action');
my $do     = $input->param('do');
my $type   = $input->param('type');
my $name   = $input->param('name');
my $user_admin   = $input->param('user_admin');
my $pass_admin   = $input->param('pass_admin');
my $flag   = 'get/post';
my %COOKIES = ();

&read_cookies();

my $scriptname = $ENV{SCRIPT_NAME};

# ------------ Main loop of install program --------------

if(($user_admin ne $install_only_user) or ($pass_admin ne $install_only_pass))
{
 $user_admin = read_cookie('user_admin');
 $pass_admin = read_cookie('pass_admin');
 $flag = 'cookies';
 if(($user_admin ne $install_only_user) or ($pass_admin ne $install_only_pass))
  {
   if(($input->param('user_admin') ne '') or ($input->param('pass_admin') ne '')) { sleep(8); }
   print "\n";   # Close HTTP header
   LogInPage();
   exit;
  }
}

if($action eq 'logout')
{
 del_cookie('user_admin');
 del_cookie('pass_admin');
 print "\n";   # Close HTTP header
 LogInPage();
 exit;
}

if($action eq '')
{
 if(($user_admin eq $install_only_user) and ($pass_admin eq $install_only_pass))
   {
    if($flag eq 'get/post')
     {
      set_cookie('user_admin',$user_admin);
      set_cookie('pass_admin',$pass_admin);
     }
   }
 print "\n";   # Close HTTP header
 MainMenu();
 exit;
}

if($action eq 'database')
{
 if($type eq 'flat')
  {
   ShowFlatMain();
  }
 if($type eq 'mysql')
  {
   ShowMysqlMain();
  }
 print "\n";   # Close HTTP header
 if(($do eq '') and ($type eq ''))
  {
   ShowDBs();
  }
 exit;
}

print "\n";   # Close HTTP header

if($action eq 'config')
{
 if($do eq 'save')
  {
   SaveConfig($input);
   $do = '';
  }
 if($do eq '')
  {
   ConfigForm();
  }
 exit;
}



# ------------ FUNCTIONS FOR INSTALL ROUTINE --------------
sub load_file
{
 my ($file) = shift(@_);
 local *FILE;
 if(-e $file)
  {
   open(FILE,$file) or return(-1);
   binmode(FILE);
   my $load;
   read(FILE,$load,(-s $file));
   close FILE;
   return($load);
  }
 else {return(-1);}
}

sub save_file
{
 my ($file) = shift(@_);
 my ($data) = shift(@_);
 local *FILE;
 open(FILE,'>'.$file) or return(-1);
 binmode(FILE);
 print FILE $data || return(-1);
 close FILE;
 return(1);
}

sub trim
{
 my $str = shift(@_);
 $str =~ s/^\ *//s;
 $str =~ s/\ *$//s;
 return($str);
}
###########################################
# Cookies
###########################################
sub set_cookie
{
 my ($name,$val) = @_;
 print "Set-Cookie: $name=$val; path=/;\n";
 return 1;
}

sub del_cookie
{
 my ($name) = @_;
 print "Set-Cookie: $name=; path=/; expires=0;\n";
 return 1;
}

sub read_cookie
{
 my ($name) = @_;
 return($COOKIES{$name});
}

sub read_cookies
{
  my $id = $ENV{HTTP_COOKIE} || $ENV{COOKIE};
  my @cookies = split(/;/s,$id);
  my $l;
  foreach $l (@cookies)
   {
    if($l ne '') 
      {
       my ($n,$v) = split(/=/s,$l);
       $n =~ s/ //sg;
       $n =~ s/\[^A-Za-z0-9_]//sg;
       if (!exists($COOKIES{$n}))
         {
          $COOKIES{$n} = $v;
         }
      }
   }
}
################################
# Make scalar from scalars
################################
sub MakeScalar
{
 my @a = @_;
 my $sclr = '';
 
 my $escape = "\Ž";
 my $row_sep = "\™";
 my $col_sep = "\®";
 
 my $nxt = 0;
 my $self = '';
 my $l;
 
 foreach $l (@a)
  {
   if($nxt)
    {
     $sclr .= $self.$col_sep.encode_separator($l, $escape, $row_sep, $col_sep);
     $nxt--;
    }
   else
    {
     $self = encode_separator($l, $escape, $row_sep, $col_sep);
     $nxt++;
    }
   $sclr .= $row_sep;
  }
 return($sclr);
}

################################
# Make array from scalars
################################
sub MakeArray
{
 my ($sclr) = @_;
 my @a = ();
 my @result = (); 
 
 my $escape = "\Ž";
 my $row_sep = "\™";
 my $col_sep = "\®";
 
 @a = split(/\™/s,$sclr);
 my $line;
 foreach $line (@a)
  {
   my ($a,$b) = split(/$col_sep/,$line);
   $a = decode_separator($a, $escape, $row_sep, $col_sep);
   $b = decode_separator($b, $escape, $row_sep, $col_sep);
   push (@result,$a);
   push (@result,$b);
  }
 return(@result);
}

sub encode_separator
  {
    my ($str, $escape, $row_sep, $col_sep) = @_;

    my $esc_hex = uc($escape.join('',unpack("Hh", $escape x 2)));
    my $row_hex = uc($escape.join('',unpack("Hh",$row_sep x 2)));
    my $col_hex = uc($escape.join('',unpack("Hh",$col_sep x 2)));
    
    $escape = quotemeta($escape);
    $row_sep = quotemeta($row_sep);
    $col_sep = quotemeta($col_sep);
    
    $str =~ s/$escape/$esc_hex/gsi;
    $str =~ s/$row_sep/$row_hex/gsi;  
    $str =~ s/$col_sep/$col_hex/gsi;
    return($str);
  }

sub decode_separator
  {
    my ($enstr, $escape, $row_sep, $col_sep) = @_;

    my $esc_hex = uc($escape.join('',unpack("Hh", $escape x 2)));
    my $row_hex = uc($escape.join('',unpack("Hh",$row_sep x 2)));
    my $col_hex = uc($escape.join('',unpack("Hh",$col_sep x 2)));
    
    $enstr =~ s/$esc_hex/$escape/gsi;
    $enstr =~ s/$row_hex/$row_sep/gsi;  
    $enstr =~ s/$col_hex/$col_sep/gsi;
    return($enstr);
  }
  
sub DirectoryRights
 {
  my ($path,$mask) = @_;
  my $result = 0;
  #  mask can be: 1-Read test; 2-Write test;
  if (-e $path)
   {
    if ($mask & 1)
      {
       if(!Check_R($path)) {return('Directory is NOT READABLE');}
      }
    else
      {
       if(Check_R($path)) {return('WARNNING: Directory is readable, that is INSECURE!!!');}
      }
    if ($mask & 2)
      {
       if(!Check_W($path)) {return('Can NOT WRITE in directory');}
      }
    else
      {
       if(Check_W($path)) {return('WARNNING: Directory is writeable, that is INSECURE!!!');}
      }
   }
  else
    {
     {return('Directory NOT EXISTS');}
    }
  return('ok');
 }

sub Check_R
{
 my ($path) = @_;
 opendir(FDIR,$path) or return(0);
 closedir(FDIR);
 return(1);
}

sub Check_W
{
 my ($path) = @_;
 if(!($path =~ m/.*\/$/s)) {$path .= '/';}
 my $f = $path.'check_pl_file_'.rand()*1000;
 open(FILE,'>'.$f) or return(0);
 print (FILE 'TEST') or return(0);
 close(FILE);
 unlink($f);
 return(1);
}

sub fetchValue
{
 my ($name) = shift(@_);
 my ($src) = shift(@_);
 
 if($src =~ m/\$webtools\:\:$name\ *?\=\ *?(\'|\")(.*?)(\'|\")\;/s)
  {
   return($2);
  }
 else {return(undef);}
}

sub setValue
{
 my ($name) = shift(@_);
 my ($val) = shift(@_);
 my ($src) = shift(@_);
 
 if($src =~ s/(\$webtools\:\:$name\ *?\=\ *?)(\'|\")(.*?)(\'|\")\;/$1$2$val$4\;/sg)
  {
   return($src);
  }
 else
  {
   return(undef);
  }
}

sub LogInPage
{
 print << "END_OF_HTML";
 $f_b
 <H3><U>WebTools Configure</U></H3>
 <table width="100%"><TR><TD width="100%" bgcolor="#D0D080">$f_b
 <B><center>Powered by <A href="http://www.proscriptum.com/">www.proscriptum.com</A></center></B>$f_e
 </TD></TR></TABLE><BR>
 <b>Please enter your user name and password in Admin form<BR>
 After sucessful login you will be able to configure your WebTools<BR><BR>
 <form METHOD='POST' ACTION='$scriptname'>
 <input name='action' value='' type='hidden'>
 <table>
 <tr><td width='100'>$f_b<B>User:</B>$f_e</td><td><input name='user_admin' value='' type='text' onFocus="javascript: this.select();" onMouseOver="javascript: this.focus();"></td></tr>
 <tr><td width='100'>$f_b<B>Password:</B>$f_e</td><td><input name='pass_admin' value='' type='password' onFocus="javascript: this.select();" onMouseOver="javascript: this.focus();"></td></tr>
 <tr><td width='100'></td><td><input value='Enter' type='submit'></td></tr>
 </table>
 </form>
 Note: Install.cgi use 'session' cookies to simulate simple session needed to secure this Web based script!
 <BR><BR>
 <table width="100%"><TR><TD width="100%" bgcolor="#D0D080">$f_b
 <B><center>All rights reserved by <A href="http://www.proscriptum.com/">Julian Lishev</A> , Sofia 2002</center></B>$f_e
 </TD></TR></TABLE><BR>
END_OF_HTML
 print $f_e;
}

sub MainMenu
{
 print << "END_OF_HTML";
 <B>$f_b
 <H3><U>WebTools Configure</U></H3>
 <table width="100%"><TR><TD width="100%" bgcolor="#D0D080">$f_b
 <B><center>Powered by <A href="http://www.proscriptum.com/">www.proscriptum.com</A></center></B>$f_e
 </TD></TR></TABLE><BR>
 Use follow links to manage install script:<BR><BR>
 <A href="$scriptname?action=config">config.pl</A>
 <BR>
 <A href="$scriptname?action=database">database</A>
 <BR><BR>
 <A href="$scriptname?action=logout">LogOut</A>
 </B>$f_e
 <BR><BR>
 <table width="100%"><TR><TD width="100%" bgcolor="#D0D080">$f_b
 <B><center>All rights reserved by <A href="http://www.proscriptum.com/">Julian Lishev</A> , Sofia 2002</center></B>$f_e
 </TD></TR></TABLE><BR>
END_OF_HTML
}

sub ConfigForm
{

#[Name_Of_Project]
my $projectname = fetchValue('projectname',$conf_code);

#[SQL]
my $db_support = fetchValue('db_support',$conf_code);
my $sql_host = fetchValue('sql_host',$conf_code);
my $sql_port = fetchValue('sql_port',$conf_code);
my $sql_user = fetchValue('sql_user',$conf_code);
my $sql_pass = fetchValue('sql_pass',$conf_code);

#[CHECK]
my $check_module_functions = fetchValue('check_module_functions',$conf_code);

#[Secure]
my $site_is_down = fetchValue('site_is_down',$conf_code);
my $wait_attempt = fetchValue('wait_attempt',$conf_code);
my $wait_for_open = fetchValue('wait_for_open',$conf_code);
my $sess_time = fetchValue('sess_time',$conf_code);
my $sys_conf_d = fetchValue('sys_conf_d',$conf_code);

my $rand_sid_length = fetchValue('rand_sid_length',$conf_code);
my $sess_cookie = fetchValue('sess_cookie',$conf_code);

my $l_sid = fetchValue('l_sid',$conf_code);

my $cgi_lib_forbid_mulipart = fetchValue('cgi_lib_forbid_mulipart',$conf_code);

my $cgi_lib_maxdata    = fetchValue('cgi_lib_maxdata',$conf_code);
my $cgi_script_timeout = fetchValue('cgi_script_timeout',$conf_code);
my $ip_restrict_mode   = fetchValue('ip_restrict_mode',$conf_code);

my $run_restrict_mode  = fetchValue('run_restrict_mode',$conf_code);
                                      
#[Debug]
my $debugging = fetchValue('debugging',$conf_code);
my $debug_mail = fetchValue('debug_mail',$conf_code);

#[Mail]
my $sendmail = fetchValue('sendmail',$conf_code);

#[Other]
my $charset = fetchValue('charset',$conf_code);

my $cpg_priority = fetchValue('cpg_priority',$conf_code);

my $sess_force_flat = fetchValue('sess_force_flat',$conf_code);

my $support_email = fetchValue('support_email',$conf_code);
my $var_printing_mode = fetchValue('var_printing_mode',$conf_code);

#[PATHS]
my $tmp = fetchValue('tmp',$conf_code);
my $driver_path = fetchValue('driver_path',$conf_code);
my $library_path = fetchValue('library_path',$conf_code);
my $db_path = fetchValue('db_path',$conf_code);
my $mailsender_path = fetchValue('mailsender_path',$conf_code);
my $xreader_path = fetchValue('xreader_path',$conf_code);
my $perl_html_dir = fetchValue('perl_html_dir',$conf_code);
my $apacheshtdocs = fetchValue('apacheshtdocs',$conf_code);

my $http_home_path = fetchValue('http_home_path',$conf_code);

my $db_support_S = getSelect('db_support',$db_support,'db_flat','db_mysql','db_access','');
my $check_module_functions_S = getSelect('check_module_functions',$check_module_functions,'on','off');
my $site_is_down_S = getSelect('site_is_down',$site_is_down,'on','off');
my $sys_conf_d_S = getSelect('sys_conf_d',$sys_conf_d,'second','minute','hour','day','month','year');
my $sess_cookie_S = getSelect('sess_cookie',$sess_cookie,'sesstime','0');
my $cgi_lib_forbid_mulipart_S = getSelect('cgi_lib_forbid_mulipart',$cgi_lib_forbid_mulipart,'on','off');

my $ip_restrict_mode_S = getSelect('ip_restrict_mode',$check_module_functions,'on','off');
my $run_restrict_mode_S = getSelect('run_restrict_mode',$run_restrict_mode,'on','off');
my $debugging_S = getSelect('debugging',$debugging,'on','off');
my $debug_mail_S = getSelect('debug_mail',$debug_mail,'on','off');
my $cpg_priority_S = getSelect('cpg_priority',$cpg_priority,'cookie','get/post');
my $sess_force_flat_S = getSelect('sess_force_flat',$sess_force_flat,'on','off');
my $var_printing_mode_S = getSelect('var_printing_mode',$var_printing_mode,'buffered','non-buffered');

 print << "END_OF_HTML";
 $f_b
 <H3><U>WebTools Configure</U></H3>
 <table width="100%"><TR><TD width="100%" bgcolor="#D0D080">$f_b
 <B><center><A href="$scriptname?action=">main menu</A></center></B>$f_e
 </TD></TR></TABLE><BR>
 <B>
 These values are related to WebTools configuration. Using this script practicality you will edit config.pl file!<BR><BR>
 <form METHOD='POST' ACTION='$scriptname'>
 <input name='action' value='config' type='hidden'>
 <input name='do' value='save' type='hidden'>
 <input name='user_admin' value='$user_admin' type='hidden'>
 <input name='pass_admin' value='$pass_admin' type='hidden'>
 <table>
 <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Name of project:</B>$f_e</td>
  <td><input name='projectname' value='$projectname' type='text' size="20" onFocus="javascript: this.select();" onMouseOver="javascript: this.focus();"></td></tr>
 <TR><TD><BR></TD><TD><BR></TD></TR>
 <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Type of SQL server:</B>$f_e</td>
  <td>$f_b$db_support_S$f_e</td></tr>
 <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Host of SQL server:</B>$f_e</td>
  <td><input name='sql_host' value='$sql_host' type='text' size="20" onFocus="javascript: this.select();" onMouseOver="javascript: this.focus();"></td></tr>
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Port of SQL server:</B>$f_e</td>
  <td><input name='sql_port' value='$sql_port' type='text' size="20" onFocus="javascript: this.select();" onMouseOver="javascript: this.focus();"></td></tr>
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>User of SQL server:</B>$f_e</td>
  <td><input name='sql_user' value='$sql_user' type='text' size="20" onFocus="javascript: this.select();" onMouseOver="javascript: this.focus();"></td></tr>
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Respective password:</B>$f_e</td>
  <td><input name='sql_pass' value='$sql_pass' type='text' size="20" onFocus="javascript: this.select();" onMouseOver="javascript: this.focus();"></td></tr>
  <TR><TD><BR></TD><TD><BR></TD></TR>
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Default database name:</B>$f_e</td>
  <td>$f_b<B>'$projectname\db'</B> (project name plus 'db' at the end)$f_e</td></tr>
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Default sessions table:</B>$f_e</td>
  <td>$f_b<B>'$projectname\_sessions'</B> (project name plus '_sessions' at the end)$f_e</td></tr>
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Default users table:</B>$f_e</td>
  <td>$f_b<B>'$projectname\_users'</B> (project name plus '_users' at the end)$f_e</td></tr>
  <TR><TD><BR></TD><TD><BR></TD></TR>
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Checking mode:</B>$f_e</td>
  <td>$f_b$check_module_functions_S$f_e</td></tr>
  <TR><TD><BR></TD><TD><BR></TD></TR>
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>WebTools(your site) is down:</B>$f_e</td>
  <td>$f_b$site_is_down_S (Set this field to '<B>on</B>' if you want to 'stop' your site /scripts side/)$f_e</td></tr>
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Count of attempts:</B>$f_e</td>
  <td><input name='wait_attempt' value='$wait_attempt' type='text' size="20" onFocus="javascript: this.select();" onMouseOver="javascript: this.focus();"></td></tr>  
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Time between two attempts:</B>$f_e</td>
  <td><input name='wait_for_open' value='$wait_for_open' type='text' size="20" onFocus="javascript: this.select();" onMouseOver="javascript: this.focus();"> $f_b (in seconds) $f_e</td></tr>
  <TR><TD><BR></TD><TD><BR></TD></TR>
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Period of session time:</B>$f_e</td>
  <td><input name='sess_time' value='$sess_time' type='text' size="7" onFocus="javascript: this.select();" onMouseOver="javascript: this.focus();">$f_b $sys_conf_d_S$f_e</td></tr>
  <TR><TD><BR></TD><TD><BR></TD></TR>
 
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Length of session ID:</B>$f_e</td>
  <td><input name='rand_sid_length' value='$rand_sid_length' type='text' size="20" onFocus="javascript: this.select();" onMouseOver="javascript: this.focus();"> $f_b (in chars) $f_e</td></tr>
  
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Type of cookie expiration:</B>$f_e</td>
  <td>$f_b$sess_cookie_S (Set '<B>sesstime</B>' if you want cookie to expire with 'session time' or set '<B>0</B>' if you want cookie to expire when user close browser)$f_e</td></tr>
  
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Session ID label:</B>$f_e</td>
  <td><input name='l_sid' value='$l_sid' type='text' size="20" onFocus="javascript: this.select();" onMouseOver="javascript: this.focus();"></td></tr>
  <TR><TD><BR></TD><TD><BR></TD></TR>
  
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Disallow multipart data:</B>$f_e</td>
  <td>$f_b$cgi_lib_forbid_mulipart_S$f_e</td></tr>
  
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Maximum data through POST:</B>$f_e</td>
  <td><input name='cgi_lib_maxdata' value='$cgi_lib_maxdata' type='text' size="20" onFocus="javascript: this.select();" onMouseOver="javascript: this.focus();"> $f_b(in bytes)$f_e</td></tr>
  <TR><TD><BR></TD><TD><BR></TD></TR>
  
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Timeout of CGI scripts:</B>$f_e</td>
  <td><input name='cgi_script_timeout' value='$cgi_script_timeout' type='text' size="20" onFocus="javascript: this.select();" onMouseOver="javascript: this.focus();"> $f_b(in seconds)$f_e</td></tr>
  <TR><TD><BR></TD><TD><BR></TD></TR>
  
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Restrict sessions by IP:</B>$f_e</td>
  <td>$f_b$ip_restrict_mode_S$f_e</td></tr>
  
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Restrict scripts by IP:</B>$f_e</td>
  <td>$f_b$run_restrict_mode_S$f_e</td></tr>
  <TR><TD><BR></TD><TD><BR></TD></TR>
  
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Run scripts in debug mode:</B>$f_e</td>
  <td>$f_b$debugging_S (If you choice '<B>on</B>' and error appear in script then WebTools will print error in browser)$f_e</td></tr>
  
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Send mails in debug mode:</B>$f_e</td>
  <td>$f_b$debug_mail_S (only for send_mail() function, so if you send mail in '<B>on</B>' mode, then all your mails will appear in mail directory and they never be sent!)$f_e</td></tr>
  <TR><TD><BR></TD><TD><BR></TD></TR>
  
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Full path of sendmail program:</B>$f_e</td>
  <td><input name='sendmail' value='$sendmail' type='text' size="20" onFocus="javascript: this.select();" onMouseOver="javascript: this.focus();"></td></tr>
  <TR><TD><BR></TD><TD><BR></TD></TR>
  
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Mix charset for session ID generation:</B>$f_e</td>
  <td><input name='charset' value='$charset' type='text' size="80" onFocus="javascript: this.select();" onMouseOver="javascript: this.focus();"> $f_b(just mix well this chars)$f_e</td></tr>
  <TR><TD><BR></TD><TD><BR></TD></TR>
  
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Priority of global variables:</B>$f_e</td>
  <td>$f_b$cpg_priority_S (If you choice '<B>cookie</B>' then all cookie variables will rewrite these from get/post and vice versa)$f_e</td></tr>
  <TR><TD><BR></TD><TD><BR></TD></TR>
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Use flat files for session support:</B>$f_e</td>
  <td>$f_b$sess_force_flat_S (If you choice '<B>on</B>' then all sessions will be saved in flat files in your 'tmp' directory other else sessions will be saved in your defult database!)$f_e</td></tr>
  
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Default support mail:</B>$f_e</td>
  <td><input name='support_email' value='$support_email' type='text' size="25" onFocus="javascript: this.select();" onMouseOver="javascript: this.focus();"> $f_b(If errors in your scripts appear then this mail will be printed in browser)$f_e</td></tr>
  <TR><TD><BR></TD><TD><BR></TD></TR>
  
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Set print mode:</B>$f_e</td>
  <td>$f_b$var_printing_mode_S (If you choice '<B>buffered</B>' then all prints will be cached!(default & recommended))$f_e</td></tr>
  <TR><TD><BR></TD><TD><BR></TD></TR>
  
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Set TEMP directory:</B>$f_e</td>
  <td><input name='tmp' value='$tmp' type='text' size="25" onFocus="javascript: this.select();" onMouseOver="javascript: this.focus();"> $f_b(At this directory you must have write/read access)$f_e</td></tr>
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Set Drivers directory:</B>$f_e</td>
  <td><input name='driver_path' value='$driver_path' type='text' size="25" onFocus="javascript: this.select();" onMouseOver="javascript: this.focus();"></td></tr>
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Set Library directory:</B>$f_e</td>
  <td><input name='library_path' value='$library_path' type='text' size="25" onFocus="javascript: this.select();" onMouseOver="javascript: this.focus();"></td></tr>
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Set Database directory:</B>$f_e</td>
  <td><input name='db_path' value='$db_path' type='text' size="25" onFocus="javascript: this.select();" onMouseOver="javascript: this.focus();"> $f_b(At this directory you must have write/read access)$f_e</td></tr>
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Set Mail directory:</B>$f_e</td>
  <td><input name='mailsender_path' value='$mailsender_path' type='text' size="25" onFocus="javascript: this.select();" onMouseOver="javascript: this.focus();"> $f_b(At this directory you must have write/read access)$f_e</td></tr>
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Set Template directory:</B>$f_e</td>
  <td><input name='xreader_path' value='$xreader_path' type='text' size="25" onFocus="javascript: this.select();" onMouseOver="javascript: this.focus();"></td></tr>
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Set WHTML(scripts) directory:</B>$f_e</td>
  <td><input name='perl_html_dir' value='$perl_html_dir' type='text' size="25" onFocus="javascript: this.select();" onMouseOver="javascript: this.focus();"></td></tr>
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Set full path of HTDOCS directory:</B>$f_e</td>
  <td><input name='apacheshtdocs' value='$apacheshtdocs' type='text' size="25" onFocus="javascript: this.select();" onMouseOver="javascript: this.focus();"></td></tr>
  <tr><td nowrap width="300" bgcolor="#EEEEEE">$f_b<B>Set WEB based html home directory:</B>$f_e</td>
  <td><input name='http_home_path' value='$http_home_path' type='text' size="25" onFocus="javascript: this.select();" onMouseOver="javascript: this.focus();"> $f_b('<B>/</B>' means HTDOCS (root) directory of your web server. For example '<B>/web/</B>' means 'http://www.yourserver.com/web/')$f_e</td></tr>
  
  
  <TR><TD><BR></TD><TD><BR></TD></TR>
  <tr><td width='100'></td><td><input value='Update' type='submit'></B></td></tr>
 </table>
 </form>
 NOTE:</B> If you want to modify <B>\@treat_htmls_ext</B> and/or <B>\@use_addition_paths</B> you have to open manualy config.pl file!<BR><BR><B>
 <table width="100%"><TR><TD width="100%" bgcolor="#D0D080">$f_b
 <B><center><A href="$scriptname?action=">main menu</A></center></B>$f_e
 </TD></TR></TABLE>
 </B>$f_e
END_OF_HTML
}

sub getSelect
{
 my ($name) = shift(@_);
 my ($value) = shift(@_);
 my @all = @_;
 my $buf = '';
 $buf .= '<SELECT name="'.$name.'">'."\n";
 my $v;
 my $set = 0;
 foreach $v (@all)
  {
   my $def;
   if($v eq $value)
    {
     $def = ' selected';
     $set = 1;
    }
   else { $def = ''; }
   $buf .= '<OPTION value="'.$v.'"'.$def.'>'.$v.'</OPTION>'."\n";
  }
 if(!$set)
  {
   $v = $all[0];
   $buf =~ s/^(.*?)\"\>/$1" selected>/si;
  }
 $buf .= '</SELECT>';
 return($buf);
}

sub SaveConfig
{
 my ($input) = shift(@_);
 
my $projectname = $input->param('projectname');

my $db_support = $input->param('db_support');
my $sql_host = $input->param('sql_host');
my $sql_port = $input->param('sql_port');
my $sql_user = $input->param('sql_user');
my $sql_pass = $input->param('sql_pass');

my $check_module_functions = $input->param('check_module_functions');

my $site_is_down = $input->param('site_is_down');
my $wait_attempt = $input->param('wait_attempt');
my $wait_for_open = $input->param('wait_for_open');
my $sess_time = $input->param('sess_time');
my $sys_conf_d = $input->param('sys_conf_d');

my $rand_sid_length = $input->param('rand_sid_length');
my $sess_cookie = $input->param('sess_cookie');

my $l_sid = $input->param('l_sid');

my $cgi_lib_forbid_mulipart = $input->param('cgi_lib_forbid_mulipart');

my $cgi_lib_maxdata    = $input->param('cgi_lib_maxdata');
my $cgi_script_timeout = $input->param('cgi_script_timeout');
my $ip_restrict_mode   = $input->param('ip_restrict_mode');

my $run_restrict_mode  = $input->param('run_restrict_mode');
                                      
my $debugging = $input->param('debugging');
my $debug_mail = $input->param('debug_mail');

my $sendmail = $input->param('sendmail');

my $charset = $input->param('charset');

my $cpg_priority = $input->param('cpg_priority');

my $sess_force_flat = $input->param('sess_force_flat');

my $support_email = $input->param('support_email');
my $var_printing_mode = $input->param('var_printing_mode');

my $tmp = $input->param('tmp');
my $driver_path = $input->param('driver_path');
my $library_path = $input->param('library_path');
my $db_path = $input->param('db_path');
my $mailsender_path = $input->param('mailsender_path');
my $xreader_path = $input->param('xreader_path');
my $perl_html_dir = $input->param('perl_html_dir');
my $apacheshtdocs = $input->param('apacheshtdocs');

my $http_home_path = $input->param('http_home_path');

# --- Set new values ---
$conf_code = setValue('projectname',trim($projectname),$conf_code);

$conf_code = setValue('db_support',trim($db_support),$conf_code);
$conf_code = setValue('sql_host',trim($sql_host),$conf_code);
$conf_code = setValue('sql_port',trim($sql_port),$conf_code);
$conf_code = setValue('sql_user',trim($sql_user),$conf_code);
$conf_code = setValue('sql_pass',trim($sql_pass),$conf_code);

$conf_code = setValue('check_module_functions',trim($check_module_functions),$conf_code);
$conf_code = setValue('site_is_down',trim($site_is_down),$conf_code);

$conf_code = setValue('wait_attempt',trim($wait_attempt),$conf_code);
$conf_code = setValue('wait_for_open',trim($wait_for_open),$conf_code);
$conf_code = setValue('sess_time',trim($sess_time),$conf_code);
$conf_code = setValue('sys_conf_d',trim($sys_conf_d),$conf_code);

$conf_code = setValue('rand_sid_length',trim($rand_sid_length),$conf_code);
$conf_code = setValue('sess_cookie',trim($sess_cookie),$conf_code);

$conf_code = setValue('l_sid',trim($l_sid),$conf_code);

$conf_code = setValue('cgi_lib_forbid_mulipart',trim($cgi_lib_forbid_mulipart),$conf_code);

$conf_code = setValue('cgi_lib_maxdata',trim($cgi_lib_maxdata),$conf_code);
$conf_code = setValue('cgi_script_timeout',trim($cgi_script_timeout),$conf_code);
$conf_code = setValue('ip_restrict_mode',trim($ip_restrict_mode),$conf_code);

$conf_code = setValue('run_restrict_mode',trim($run_restrict_mode),$conf_code);
                                      
$conf_code = setValue('debugging',trim($debugging),$conf_code);
$conf_code = setValue('debug_mail',trim($debug_mail),$conf_code);

$conf_code = setValue('sendmail',trim($sendmail),$conf_code);

$conf_code = setValue('charset',trim($charset),$conf_code);

$conf_code = setValue('cpg_priority',trim($cpg_priority),$conf_code);

$conf_code = setValue('sess_force_flat',trim($sess_force_flat),$conf_code);

$conf_code = setValue('support_email',trim($support_email),$conf_code);
$conf_code = setValue('var_printing_mode',trim($var_printing_mode),$conf_code);

$conf_code = setValue('tmp',trim($tmp),$conf_code);
$conf_code = setValue('driver_path',trim($driver_path),$conf_code);
$conf_code = setValue('library_path',trim($library_path),$conf_code);
$conf_code = setValue('db_path',trim($db_path),$conf_code);
$conf_code = setValue('mailsender_path',trim($mailsender_path),$conf_code);
$conf_code = setValue('xreader_path',trim($xreader_path),$conf_code);
$conf_code = setValue('perl_html_dir',trim($perl_html_dir),$conf_code);
$conf_code = setValue('apacheshtdocs',trim($apacheshtdocs),$conf_code);

$conf_code = setValue('http_home_path',trim($http_home_path),$conf_code);

save_file($config.'config.pl',$conf_code);
}

sub ShowDBs
{
 print << "END_OF_HTML";
 <B>$f_b
 <H3><U>WebTools Configure</U></H3>
 <table width="100%"><TR><TD width="100%" bgcolor="#D0D080">$f_b
 <B><center><A href="$scriptname?action=">main menu</A></center></B>$f_e
 </TD></TR></TABLE><BR>
 Use follow links to manage your database:<BR><BR>
 <A href="$scriptname?action=database&do=&type=flat">Flat DB</A>
 <BR>
 <A href="$scriptname?action=database&do=&type=mysql">Mysql DB</A>
 <BR><BR><BR>
 </B>$f_e
 <table width="100%"><TR><TD width="100%" bgcolor="#D0D080">$f_b
 <B><center><A href="$scriptname?action=">main menu</A></center></B>$f_e
 </TD></TR></TABLE>
END_OF_HTML
}

sub ShowFlatMain
{
 my $projectname = fetchValue('projectname',$conf_code);
 my $projectnamedb = $projectname.'db';
 my $projectnamesessions = $projectname.'_sessions';
 my $projectnameusers = $projectname.'_users';
 my $sql_user = fetchValue('sql_user',$conf_code);
 my $sql_pass = fetchValue('sql_pass',$conf_code);
 my $db_path = fetchValue('db_path',$conf_code);
 my $driver_path = fetchValue('driver_path',$conf_code);
 my $apass = $input->param('apass');
 my $sqlq = $input->param('sqlq');
 local *SDB;
 
 if($do eq 'create')
 {
  my $check_module_functions = fetchValue('check_module_functions',$conf_code);
  if($check_module_functions =~ m/^on$/si)
   {
    print "\n";
    print $f_b."<B>Sorry can't create database till WebTools is in debug mode!<BR>Please set debug mode in <A href='$scriptname?action=config'>config.pl</A> to 'off'.</B>".$f_e; exit;
    exit;
   }
  my $code = << 'END_TERM';
  use lib "$driver_path";
  use lib "./conf/";
  use lib './modules/';
  use webtools;
  
  webtools::StartUpInit();
  
  webtools::load_database_driver('flat');
  $webtools::db_support = 'db_flat';
END_TERM
  eval $code;
  if($@ ne '') { print $f_b."<B>Sorry can't load needed libraries and modules (check in config.pl your WebTools directories!)</B>".$f_e; exit;}
  my $dbname = $db_path.$projectnamedb.'.sdb';
  if(-e $db_path.$projectnamedb.'.sdb')
   {
    unlink($db_path.$projectnamedb.'.sdb');
    unlink($db_path.$projectnamesessions.'.stb');
    unlink($db_path.$projectnameusers.'.stb');
   }
  open (SDB, ">>".$db_path.$projectnamedb.'.sdb')  || do {
    print $f_b."<B>Can't create database: $dbname<BR><BR>";
    print "Hint: Check write/read permissions of your default db directory($db_path)!<BR>More about permissions read in INSTALL.html</B>".$f_e;
    exit;
   };
  $db_path =~ s#/$##;	
  my $dbext = '.stb';
  my $rdelim = '\r\n';
  my $fdelim = '::';
  my $cryptedpswd = crypt($sql_pass, substr($sql_user,0,2));
  print SDB <<END_REC;
$db_path/*$dbext
$sql_user
$cryptedpswd
$fdelim
$rdelim
END_REC
  close SDB;
  my $admin_user = 'admin';
  my $admin_pass = $apass;
  my $dbh = webtools::sql_connect();
  if($dbh eq '')
   {
     print $f_b."<B>Sorry can't connect to database '$projectnamedb'!</B>".$f_e;
     exit;
   }
  my $tab = << "TERMI";
  $projectnamesessions (
        ID LONG,
        S_ID VARCHAR(255),
        IP VARCHAR(20),
        EXPIRE DATETIME,
        FLAG CHAR(1),
        DATA VARCHAR(1048576)
        )
TERMI
  my $dbi = '';
  eval 'webtools::sql_create_db($tab,$dbh);';
  if($@) {print "<B>$f_b Sorry can't create \'$projectnamesessions\' table!</B>$f_e";exit;}
  my $tab = << "TERMI";
  $projectnameusers (
        ID LONG,
        USER VARCHAR(50),
        PASSWORD VARCHAR(50),
        ACTIVE CHAR(1),
        DATA VARCHAR(1048576),
        CREATED DATETIME,
        FNAME VARCHAR(50),
        LNAME VARCHAR(50),
        EMAIL VARCHAR(120)
        )
TERMI
  eval 'webtools::sql_create_db($tab,$dbh);';
  if($@) {print "<B>$f_b Sorry can't create \'$projectnameusers\' table!</B>$f_e";exit;}
  $admin_pass = webtools::sql_quote($admin_pass,$dbh);
  webtools::sql_query("insert into $projectnameusers values(MAXVAL('ID|$projectnameusers'),'$admin_user',$admin_pass,'Y','',NOW(),'Admin','','');",$dbh);
  if(webtools::sql_errno($dbh))
    {
     print $f_b."<B>Can't create tables!<BR>";
     print "SQL error message: ".webtools::sql_errmsg($dbh)."<BR><BR>";
     print "Hint: Check write/read permissions of your default db directory($db_path)!<BR>More about permissions read in INSTALL.html</B>".$f_e;
     exit;
    }
 print << "END_OF_HTML";
 <B>$f_b
 <H3><U>WebTools Configure</U></H3>
 <table width="100%"><TR><TD width="100%" bgcolor="#D0D080">$f_b
 <B><center><A href="$scriptname?action=">main menu</A></center></B>$f_e
 </TD></TR></TABLE><BR>
 <B>&nbsp; Flat database in your db directory successfully created!<BR></B><BR>
 <BR>
 </B>$f_e
 <table width="100%"><TR><TD width="100%" bgcolor="#D0D080">$f_b
 <B><center><A href="$scriptname?action=">main menu</A></center></B>$f_e
 </TD></TR></TABLE>
END_OF_HTML
 }
 if($do eq 'ctable')
 {
  print "\n";   # Close HTTP header
  my $code = << 'END_TERM';
  use lib "$driver_path";
  use lib "./conf/";
  use lib './modules/';
  require './conf/config.pl';
  require 'db_flat.pl';
END_TERM
  eval $code;
  if($@ ne '') { print $f_b."<B>Sorry can't load needed libraries and modules (check in config.pl your WebTools directories!)</B>".$f_e; exit;}
  my $dbh;
  my $code = << 'END_TERM';
  $dbh = webtools::sql_connect();
  my $res = $dbh->do($sqlq);
  $dbh->commit();
END_TERM
  eval $code;
  if(($@ ne '') or ($sqlq eq '') or (webtools::sql_errno($dbh) ne '')) { print $f_b."<B>Sorry can't create table!<BR> Maybe your CREATE TABLE syntax is not correct or not supported from Flat DB ???</B>".$f_e; exit; }
  print << "END_OF_HTML";
 <B>$f_b
 <H3><U>WebTools Configure</U></H3>
 <table width="100%"><TR><TD width="100%" bgcolor="#D0D080">$f_b
 <B><center><A href="$scriptname?action=">main menu</A></center></B>$f_e
 </TD></TR></TABLE><BR>
 <B>&nbsp; Flat table successfully created!<BR></B><BR>
 <BR>
 </B>$f_e
 <table width="100%"><TR><TD width="100%" bgcolor="#D0D080">$f_b
 <B><center><A href="$scriptname?action=">main menu</A></center></B>$f_e
 </TD></TR></TABLE>
END_OF_HTML
 }
 if($do eq '')
 {
 print "\n";   # Close HTTP header
 print << "END_OF_HTML";
 <B>$f_b
 <H3><U>WebTools Configure</U></H3>
 <table width="100%"><TR><TD width="100%" bgcolor="#D0D080">$f_b
 <B><center><A href="$scriptname?action=database">database menu</A></center></B>$f_e
 </TD></TR></TABLE><BR>
 <b>You can create default database structure for Flat DB, using values from config.pl<BR>
 If your config.pl is not configured do it first <A href="$scriptname?action=config">here</A>!<BR><BR>
 Note: If database exists it will be removed and rebuilt!<BR><BR>
 Database structure will be created based on follow data:<BR><BR>
 DATABASE: <font color='#C05040'>$projectnamedb</font><BR>
 SESSIONS TABLE: <font color='#C05040'>$projectnamesessions</font><BR>
 USERS TABLE: <font color='#C05040'>$projectnameusers</font><BR>
 SQL USER: <font color='#C05040'>$sql_user</font><BR>
 SQL PASS: <font color='#C05040'>$sql_pass</font><BR></B>
 <form METHOD='POST' ACTION='$scriptname'>
 <input name='action' value='database' type='hidden'>
 <input name='type' value='flat' type='hidden'>
 <input name='do' value='create' type='hidden'>
 <input name='user_admin' value='$user_admin' type='hidden'>
 <input name='pass_admin' value='$pass_admin' type='hidden'>
 Enter password for default 'admin' user (for users support):<BR><BR>
 Password: <input name='apass' value='' type='password' onFocus="javascript: this.select();" onMouseOver="javascript: this.focus();"><BR><BR>
 <input value='Create' type='submit'>
 </form>
 <BR>
 If your database structure is already created you can create your own custom tables.<BR>
 Write below complete SQL query(create table statement):<BR>
 <form METHOD='POST' ACTION='$scriptname'>
 <input name='action' value='database' type='hidden'>
 <input name='type' value='flat' type='hidden'>
 <input name='do' value='ctable' type='hidden'>
 <input name='user_admin' value='$user_admin' type='hidden'>
 <input name='pass_admin' value='$pass_admin' type='hidden'>
 <textarea name='sqlq' cols='60' rows='12'></textarea><BR><BR>
 <input value='Create Table' type='submit'>
 </form>
Example:</B><BR><BR>
create table test (<BR>
&nbsp; &nbsp; ID LONG,<BR>
&nbsp; &nbsp; S_ID VARCHAR(45),<BR>
&nbsp; &nbsp; IP VARCHAR(20),<BR>
&nbsp; &nbsp; EXPIRE INT,<BR>
&nbsp; &nbsp; FLAG CHAR(1),<BR>
&nbsp; &nbsp; DATA VARCHAR(1048576)<BR>
&nbsp; &nbsp; )<BR><BR>
 </B>$f_e
 <table width="100%"><TR><TD width="100%" bgcolor="#D0D080">$f_b
 <B><center><A href="$scriptname?action=database">database menu</A></center></B>$f_e
 </TD></TR></TABLE>
END_OF_HTML
 }
}

sub ShowMysqlMain
{
 my $projectname = fetchValue('projectname',$conf_code);
 my $projectnamedb = $projectname.'db';
 my $projectnamesessions = $projectname.'_sessions';
 my $projectnameusers = $projectname.'_users';
 my $sql_user = fetchValue('sql_user',$conf_code);
 my $sql_pass = fetchValue('sql_pass',$conf_code);
 my $sql_host = fetchValue('sql_host',$conf_code);
 my $sql_port = fetchValue('sql_port',$conf_code);
 my $db_path = fetchValue('db_path',$conf_code);
 my $driver_path = fetchValue('driver_path',$conf_code);
 my $apass = $input->param('apass');
 my $sqlq = $input->param('sqlq');
 
 if($do eq 'create')
 {
  my $check_module_functions = fetchValue('check_module_functions',$conf_code);
  if($check_module_functions =~ m/^on$/si)
   {
    print "\n";
    print $f_b."<B>Sorry can't create database till WebTools is in debug mode!<BR>Please set debug mode in <A href='$scriptname?action=config'>config.pl</A> to 'off'</B>".$f_e; exit;
    exit;
   }
  my $code = << 'END_TERM';
  use lib "$driver_path";
  use lib "./conf/";
  use lib './modules/';
  
  use webtools;
  
  webtools::StartUpInit();
  
  webtools::load_database_driver('mysql');
  $webtools::db_support = 'db_mysql';
  
END_TERM
  eval $code;
  if($@ ne '') { print $f_b."<B>Sorry can't load needed libraries and modules (check in config.pl your WebTools directories!)</B>".$f_e; exit;}
  my $admin_user = 'admin';
  my $dbh;
  my $code = << 'TERMI';
  $dbh = Mysql->connect($sql_host.':'.$sql_port, undef, $sql_user, $sql_pass);
TERMI
  eval $code;
  if($@ ne '') { print $f_b."<B>Sorry can't connect to MySQL server! (check in config.pl your SQL settings!)</B>".$f_e; exit;}
  my $code = 'webtools::sql_drop_db($projectnamedb,$dbh);';
  eval $code;
  
  my $res;
  eval '$res = webtools::sql_create_db($projectnamedb,$dbh);';
  if($@) {print "<B>$f_b Sorry can't create database \'$projectnamedb\'!</B>$f_e";exit;}
  
  $dbh = webtools::sql_select_db($projectnamedb,$dbh);
  if($dbh eq '')
   {
     print $f_b."<B>Sorry can't connect to database '$projectnamedb'!</B>".$f_e;
     exit;
   }
  my $tab = << "TERMI";
create table $projectnamesessions (
        ID BIGINT(1) not null auto_increment primary key,
        S_ID VARCHAR(255) binary not null,
        IP VARCHAR(20) binary default 'xxx.xxx.xxx.xxx',
        EXPIRE DATETIME not null,
        FLAG char(1) binary default '0',
        DATA longblob
        )
TERMI
  webtools::sql_query($tab,$dbh);
  if(webtools::sql_errno($dbh) ne '') { print $f_b."<B>Sorry can't create system WebTools tables!</B>".$f_e; exit;}
  
  my $tab = << "TERMI";
create table $projectnameusers (
        ID INT(1) not null auto_increment primary key,
        USER VARCHAR(50) binary not null,
        PASSWORD VARCHAR(50) binary default '',
        ACTIVE CHAR(1),
        DATA longblob,
        CREATED DATETIME not null,
        FNAME VARCHAR(50),
        LNAME VARCHAR(50),
        EMAIL VARCHAR(120),
        unique(USER)
        )
TERMI
  webtools::sql_query($tab,$dbh);
  if(webtools::sql_errno($dbh) ne '') { print $f_b."<B>Sorry can't create system WebTools tables!</B>".$f_e; exit;}
  $apass = webtools::sql_quote($apass,$dbh);
  my $q = "insert into $projectnameusers values(NULL,'$admin_user',$apass,'Y','',NOW(),'Admin','','');";
  webtools::sql_query($q,$dbh);
  if(webtools::sql_errno($dbh) ne '') { print $f_b."<B>Sorry can't insert Admin user in database!</B>".$f_e; exit;}
  print << "END_OF_HTML";
 <B>$f_b
 <H3><U>WebTools Configure</U></H3>
 <table width="100%"><TR><TD width="100%" bgcolor="#D0D080">$f_b
 <B><center><A href="$scriptname?action=">main menu</A></center></B>$f_e
 </TD></TR></TABLE><BR>
 <B>&nbsp; Structure for MySQL successfully created!<BR></B><BR>
 <BR>
 </B>$f_e
 <table width="100%"><TR><TD width="100%" bgcolor="#D0D080">$f_b
 <B><center><A href="$scriptname?action=">main menu</A></center></B>$f_e
 </TD></TR></TABLE>
END_OF_HTML
 }
 if($do eq '')
 {
 print "\n";   # Close HTTP header
 print << "END_OF_HTML";
 <B>$f_b
 <H3><U>WebTools Configure</U></H3>
 <table width="100%"><TR><TD width="100%" bgcolor="#D0D080">$f_b
 <B><center><A href="$scriptname?action=database">database menu</A></center></B>$f_e
 </TD></TR></TABLE><BR>
 <b>You can create default database structure for MySQL, using values from config.pl<BR>
 If your config.pl is not configured do it first <A href="$scriptname?action=config">here</A>!<BR><BR>
 Note: If database exists it will be removed and rebuilt!<BR><BR>
 Database structure will be created based on follow data:<BR><BR>
 DATABASE: <font color='#C05040'>$projectnamedb</font><BR>
 SESSIONS TABLE: <font color='#C05040'>$projectnamesessions</font><BR>
 USERS TABLE: <font color='#C05040'>$projectnameusers</font><BR>
 SQL USER: <font color='#C05040'>$sql_user</font><BR>
 SQL PASS: <font color='#C05040'>$sql_pass</font><BR></B>
 <form METHOD='POST' ACTION='$scriptname'>
 <input name='action' value='database' type='hidden'>
 <input name='type' value='mysql' type='hidden'>
 <input name='do' value='create' type='hidden'>
 <input name='user_admin' value='$user_admin' type='hidden'>
 <input name='pass_admin' value='$pass_admin' type='hidden'>
 Enter password for default 'admin' user (for users support):<BR><BR>
 Password: <input name='apass' value='' type='password' onFocus="javascript: this.select();" onMouseOver="javascript: this.focus();"><BR><BR>
 <input value='Create' type='submit'>
 </form>
 <BR>
 If your database structure is already created you can create your own custom tables.<BR>
 Write below complete SQL query(create table statement):<BR>
 <form METHOD='POST' ACTION='$scriptname'>
 <input name='action' value='database' type='hidden'>
 <input name='type' value='mysql' type='hidden'>
 <input name='do' value='ctable' type='hidden'>
 <input name='user_admin' value='$user_admin' type='hidden'>
 <input name='pass_admin' value='$pass_admin' type='hidden'>
 <textarea name='sqlq' cols='60' rows='12'></textarea><BR><BR>
 <input value='Create Table' type='submit'>
 </form>
Example:</B><BR><BR>
create table test (<BR>
&nbsp; &nbsp; ID INT(1) not null auto_increment primary key,<BR>
&nbsp; &nbsp; USER VARCHAR(30) binary not null,<BR>
&nbsp; &nbsp; PASSWORD VARCHAR(30) binary default '',<BR>
&nbsp; &nbsp; DATA longblob,<BR>
&nbsp; &nbsp; unique(USER)<BR>
&nbsp; &nbsp; )<BR><BR>
 </B>$f_e
 <table width="100%"><TR><TD width="100%" bgcolor="#D0D080">$f_b
 <B><center><A href="$scriptname?action=database">database menu</A></center></B>$f_e
 </TD></TR></TABLE>
END_OF_HTML
}
if($do eq 'ctable')
 {
  print "\n";   # Close HTTP header
  my $code = << 'END_TERM';
  use lib "$driver_path";
  use lib "./conf/";
  use lib './modules/';
  require './conf/config.pl';
  require 'db_mysql.pl';
END_TERM
  eval $code;
  if($@ ne '') { print $f_b."<B>Sorry can't load needed libraries and modules (check in config.pl your WebTools directories!)</B>".$f_e; exit;}
  my $dbh;
  my $code = << 'END_TERM';
  $dbh = webtools::sql_connect();
  webtools::sql_query($sqlq,$dbh);
END_TERM
  eval $code;
  if(($@ ne '') or ($sqlq eq '') or (sql_errno($dbh) ne '')) { print $f_b."<B>Sorry can't create table!<BR> Maybe your CREATE TABLE syntax is not correct or not supported from MySQL ???</B>".$f_e; exit; }
  print << "END_OF_HTML";
 <B>$f_b
 <H3><U>WebTools Configure</U></H3>
 <table width="100%"><TR><TD width="100%" bgcolor="#D0D080">$f_b
 <B><center><A href="$scriptname?action=">main menu</A></center></B>$f_e
 </TD></TR></TABLE><BR>
 <B>&nbsp; MySQL table successfully created!<BR></B><BR>
 <BR>
 </B>$f_e
 <table width="100%"><TR><TD width="100%" bgcolor="#D0D080">$f_b
 <B><center><A href="$scriptname?action=">main menu</A></center></B>$f_e
 </TD></TR></TABLE>
END_OF_HTML
 }
}