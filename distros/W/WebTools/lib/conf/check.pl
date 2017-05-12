#####################################################
# Helper script checking functionallity of
# package and self configuration.
# (internally called by "config.pl")
#####################################################
# Copyright (c) 2001, Julian Lishev, Sofia 2001
# All rights reserved.
# This code is free software; you can redistribute
# it and/or modify it under the same terms 
# as Perl itself.
#####################################################

sub check_configuration
{
 if($ENV{'SCRIPT_NAME'} eq '') 
  {
   print STDOUT "\n  Test Mode\n\n";
   print STDOUT "Your variable ".'$webtools::check_module_functions'.
                " (in config.pl) is turned 'on'\n";
   print STDOUT "...force CHECKING mode\n";
   print STDOUT "(to turn off this check and script run normal, please set variable to 'off'!\n\n";
   print STDOUT "This is a WEB BASED check up program! It works only through WEB!\n";
   print STDOUT "Check script exit immediately! Use your favorit Browser!\n\n";
   print STDOUT "Syntax Ok";
   exit;
  }
 if ($webtools::check_module_functions eq 'on')   # Script now working only in debug mode!
  {
   # Eval code for speed! (this code will be compiled only if need)
   $eval_this_code = << 'EVAL_TERMINATOR';
   if(($ENV{'SCRIPT_NAME'} ne '') and !($ENV{'SCRIPT_NAME'} =~ m/\/install\.cgi$/si))
    {
     print STDOUT "Content-type: text/html\n\n";
    }
   print STDOUT '<font face="Verdana, Arial" size=2 color="#202070">';
   print STDOUT '<center><H3><p style="color:red">Test Mode</p></H3></center>';
   print STDOUT "<B>Your variable ".'<span style="color:red">$webtools::check_module_functions</span>'.
                " (<span style='color:red'>in config.pl</span>) is turned 'on'<BR>";
   print STDOUT "...force CHECKING mode<BR>";
   print STDOUT '<font face="Verdana, Arial" size=1>';
   print STDOUT "(to turn off this check and script run normal, please set variable to 'off'!</font><BR><BR>";
   print STDOUT "<HR><U><span style='color:red'>Checking your paths</span></U>:<BR><BR>";
   
   print STDOUT "<LI>Driver path";

   if(-e $webtools::driver_path) { print STDOUT "...ok"; }
   else {ErrorMessage("...<span style='background:red'>NOT EXISTS...</span><BR>");}
   
   print STDOUT "<LI>Library path";
   if(-e $webtools::library_path) { print STDOUT "...ok"; }
   else {ErrorMessage("...<span style='background:red'>NOT EXISTS...</span><BR>");}
   
   print STDOUT "<LI>DataBase path";
   if(-e $webtools::db_path) { print STDOUT "...ok"; }
   else {ErrorMessage("...<span style='background:red'>NOT EXISTS...</span><BR>");}
   
   print STDOUT "<LI> Mail path";
   my $result = DirectoryRights($webtools::mailsender_path,3); # Read/Write
   if($result eq 'ok') { print STDOUT "...ok"; }
     else {ErrorMessage("...<span style='background:red'>".$result."...</span><BR>");}
      
   print STDOUT "<LI> Xreader path";
   if(-e $webtools::xreader_path) { print STDOUT "...ok"; }
   else {ErrorMessage("...<span style='background:red'>NOT EXISTS...</span><BR>");}
   
   print STDOUT "<LI> Perl/HTML path";
   if(-e $webtools::perl_html_dir) { print STDOUT "...ok"; }
   else {ErrorMessage("...<span style='background:red'>NOT EXISTS...</span><BR>");}
   
   print STDOUT "<LI> Web server htdocs (root) path";
   if(-e $webtools::apacheshtdocs) { print STDOUT "...ok"; }
   else {ErrorMessage("...<span style='background:red'>NOT EXISTS...</span><BR>");}
   
   print STDOUT "<LI> Temp path";  # Read/Write
   my $result = DirectoryRights($webtools::tmp,3);
   if($result eq 'ok') { print STDOUT "...ok"; }
     else {ErrorMessage("...<span style='background:red'>".$result."...</span><BR>");}

   print STDOUT "<HR><U><span style='color:red'>Checking your external programs</span></U>:<BR><BR>";
      
   my $sys_mailing = 0;
   
   print STDOUT "<LI> sendmail";
   my $sys_res_open =  (-e $webtools::sendmail) ? 1:0;
   if($sys_res_open) { print STDOUT "...ok"; $sys_mailing |= 1;}
   else {print STDOUT "...<font color='#C02020'>not available</font>";}
   
   print STDOUT "<LI> host";
   my $sys_res_open =  (-e '/usr/bin/host') ? 1:0;
   if($sys_res_open) { print STDOUT "...ok"; $sys_mailing |= 2;}
   else {print STDOUT "...<font color='#C02020'>not available</font>";}
   
   print STDOUT "<LI> nslookup";
   my $sys_res_open = `nslookup 127.0.0.1`;
   if($sys_res_open) { print STDOUT "...ok"; $sys_mailing |= 4;}
   else {print STDOUT "...<font color='#C02020'>not available</font>";}

   if($sys_mailing == 0)
    {
     print '<BR><BR><font color="#C02020">Sorry but you can`t send emails through standart way! (Either sendmail and host/nslookup are not available for WebTools).</font><BR>';
     print '<BR>Hint1: <font color="#C02020">Set full path for sendmail program in config.pl ($webtools::sendmail variable) and then use send_mail() function available in mail.pl</font>';
     print '<BR>Hint2: <font color="green">Rely on our build-in DNS lookup you can use mail() function available in mail.pl</font><BR>';
    }
   elsif($sys_mailing == 1)
    {
     print '<BR><BR><font color="#C02020">"host" and "nslookup" are not available for WebTools, so you can send emails only via sendmail program!</font><BR>';
     print '<BR>Hint: <font color="#C02020">Use send_mail() function available in mail.pl</font><BR>';
    }
   elsif($sys_mailing == 4)
    {
     print '<BR><BR><font color="#C02020">"sendmail" and "host" programs are not available for WebTools! <BR>If you want to use our build-in mail client you must relay on nslookup program!</font><BR>';
     print '<font color="#C02020">This case is typical for Windows systems!</font><BR>';
     print '<BR>Hint: <font color="#C02020">Use mail() function available in mail.pl</font><BR>';
    }
   elsif(($sys_mailing != 0) and !($sys_mailing & 1))
    {
     print '<BR><BR><font color="#C02020">"sendmail" is not available for WebTools, so if you want to use our build-in mail client you must relay on host/nslookup</font><BR>';
     print '<BR>Hint: <font color="#C02020">Use mail() function available in mail.pl</font><BR>';
     print '<BR>Note: <font color="#C02020">Check whether $webtools::sendmail variable (in config.pl) is set to correct full path of sendmail program!</font><BR>';
    }
    if(($sys_mailing != 7) and ($sys_mailing != 0))
     {
      print '<BR>Note: Critical errors are not found in mail section!<BR>';
     }
   
   print STDOUT "<HR><U><span style='color:red'>Info</span></U>:<BR><BR>";
   
   print STDOUT "<LI> Name of project:";
   print STDOUT " $webtools::projectname";
   
   print STDOUT "<LI> Name of db driver:";
   if($webtools::db_support eq 'db_mysql' or $webtools::db_support eq 'db_access' or $webtools::db_support eq 'db_excel' or $webtools::db_support eq 'db_flat')
    {
     print STDOUT " $webtools::db_support";
    }
   else
    {
     print STDOUT " $webtools::db_support (that is not standart db driver...please check it!)";
    }
      
   print STDOUT "<LI> Name of database:";
   print STDOUT " $webtools::sql_database_sessions";
   
   print STDOUT "<LI> Session time is:";
   print STDOUT " $webtools::sess_time $webtools::sys_conf_d";
   
   print STDOUT "<LI> Session cookie expiration:";
   if($webtools::sess_cookie eq 'sesstime')
    {
     print STDOUT " when session expire! (same as session time)";
    }
   else
    {
     print STDOUT " when browser is closed! (Browser side)";    
    }
   
   print STDOUT "<LI> Name of session ID:";
   print STDOUT " $webtools::l_sid";
   
   print STDOUT "<LI> Cookie/Get/Post priority:";
   if($webtools::cpg_priority eq 'cookie')
    {
     print STDOUT " cookie has higher priority";
    }
   else
    {
     print STDOUT " get/post has higher priority";
    }
   
   print STDOUT "<LI> Session support:";
   print STDOUT "  authomatic choice via cookies/get/post";

   print STDOUT "<LI> Force flat files with sessions:";
   if($webtools::sess_force_flat eq 'on')
    {
     print STDOUT "  ON (store session's data in flat files)";
    }
   else
    {
     print STDOUT " OFF (store session's data in database)";
    }

   print STDOUT "<LI> Maximum size of data via POST method:";
   print STDOUT " $webtools::cgi_lib_maxdata bytes";   
   
   print STDOUT "<LI> Multipart support...";
   if($webtools::cgi_lib_forbid_mulipart eq 'off')
    {
     print STDOUT " on";
    }
   else
    {
     print STDOUT " off (multipart spam protected)";
    }
   
   print STDOUT "<LI> Restrict sessions by IP...";
   if($webtools::ip_restrict_mode =~ m/^on$/is)
    {
     print STDOUT " on";
    }
   else
    {
     print STDOUT " off";
    }
   
   print STDOUT "<LI> Restrict script execution by IP...";
   if($webtools::run_restrict_mode =~ m/^on$/is)
    {
     print STDOUT " on";
    }
   else
    {
     print STDOUT " off";
    }
   
   print STDOUT "<LI> Printing mode...";
   if($webtools::var_printing_mode =~ m/^buffered$/is)
    {
     print STDOUT " buffered";
    }
   else
    {
     print STDOUT " non buffered";
    }
   
   print STDOUT "<LI> Searching row: ";
   my $trow;
   foreach $trow (@webtools::treat_htmls_ext)
    {
     print $trow."&nbsp;&nbsp;";
    }
   
   print STDOUT "<LI> Debugging mode is";
   print STDOUT "...$webtools::debugging";

   print STDOUT '</B></font><BR>';
   
EVAL_TERMINATOR

   eval $eval_this_code;
   exit;
  }
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
 $f = $path.'check_pl_file_'.rand()*1000;
 open(FILE,'>'.$f) or return(0);
 print (FILE 'TEST') or return(0);
 close(FILE);
 unlink($f);
 return(1);
}

sub ErrorMessage
 {
    print STDOUT shift(@_);
    print STDOUT "<BLOCKQUOTE>Please check your package and config.pl (this) file!</BLOCKQUOTE><BR>";
 }

1;