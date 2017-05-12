package webtools;
####################################################
# Perl`s WEB module
####################################################
###########################################
# BEGIN Section start here
###########################################
BEGIN {
use vars qw($VERSION $INTERNALVERSION @ISA @EXPORT);
    $VERSION = "1.27";
    $INTERNALVERSION = "1";
    @ISA = qw(Exporter);
    @EXPORT = 
     qw(
        %sess_cookies %SESREG %SESREG_TYPES $sys_cookie_accepted 
        session_start session_destroy session_register 
        $session_started session_clear_expired session_id 
        read_scalar read_array read_hash register_var unregister_var exists_var 
        session_id_adder href_sid_adder action_sid_adder 
        new_session session_expire_update update_var 
        session_set_id_name session_id_name session_ip_restrict 
        session_expiration session_cookie_path 
        convert_ses_time GetCurrentSID 
        
        GetCookies SetCookies  SetCookieExpDate SetCookiePath SetCookieDomain SetSecureCookie 
        GetCompressedCookies SetCompressedCookies delete_cookie write_cookie read_cookie 
        $cookie_path_cgi $cookie_domain_cgi $cookie_exp_date_cgi $secure_cookie_cgi 
        
        SignUpUser SignInUser 
        
        sql_query sql_fetchrow sql_affected_rows sql_inserted_id hideerror sql_select_db 
        sql_num_rows sql_quote sql_connect sql_disconnect $sql_host $sql_user test_connect 
        sql_data_seek sql_errmsg sql_errno load_database_driver $sql_pass $sql_database_sessions 
        $sql_sessions_table DB_OnDestroy DB_OnExit $system_database_handle 
        
        Header read_form read_form_array read_var href_adder action_adder 
        attach_var detach_var 
        encode_separator decode_separator 
        StartUpInit RunScript set_script_timeout flush_print set_printing_mode DestroyScript 
        ClearBuffer ClearHeader Load_and_Parse_script $print_header_buffer $print_flush_buffer 
        r_str rand_srand b_print Parse_Form exists_insensetive set_ignore_termination 
        get_ignore_termination global_variables_dump_style $sys_ignore_term 
        *SESSIONSTDOUT $reg_buffer $global_variables_dump set_variables_dump 
        $sentcontent $apacheshtdocs %SIGNALS $loaded_functions 
        $sys_OS $sys_CRLF $sys_EBCDIC $sys_config_pl_loaded 
       );

 require Exporter;
 
 use Errors::Errors;
 $Errors::Errors::sys_ERROR = Errors::Errors->new(); # Create one global error object
 
 use globexport;
 use stdouthandle;

 #################################
 # PLEASE DO NOT MODIFY ANYTHING!
 # Please see file config.pl !!!
 #################################
 $| = 1;                               # Flush imediatly!   
 $webtools::sentcontent = 0;           # Show whether Send_Content() where called!
 $webtools::session_started = 0;       # Show whether session_start were started!
 %webtools::attached_vars = ();        # The variables that we will store
 $webtools::reg_buffer = '';           # Contain register session file!
 %webtools::SESREG = ();
 %webtools::SESREG_TYPES = ();
 %webtools::SESREG_VAR = ();
 $webtools::print_flush_buffer = '';
 $webtools::print_header_buffer = '';
 $webtools::new_session_were_started = 0; # Default we are in old session!
 $webtools::sess_header_flushed = 0;      # Header Is not still flushed!
 $webtools::cookie_path_cgi = '/';
 $webtools::secure_cookie_cgi = '0';
 %webtools::SIGNALS = ();
 $webtools::flag_onFlush_Event = 0;
 $webtools::syspre_process_counter = 0;
 $webtools::sys_cookie_accepted = 0;
 $webtools::sys_header_warnings = 0;
 $webtools::sys_ignore_term = 1;
 $webtools::sys__subs__ = {};
 
 tie(*SESSIONSTDOUT,'stdouthandle');
 select(SESSIONSTDOUT);

 ################################################################
 # Needed definitions
 ################################################################
 my $sys_local_sess_id = ''; # This is current session ID!!!
 @webtools::l_charset = ('085wOxVz1S','lZXa6M9RTk','FbHQvcjdmP','dQPpgALNqE','YDJ7CNG3yi',
               'mzk5l2F0xs','ThQPjd2OfR','G3YJK7IeWC','b4Zmol8SuM','jd9XvcHQa6',
               'sjyiDd21rB','RThpFALgNq');
 ################################################################
 my $sys_w_id = $ENV{HTTP_COOKIE} || $ENV{COOKIE};
  my @cookies = split(/;/s,$sys_w_id);
  my $l;
  foreach $l (@cookies)
   {
    if($l ne '') 
      {
       my ($n,$v) = split(/=/s,$l);
       $n =~ s/ //sg;
       if (!exists($webtools::sess_cookies{$n}))
         {
          $webtools::sess_cookies{$n} = $v;
          }
      }
   }

###########################################        
  $webtools::system_database_handle = undef;   # That is current opened DB Handler!
  $webtools::system_database_handle_flat   = undef;
  $webtools::system_database_handle_mysql  = undef;
  $webtools::system_database_handle_access = undef;
  $webtools::usystem_database_handle_flat   = undef;
  $webtools::usystem_database_handle_mysql  = undef;
  $webtools::usystem_database_handle_access = undef;
  
}

sub AUTOLOAD
{
 my $name = $webtools::AUTOLOAD;
 $name =~ s/.*://;   # Strip fully-qualified portion
 unless (exists $webtools::sys__subs__->{$name})
   {
    print "<font face='Verdana' size='2'><B>Error: Can't access function '$name' in ".__PACKAGE__." module!</B></font>";
    exit;
   }
my $ref = $webtools::sys__subs__->{$name};
&$ref(@_);
}

###########################################
# Functions start here
###########################################
sub PathMaker 
 {
  my $pth = (-e $_[0]) ? $_[0] : $_[1];
  if($pth ne '')
  {
    eval ("use lib \'$pth\';"); return($pth);
  }
 }
###########################################
# On start up makes some profit things :-)
###########################################
sub StartUpInit
{
 $Errors::Errors::sys_ERROR->install('onterm',\&On_Term_Event);
 my $add = PathMaker('./modules/additionals','./additionals');
 $webtools::loaded_functions = 0;
 $webtools::global_variables_dump = 0;
 $webtools::global_variables_dump_style = 'layer';
 if(!($webtools::loaded_functions & 128)){require "$library_path"."utl.pl";}
 require "$library_path"."cookie.pl";
 ###################################################################
 require $driver_path.'sess_flat.pl';  # Must be placed before any require on db drivers!
 #####################################################################
 #  ###   ###     ###   ####   #####  #   #  #####  ####             #
 #  #  #  #  #    #  #  #   #    #    #   #  #      #   #            #
 #  #  #  ####    #  #  ####     #    #   #  #####  ####             #
 #  #  #  #  #    #  #  #  #     #     # #   #      #  #             #
 #  ###   ###     ###   #  ##  #####    #    #####  #  ##            #
 #####################################################################
 if($db_support eq 'db_mysql') { require $driver_path.'db_mysql.pl'; $webtools::loaded_functions = $webtools::loaded_functions | 1;}
 if($db_support eq 'db_access') { require $driver_path.'db_access.pl'; $webtools::loaded_functions = $webtools::loaded_functions | 2;}
 if($db_support eq 'db_flat') { require $driver_path.'db_flat.pl'; $webtools::loaded_functions = $webtools::loaded_functions | 4;}
 # TODO: more lines and more db engines
}
##########################################
# When process.cgi exit...
##########################################
sub DestroyScript
{
 my $sys_destroy_db_code = 'if($webtools::db_support ne "") {DB_OnExit($webtools::system_database_handle);}';
 eval $sys_destroy_db_code;
 if($webtools::global_variables_dump and ($webtools::debugging =~ m/^on$/sig)) {printDump($webtools::global_variables_dump_style);}
 $Errors::Errors::sys_ERROR->exit('');
 1;
}
####################################################################
# High level functions...
####################################################################
sub session_start
{
 my ($dbh,$newv) = @_;
 session_clear_expired($dbh); # Clear all expired sessions!
 my $sid = Get_Old_SID($dbh); # Try to find old session ID!
 if ($newv)
  {
   local $sys_local_sess_id = $sid;
   session_destroy($dbh);     # Remove previous session if user resubmit login form!
   $sid = '';
  }
 $sys_local_sess_id = $sid;
 
 my $sid_time;
 if ($sid eq '')              # Old sessions present?
   {
    $new_session_were_started = 1;
    $sid_time = time();       # Get current time (in ticks)
    $sid_time -= 286521037;   # Try to hide what we doing :-)
    $sid_time = convert_ses_time($sid_time,9);
    rand_srand();             # Reset random generator
    $sid = $sid_time.r_str($charset,$rand_sid_length);  # Create SID string!
    $sys_local_sess_id = $sid;
    if (!insert_sessions_row ($dbh)) { return (0); }
   }
 else
   {   
     $new_session_were_started = 0;
     if(open_session_file($dbh))
       {
        $reg_buffer = load_session_data($dbh);
        if($reg_buffer eq undef) {$reg_buffer = '';}
        save_session_data($reg_buffer,$dbh);            # Here is a place where we automaticly transffer reged data!
        close_session_file($dbh);
       }
     else { return (0); }
     load_registred_vars($reg_buffer);
   }  
 $session_started = 1;
 my $sess = $sess_cookies{$l_sid};
 if($sess eq $sys_local_sess_id) {$sys_cookie_accepted = 1;}
 else {$sys_cookie_accepted = 0;}
 return($sid);          # Return new(old) SID!
}
sub session_register
{
  my ($buffer,$dbh) = @_;
  if (!$session_started)
     {
      if(!session_start($dbh))
        {
         return(0);
        }
     }
  if(open_session_file($dbh))
    {
      my $r = save_session_data($buffer,$dbh);
      close_session_file($dbh);
      if(!$r){ return(0); }
    }
  else { return(0); }
  return(1);
}
sub session_destroy
{
  my ($dbh) = @_;
  if($sys_local_sess_id eq '') {$sys_local_sess_id = Get_Old_SID($dbh);}
  if($sys_cookie_accepted) # If browser accepts cookies...
   {
    delete_cookie($l_sid);   # That send empty cookie to broser...and browser delete it!
   }
  if(open_session_file($dbh))
    {
      $session_started = 0;
      my $rez = delete_sessions_row($dbh);
      $sys_local_sess_id = '';
      return($rez);
    }
  else { $sys_local_sess_id = ''; return(0); }
}
sub session_id
{
  return($sys_local_sess_id);
}
sub session_set_id_name
{
  $l_sid = shift(@_);
}
sub session_ip_restrict
{
  my ($rmd) = shift(@_);
  if($sess_force_flat eq 'off') ###DB###
  {
  if($rmd or ($rmd =~ m/^on$/i)) { $ip_restrict_mode = 'on'; }
  else { $ip_restrict_mode = 'off'; }
  }
  else
  {
   ###FLAT###
   $ip_restrict_mode = 'off';
  }
}
sub set_script_timeout
{
  $cgi_script_timeout = shift(@_);
  SetCGIScript_Timeout();
}	
sub session_id_name
{
  return($l_sid);
}
sub new_session
{
 return($new_session_were_started);
}
sub session_id_adder   # Add SID ident to all links and forms in source!
{
 my ($source) = @_;
 my $sid = $sys_local_sess_id;
 my $src = href_sid_adder($source,$sid);
 return(action_sid_adder($src,$sid));
}
sub attach_var 
  {
    my ($name,$value) = @_;
    $attached_vars{$name} = $value;
    return (1);
  }
sub detach_var 
  {
    my ($name) = @_;

    if ( exists $attached_vars{$name} )
      {
      	delete $attached_vars{$name};
      }
    if ( exists $sess_cookies{$name} ) { delete_cookie($name); }
    return (1); 	
  }

sub session_expiration
{
  return($sesstimead);
}
sub session_cookie_path
{
  return($cookie_path_cgi);
}

sub register_var
{
  my ($type,$name,@val) = @_;
  my $sp;
  my $reg_buffer = '';
  if ($type eq 'scalar')
    {
     $sp = $uni_sep.'<scalar>:'.$name.':';
     ($val) = @val;
     $reg_buffer = $sp.encode_separator($val,$uni_esc,$uni_gr_sep,$uni_sep);
    }
  if ($type eq 'array')
    {
     $sp = $uni_sep.'<array>:'.$name.':';
     $reg_buffer = $sp;
     my $size = $#val+1;
     $reg_buffer .= "$size".":";
     foreach $scl (@val)
        { 
         $reg_buffer .= $uni_sep."<scalar_a>:".encode_separator($scl,$uni_esc,$uni_gr_sep,$uni_sep);
        }
    }
  if ($type eq 'hash')
    {
     my $h = $val[0];
     my %val = ();
     my $res = ref($h);
     if ($res eq 'HASH'){%val = %$h; @val = %val;}
     else { %val = @val;}
     $sp = $uni_sep.'<hash>:'.$name.':';
     $reg_buffer = $sp;
     my $size = int((scalar @val) / 2);
     $reg_buffer .= "$size".":";
     my $key;
     foreach $key (keys %val)
       { 
        $reg_buffer .= $uni_sep."<scalar_h>:".encode_separator($key,$uni_esc,$uni_gr_sep,$uni_sep).":".encode_separator($val{$key},$uni_esc,$uni_gr_sep,$uni_sep);
       }
    }    	
  return($reg_buffer);
}
sub unregister_var
{
 my ($name,$buffer) = @_;
 
 my $sp = $uni_sep_t;
 if($buffer =~ s/$sp\<scalar\>\:$name\:(.*?)$sp/$uni_sep/s)
   {
     return($buffer);    
   }
 elsif($buffer =~ s/$sp\<scalar\>\:$name\:(.*)//s)
       {
         return($buffer);
       }
 $sp = $uni_sep_t.'(<array>:|<hash>:)'.$name.':';
 my $ps = $uni_sep_t.'<scalar>:';
 my $ps1 = $uni_sep.'<scalar>:';
 my $pa = $uni_sep_t.'<array>:';
 my $pa1 = $uni_sep.'<array>:';
 my $ph = $uni_sep_t.'<hash>:';
 my $ph1 = $uni_sep.'<hash>:';
 if(!($buffer =~ s/$sp(\d{1,})\:(.*?)$ps/$ps1/s))
   {
    if(!($buffer =~ s/$sp(\d{1,})\:(.*?)$pa/$pa1/s))
      {
      	if(!($buffer =~ s/$sp(\d{1,})\:(.*?)$ph/$ph1/s))
          {
           $buffer =~ s/$sp(\d{1,})\:(.*)//s;
          }
      }
   }
 return($buffer);  
}
sub update_var  # Set new value for (not)exists variable (rigistrated)!
{
 my ($type,$name,$buffer,@val) = @_;
 $buffer = unregister_var($name,$buffer);
 $buffer .= register_var($type,$name,@val);
 return($buffer);
}
sub exists_var  # Check wether given var exists!
{
 my ($type,$name,$buffer) = @_;
 if($buffer =~ m/$uni_sep_t\<$type\>\:$name\:/s) {return (1);}
 return(0);
}
sub read_scalar   # Read one scalar from DB (registrated only)
{
  my ($name) = @_;
  return ($SESREG{$name});
}
sub read_array   # Read one array from DB (registrated only)
{
  my ($name) = @_;
  my  $ptr = $SESREG{$name};
  my  @a = @$ptr;
  return(@a);
}
sub read_hash   # Read one hash from DB (registrated only)
{
  my ($name) = @_;
  my  $ptr = $SESREG{$name};
  my  %h = %$ptr;
  return(%h);
}
sub read_form   # Read one scalar from form (browser)
{
  my ($name) = @_;
  if($parsedform) { return ($formdatah{$name}); }
}
sub read_form_array  # Read one scalar from form (browser) but via normal array.
{
  my ($numb) = @_;
  my $kv = $formdataa[$numb];
  my $null = "\0";
  my $kv = m/^(.*?)$null(.*)$/s;
  my @res = ($1,$2);
  return ($res);
}
sub read_var  # Read one scalar from broser (via cookie or just via link/form... - no matter :-)))
{
 my ($name) = @_;
 my $pg = $formdatah{$name};
 my $c = $sess_cookies{$name};
 if(!(exists($formdatah{$name}))) { $pg = '';}
 if(!(exists($sess_cookies{$name}))) {$c = '';}
 my $r;
 if($cpg_priority =~ m/^cookie$/si)
   {
     $r = $pg;
     if (exists($sess_cookies{$name})) { return($c); }
     return($r);
   }
  else
   {
     $r = $c;
     if (exists($formdatah{$name})) { return($pg); }
     return($r);
   }
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

sub set_printing_mode
{
 my ($flag) = shift(@_);
 my $old = $webtools::var_printing_mode;
 if ($flag eq 'buffered')
   {
    $webtools::var_printing_mode = 'buffered';
   }
 else {
 	if($old eq 'buffered')
 	 {
 	  flush_print();
 	 }
 	$webtools::var_printing_mode = '';
       }
 return($old);
}

sub flush_print     # Flush all data (header and body), coz they are never had been printed!
{
 my ($clear) = @_;
 if($clear == 1) { $sess_header_flushed = 1; return;}
 my $oldslcthnd = CORE::select(STDOUT);           # Select real output handler
 $i = 0;
 if ($flag_onFlush_Event == 0)
 {
  $flag_onFlush_Event = 1;
  if(exists($webtools::SIGNALS{'OnFlush'}))
     {
       eval {
      	     my $OnEvent_code = $webtools::SIGNALS{'OnFlush'};
      	     &$OnEvent_code;
       	    };
       $flag_onFlush_Event = 0;
      }
 }
 if(!$sess_header_flushed)      # If Header was not flushed...
 {
  $| = 1;
  if(!$is and !($sys_stdouthandle_header and $sys_stdouthandle_content_ok))
   {
    $print_header_buffer = "X-Powered-By: WebTools/1.27\n".$print_header_buffer; # Print version of this tool.
   }
  if ((!$sys_cookie_accepted) and ($sys_local_sess_id ne ''))
   {
    if($sess_cookie ne 'sesstime')
      {
       if(new_session()){
         write_cookie($l_sid,$sys_local_sess_id,'',$cookie_path_cgi);
        }
      }
     else
      {
       if(new_session()){
        write_cookie($l_sid,$sys_local_sess_id,$sesstimead,$cookie_path_cgi);
       }
      }
    $print_flush_buffer = session_id_adder($print_flush_buffer);
   }
  if (scalar(%attached_vars)) # Add attached variables to get/post/cookie
       { 
         while ( my ($name,$value) = each( %attached_vars) )
           {      
            if(!(exists $sess_cookies{$name}) or ($sess_cookies{$name} ne $value))
              {
               write_cookie($name,$value);
               $print_flush_buffer = href_adder($print_flush_buffer,$name,$value);
               $print_flush_buffer = action_adder($print_flush_buffer,$name,$value);
              }
           }
       }
  if((!($print_header_buffer =~ m/Content\-type\:(.+)/is)) and (!($print_header_buffer =~ m/Status:( *?)204/is)))
   {
    if(!$is and !($sys_stdouthandle_header and $sys_stdouthandle_content_ok))
     {
      Header(type=>'content');  # Well we forgot to send content-type
     }
   }
  my $sys_print_res;
  my $sys_data;

  while($sys_data = substr($print_header_buffer,0,2048))
    {
      substr($print_header_buffer,0,2048,'');
      $sys_print_res = print ($sys_data);
      if($sys_print_res eq undef) {onExit();exit;}
    }
    
  $sys_print_res = print ("\n");
  if($sys_print_res eq undef) {onExit();exit;}
  
  $print_header_buffer = '';
  $sess_header_flushed = 1;
 }
 #print $print_flush_buffer;  # Just Print It!
 my $sys_data = '';
 while($sys_data = substr($print_flush_buffer,0,2048))
    {
      substr($print_flush_buffer,0,2048,'');
      my $sys_print_res = print ($sys_data);
      if($sys_print_res eq undef) {onExit();exit;}
    }
 $print_flush_buffer = '';
 if($webtools::sys_header_warnings > 0)
  {
   CORE::print('<BR><font face="Verdana, Arial, Helvetica, sans-serif" size="2">'."\n<BR>");
   CORE::print("<B>Warnings Note: <font color='red'>WebTools is unable to use sessions/cookies till 'non-buffered' print mode is forced ");
   CORE::print("or any headers are sent after body!\n<BR></font></B></font><BR>");
  }
 select($oldslcthnd);
}
sub ClearBuffer
{
 $print_flush_buffer = '';
}
sub ClearHeader
{
 $print_header_buffer = '';
 $sess_header_flushed = 0;
 $sentcontent = 0;
}
sub GetCurrentSID
{
 return(Get_Old_SID(shift(@_)));
}
########################################################################
# Low level function...
########################################################################
sub Get_Old_SID
{
 my ($dbh) = @_;
 my $sid;
 my $ip = $ENV{'REMOTE_ADDR'}; # Get remote IP address
 if (read_var($l_sid) ne undef)
   {
    $sid = read_var($l_sid);
    if (!check_sid($sid))
      {
        $sid = '';
      }
    else
     {
      if($sess_force_flat eq 'off') ###DB###
      {
       my $r_q = '';
       if($ip_restrict_mode =~ m/^on$/i)
        {
         $r_q = " and IP = \'$ip\'";    # Restrict session on IP!
        }
       my $q = "select S_ID from $sql_sessions_table where S_ID = \'$sid\'".$r_q;
       my $res = sql_query($q,$dbh);
       if ($res ne undef)
        {
         ($my_sid) = sql_fetchrow($res);
         if($my_sid eq $sid) { return($sid); }
         return('');
        }
       else { delete_cookie($l_sid); return(''); }
      }
      else
      {
       ###FLAT###
       my $res = find_SF_File($tmp,$sid);
       if ($res ne '')
        {
         return($sid);
        }
       else { delete_cookie($l_sid); return(''); }
      }
     }  
   }
 else { $sid = ''; }
 return($sid);
}
sub r_char
{
 my ($s) = @_;
 $l = length($s);
 $p = rand($l-1);
 return(substr($s,$p,1));
}
sub r_str
{
 my ($cs,$l) = @_;
 my $rs = "";
 for($i=0;$i<$l;$i++)
  {
   $rs .= r_char($cs);
  }
 return($rs);  
}
sub rand_srand()
{
 srand();
}
sub check_sid
{
 my ($sid) = @_;
 if($sid =~ m/^[0-9A-Za-z]*$/i)
  {
   return(1);
  }
 else { return(0);}
}
sub Header
{
  my %arg = @_;
  my $type = $arg{'type'};
  my $val = $arg{'val'};
  local $oldstd;
  
  my $is = $webtools::var_printing_mode eq 'buffered' ? 1 : 0;
  if(!$is)
   {
     if($stdouthandle::sys_stdouthandle_header or $stdouthandle::sys_stdouthandle_print_text)
      {
       local $oldHand = select(STDOUT);
       CORE::print('<BR><font face="Verdana, Arial, Helvetica, sans-serif" size="2">'."<B>Warning:</B>\n<BR>");
       CORE::print("You are in non-buffered print mode and header is already sent!\n</font><BR>");
       CORE::print("<B>Hint: <font color='red'>Send header before body (or force 'buffered' print mode)!</font></B><BR>");
       CORE::print("<B>Raw data:</B>");
       select($oldHand);
       $webtools::sys_header_warnings ++;
      }
     if(!$stdouthandle::sys_stdouthandle_header and !$stdouthandle::sys_stdouthandle_print_text)
      {
      	if(($type =~ m/Content/si) or ($type =~ m/Location/si) or ($type =~ m/Status/si) or
      	   ($val =~ m/Content\-type\:/si) or ($val =~ m/Location\:/si) or ($val =~ m/Status\:/si))
          {
           $stdouthandle::sys_stdouthandle_content_ok = 1;
          }
        else {$stdouthandle::sys_stdouthandle_content_ok = 0;}
       }
   }
  if(!$is) {$oldstd = select(STDOUT);}
  if (exists($arg{'type'}))
    {
      if ($type =~ m/content/is)
        {
         if(!$sentcontent)
          {
           $sentcontent = 1;
           if($is) {$print_header_buffer .= "Content-type: ";}
           else { CORE::print "Content-type: ";}
           if (exists($arg{'val'}))
             {
             if($is) {$print_header_buffer .= $val."\n";}
             else { CORE::print $val."\n";}
             }
           else
             {
              if($is) {$print_header_buffer .= "text/html\n";}
              else { CORE::print "text/html\n";}
             }
          }
        }
      if ($type =~ m/cookie/is)
        {
         $print_header_buffer .= "Set-Cookie: ";
         if (exists($arg{'val'}))
           {
	     if (!($val =~ m/(;| )path ?=.*$/is))
              {
              	if($is) {$print_header_buffer .= $val."; path=$cookie_path_cgi\n";}
                else { CORE::print $val."; path=$cookie_path_cgi\n";}
              }
             else
              {
               if($is) {$print_header_buffer .= $val."\n"; }
               else { CORE::print $val."\n"; }
              }
           }
         else 
           {
            if($is) {$print_header_buffer .= "\n";}
            else { CORE::print "\n"; }
           }
        }
      if ($type =~ m/raw/is)
        {
         if (exists($arg{'val'}))
           {
            if($is) {$print_header_buffer .= $val;}
            else { CORE::print $val; }
           }
        }
      if ($type =~ m/modified/is)
        {
         $print_header_buffer .= "Last-modified: ";
         if (exists($arg{'val'}))
           {
             my $expi = expires($val);
             if($is) {$print_header_buffer .= $expi."\n";}
             else { CORE::print $expi."\n";}
           }
         else {
               my $expi = expires('-1m');
               if($is) {$print_header_buffer .= $expi."\n";}
               else { CORE::print $expi."\n";}
              }
        }
      if ($type =~ m/MIME/is)
        {
         if($is) {$print_header_buffer .= "MIME-version: ";}
         else { CORE::print "MIME-version: ";}
         if (exists($arg{'val'}))
           {
             if($is) {$print_header_buffer .= $val."\n";}
             else { CORE::print $val."\n";}
           }
         else 
           {
            if($is) {$print_header_buffer .= "1.0\n";}
            else { CORE::print "1.0\n";}
           }
        }
      if ($type =~ m/window/is)
        {
         if($is) {$print_header_buffer .= "Window-target: ";}
         else { CORE::print "Window-target: ";}
         if (exists($arg{'val'}))
           {
             if($is) {$print_header_buffer .= $val."\n";}
             else { CORE::print $val."\n";}
           }
         else {
                if($is) {$print_header_buffer .= "\n";}
                else { CORE::print "\n";}
              }
        }
      if ($type =~ m/Pragma/is)
        {
         if($is) {$print_header_buffer .= "Pragma: ";}
         else { CORE::print "Pragma: ";}
         if (exists($arg{'val'}))
           {
             if($is) {$print_header_buffer .= $val."\n";}
             else { CORE::print $val."\n";}
           }
         else { 
         	if($is) {$print_header_buffer .= "no-cache\n";}
         	else { CORE::print "no-cache\n";}
              }
        }
      if ($type =~ m/Expires/is)
        {
         if($is) {$print_header_buffer .= "Expires: ";}
         else { CORE::print "Expires: ";}
         if (exists($arg{'val'}))
           {
             my $expi = expires($val);
             if($is) {$print_header_buffer .= $expi."\n";}
             else { CORE::print $expi."\n";}
           }
         else {
         	my $expi = expires('-1m');
                if($is) {$print_header_buffer .= $expi."\n";}
                else { CORE::print $expi."\n";}
              }
        }
      if ($type =~ m/Referrer/is)
        {
         if($is) {$print_header_buffer .= "Referrer: ";}
         else { CORE::print "Referrer: ";}
         if (exists($arg{'val'}))
           {
             if($is) {$print_header_buffer .= $val."\n";}
             else { CORE::print $val."\n";}
           }
         else {
         	if($is) {$print_header_buffer .= "\n";}
         	else { CORE::print "\n";}
               }
        }
    }
  if(!$is) {select($oldstd);}
  return(1);
}
sub href_sid_adder
{
 my ($source,$sid) = @_;
 my ($name,$value) = ($l_sid,$sid);
 my $url;
 my $src = $source;
 my $match = $source;
    $source = '';
 my $after,$before,this;
 if($session_started)
 {
  if(!($src =~ s! *href *?= *?(\'|\")?(.*?)(\'|\"|\>\ )?!do{
    $match =~ m/( *href *?= *?)(\'|\"|)(.*?)(\'|\"|\ |\>)/is;
    $url = $3;   #Matched string
    $before = $`;
    $after = $';
    $this = $&;
    if($url =~ m/.*?\.(cgi|pl).*/is)
     {
      if ($url =~ s/(.*?\?.*)/$1\&$name\=$value/is)
        {
        }
      else
        {
         $url =~ s/(.*)/$1\?$name\=$value/is;
        }
     }
      $this =~ s/( *?href *?= *?)(\'|\"|)(.*?)(\'|\"| |>)/$1$2$url$4/is;
    
      $source .= $before.$this;
      $match = $after;
   };!isge)) { return($src); } 
   $source .= $after;
 }
 else { return($src); } 
   return($source); 
} 
sub href_adder
{
 my ($source,$name,$value) = @_;
 my $url;
 my $src = $source;
 my $match = $source;
    $source = '';
 my $after,$before,this;
 
  if(!($src =~ s! *href *?= *?(\'|\")?(.*?)(\'|\"|\>\ )?!do{
    $match =~ m/( *href *?= *?)(\'|\"|)(.*?)(\'|\"|\ |\>)/is;
    $url = $3;   #Matched string
    $before = $`;
    $after = $';
    $this = $&;
    if($url =~ m/.*?\.(cgi|pl).*/is)
     {
      if ($url =~ s/(.*?\?.*)/$1\&$name\=$value/is){}
      else
        {
         $url =~ s/(.*)/$1\?$name\=$value/is;
        }
     }
      $this =~ s/( *?href *?= *?)(\'|\"|)(.*?)(\'|\"| |>)/$1$2$url$4/is;
    
      $source .= $before.$this;
      $match = $after;
   };!isge)) { return($src); } 
   $source .= $after;
 
 
   return($source); 
}
sub action_sid_adder
{
 my ($source,$sid) = @_;
 my ($name,$value) = ($l_sid,$sid);
 my $url;
 my $src = $source;
 my $match = $source;
    $source = '';
 my $after,$before,this,$cntr;
 $cntr = 0;
 if($session_started)
 {
    $src =~ s!\ +action *?= *?(\'|\")?(.*?)(\'|\")?!do{
    $match =~ m/\ +(action *?= *?)(\'|\"|)(.*?)(\'|\"|\ |\>)/is;
    $url = $3;   #Matched string
    $before = $`;
    $after = $';
    $this = $&;
    $cntr++;
    if ($url =~ s/(.*?\?.*)/$1\&$name\=$value/is){}
    else
      {
       $url =~ s/(.*)/$1\?$name\=$value/is;
      }
    
    $this =~ s/(\ +action *?= *?)(\'|\"|)(.*?)(\'|\"|\ |\>)/$1$2$url$4/is;
    
    $source .= $before.$this;
    $match = $after;
   };!isge;
   $source .= $after;
   if($cntr == 0) { return ($src); }
 }
 else { return($src); }   
   return($source);
}
sub action_adder
{
 my ($source,$name,$value) = @_;
 my $url;
 my $src = $source;
 my $match = $source;
    $source = '';
 my $after,$before,this;
 my $cntr = 0;
 
    $src =~ s!\ +action *?= *?(\'|\")?(.*?)(\'|\")?!do{
    $match =~ m/\ +(action *?= *?)(\'|\"|)(.*?)(\'|\"|\ |\>)/is;
    $url = $3;   #Matched string
    $before = $`;
    $after = $';
    $this = $&;
    $cntr++;
    if ($url =~ s/(.*?\?.*)/$1\&$name\=$value/is)
      {
      }
    else
      {
       $url =~ s/(.*)/$1\?$name\=$value/is;
      }
    
    $this =~ s/(\ +action *?= *?)(\'|\"|)(.*?)(\'|\"|\ |\>)/$1$2$url$4/is;
    
    $source .= $before.$this;
    $match = $after;
   };!isge;
   $source .= $after;
   if($cntr == 0) { return ($src); }
    
   return($source);
}
sub delete_sessions_row
{
  my ($dbh) = @_;
  my $sid = $sys_local_sess_id;
  my $ip = $ENV{'REMOTE_ADDR'}; # Get remote IP address
  my $r_q = '';
  if($sess_force_flat eq 'off') ###DB###
  {
   if($ip_restrict_mode =~ m/^on$/i)
    {
     $r_q = " and IP = \'$ip\'";    # Restrict session on IP!
    }
   my $res = sql_query("delete from $sql_sessions_table where S_ID = \'$sid\'".$r_q,$dbh);
   if ($res ne undef)
     {
      return(1);
     }
  }
 else
  {
   ###FLAT###
   return(destroy_SF_File($tmp,$sid));
  }
 return(0);
}
sub open_session_file
{
  my ($dbh) = @_;
  my $sid = $sys_local_sess_id;
  my $ip = $ENV{'REMOTE_ADDR'}; # Get remote IP address
  my $r_q = '';
  if($ip_restrict_mode =~ m/^on$/i)
   {
    $r_q = " and IP = \'$ip\'";    # Restrict session on IP!
   }
  my $q = "update $sql_sessions_table set FLAG = \'1\' where S_ID = \'$sid\' and FLAG = \'0\'".$r_q;
  my $c = $wait_for_open / $wait_attempt; 
  my $i;
  for ($i=0;$i<$wait_attempt;$i++)
    {
     my $re;
     if($sess_force_flat eq 'off') ###DB###
      {
       $re = sql_query($q,$dbh);
       if($re ne undef) {return(1);}
      }
     else
      {
       ###FLAT###
       $re = osetflag_SF_File($tmp,$sid);
       if($re == -1) {$re = undef;}
       else {return(1);} # File can be opened!
      }
     select(undef,undef,undef,$c);
    }
  onLockedFileErrorEvent();
  return(0);   # Sorry, at this moment file can`t be opened!
}
sub close_session_file 
{
  my ($dbh) = @_;
  my $sid = $sys_local_sess_id;
  my $ip = $ENV{'REMOTE_ADDR'}; # Get remote IP address
  my $r_q = '';
  if($ip_restrict_mode =~ m/^on$/i)
   {
    $r_q = " and IP = \'$ip\'";    # Restrict session on IP!
   }
  my $q = "update $sql_sessions_table set FLAG = \'0\' where S_ID = \'$sid\'".$r_q;

  if($sess_force_flat eq 'off') ###DBD###
   {
    if (sql_query($q,$dbh) ne undef) { return(1); }
    return(0);
   }
  else
  {
   ###FLAT###
   $re = csetflag_SF_File($tmp,$sid);
   return(1);
  }
}

sub load_registred_vars
{
  my ($buffer) = @_;
  my $c = 0,$i = 0;
  my $a_name,$s_name,$h_name,$val;
  my @a_data = ();
  my @h_data = ();
  my @pars = split(/$uni_sep_t/s,$buffer);
  foreach $line (@pars)
   { 
    if ($c == 0)
     {
      if ($line =~ m/\<array\>\:(.*?)\:(\d{1,})\:(.*)/s)
        {
         $c = $2;
         $a_name = $1;
         $val = '';
         @a_data = ();
        }
      if ($line =~ m/\<hash\>\:(.*?)\:(\d{1,})\:(.*)/s)
        {
         $c = $2;
         $h_name = $1;
         $val = '';
         @h_data = ();
        }
      if ($line =~ m/\<scalar\>\:(.*?)\:(.*)/s)
        {
         $s_name = $1;
         $val = $2;
         make_scalar_from($s_name,decode_separator($val,$uni_esc,$uni_gr_sep,$uni_sep));
        }
     }
    else
     {
       if ($line =~ m/\<scalar_a\>\:(.*)/s)
         {
          my $scl = decode_separator($1,$uni_esc,$uni_gr_sep,$uni_sep);
          push (@a_data,$scl);
          $c --;
          if (!$c) { make_array_from($a_name,@a_data); }
         }
       if ($line =~ m/\<scalar_h\>\:(.*?)\:(.*)/s)
         {
          my $n = $1;
          my $v = $2;
          my $n = decode_separator($n,$uni_esc,$uni_gr_sep,$uni_sep);
          my $v = decode_separator($v,$uni_esc,$uni_gr_sep,$uni_sep);
          push (@h_data,$n);push (@h_data,$v);
          $c --;
          if (!$c) { make_hash_from($h_name,@h_data); }
         }
     } 
   }
}
sub make_scalar_from
{
 my ($s_name,$val) = @_;
 $SESREG{$s_name} = $val;
 $SESREG_TYPES{$s_name} = 's';
}
sub make_array_from
{
 my ($a_name,@a_data) = @_;
 $SESREG{$a_name} = \@a_data;
 $SESREG_TYPES{$a_name} = 'a';
}
sub make_hash_from
{
 my ($h_name,%h_data) = @_;
 $SESREG{$h_name} = \%h_data;
 $SESREG_TYPES{$h_name} = 'h';
}
sub save_session_data   # ($session_ID,$buffer,$database_handler) // Save into DB DATA field
{
 my ($buffer,$dbh) = @_;
 my $sid = $sys_local_sess_id;
 my $ip = $ENV{'REMOTE_ADDR'}; # Get remote IP address
 my $r_q = '';
 if($sess_force_flat eq 'off') ###DB###
 {
  if($ip_restrict_mode =~ m/^on$/i)
    {
     $r_q = " and IP = \'$ip\'";    # Restrict session on IP!
    }
  my $buf = sql_quote($buffer,$dbh);
   
  my $q = "update $sql_sessions_table set DATA = $buf where S_ID = \'$sid\'".$r_q;
  if (sql_query($q,$dbh) ne undef) { return(1); }
 }
 else
 {
  ###FLAT###
  write_SF_File($tmp,$sid,$buffer);
  return(1);
 }
 return(0);
}
sub load_session_data   # ($session_ID,$database_handler) // Load DATA from table
{
 my ($dbh) = @_;
 my $sid = $sys_local_sess_id;
 my $ip = $ENV{'REMOTE_ADDR'}; # Get remote IP address
 my $r_q = '';
 my @arr = ();
 if($sess_force_flat eq 'off') ###DB###
 {
  if($ip_restrict_mode =~ m/^on$/i)
    {
     $r_q = " and IP = \'$ip\'";    # Restrict session on IP!
    }
  my $q = "select DATA from $sql_sessions_table where S_ID = \'$sid\'".$r_q;
  my $res = sql_query($q,$dbh);
  if ($res eq undef) { return(undef); }
  @arr = sql_fetchrow($res);
 }
 else
 {
  ###FLAT###
  return(read_SF_File($tmp,$sid));
 }
 return($arr[0]);     # Return DATA field
}
sub read_redirected_script_file
{
 my $p_file_name_N00 = '';
 my $sys_pre_load_redirected_file = '';
 
 if(exists($ENV{'PATH_TRANSLATED'}))
   {
    my $rurl = $ENV{'PATH_TRANSLATED'};
    if(($rurl ne '') && (-e $rurl))
     {
      local * REDIRECTEDFILE;
      if(open(REDIRECTEDFILE, $rurl))
       {
       	if(binmode (REDIRECTEDFILE))
       	 {
       	  my $cnt = read(REDIRECTEDFILE,$sys_pre_load_redirected_file,-s REDIRECTEDFILE);
       	  if($cnt)
       	   {
       	    close (REDIRECTEDFILE);
       	    $sys_pre_load_redirected_file =~ s/\r\n/\n/sg;
       	    if(!($sys_pre_load_redirected_file =~ m/\n$/s)) {$sys_pre_load_redirected_file .= "\n";}
       	    ###################################
       	    # Parse Reditected File
       	    ###################################
       	    my $sys_value = '';
       	    my $sys_key   = '';
       	    
       	    if($sys_pre_load_redirected_file =~ m/\$REDIRECT\_OPTIONS\ {0,}\{(\'|\")?file(\'|\")?\}\ {0,}\=\ {0,}(\'|\")?([^\'\"\;\n]{1,})(\'|\")?\;{0,}\n/si)
       	     {
       	      $sys_value = $4;
       	      if($sys_value ne '') {$p_file_name_N001 = $sys_value;}
       	     }
     	    else
       	     {
       	      my $rurlZ = $rurl;
       	      $rurlZ =~ s/\\/\//sg;
       	      if($rurlZ =~ m/(.*)\/(.*)$/s)
       	        {
       	         $p_file_name_N001 = $2;
       	        }
       	     }
       	    if($sys_pre_load_redirected_file =~ m/\$REDIRECT\_OPTIONS\ {0,}\{(\'|\")?home(\'|\")?\}\ {0,}\=\ {0,}(\'|\")?([^\'\"\;\n]{1,})(\'|\")?\;{0,}\n/si)
       	     {
       	      $sys_value = $4;
       	      if($sys_value ne '') { chdir $sys_value; }
       	     }
       	   }
       	  else {close (REDIRECTEDFILE);}
       	 }
       	else {close (REDIRECTEDFILE);}
       }
     }
   }
 return($p_file_name_N001);
}
sub RunScript
{
 my $sys_loaded_src = 0;
 my $p_file_name_N001 = read_form('file');
 if($p_file_name_N001 eq '') { $p_file_name_N001 = read_redirected_script_file(); }
 $p_file_name_N001 =~ m/^(.*?)\./si;
 my $sys_RS_p_file_name = $1;
 if($globexport::sys_script_cached_source eq '')
 {
 if(($perl_html_dir eq '') or ($perl_html_dir =~ m/^(\\|\/)$/si))
   {
    print "<BR><h3><B><font color='red'>Security hole!!!</font> Your default script direcotry (htmls) is leaved empty or<BR>";
    print " it is pointed to your ROOT directory! <BR>";
    print "Script abort immediately!</h3></B>";
    die ':QUIT:';
   }
 $p_file_name_N001 = read_form('file');
 if($p_file_name_N001 eq '') { $p_file_name_N001 = read_redirected_script_file(); }
 $p_file_checked_done_N001 = 0;
 if ($p_file_name_N001 =~ m/^[A-Za-z0-9-_.\/]*$/is)
   {
    if (!($p_file_name_N001 =~ m/\.\./i) and (!($p_file_name_N001 =~ m/\.\//i))) {
       if (($p_file_name_N001 =~ m/\.html$/i) or ($p_file_name_N001 =~ m/\.htm$/i) or ($p_file_name_N001 =~ m/\.cgi$/i) or
           ($p_file_name_N001 =~ m/\.whtml$/i) or ($p_file_name_N001 =~ m/\.cgihtml$/i))
         {
          $p_file_name_N001 =~ m/^(.*)\.(.*)$/i;
          my $body = $1;
          my $ext = $2;
          my $exname;
          if($treat_htmls_ext[0] ne '')
           {
            if(!(-e $perl_html_dir.$p_file_name_N001))
             {
              foreach $exname (@treat_htmls_ext)
               {
                if(-e $perl_html_dir.$body.'.'.$exname)
                 {
                  $p_file_name_N001 = $body.'.'.$exname;
                  last;
                 }
                else
                 {
               	  if($exname =~ m/^$ext$/i) {last;}
                 }
              }
             }
           }
          $p_file_checked_done_N001 = 1;
         }      
       }
   }
 if ($p_file_checked_done_N001)   
  {
    if(!open(FILE_H_OPEN_N001,$perl_html_dir.$p_file_name_N001))
      {
       Header(type => 'content');
       $print_flush_buffer = '';
       flush_print();
       print "<br><font color='red'><h2>Error: Incorrect request($perl_html_dir$p_file_name_N001)!</h2></font>";
       onExit('withOutDB');
       exit;
      }
    binmode(FILE_H_OPEN_N001);
    read(FILE_H_OPEN_N001,$p_file_buf_N001,(-s FILE_H_OPEN_N001));
    close (FILE_H_OPEN_N001);
    $sys_loaded_src = 1;
    $globexport::sys_script_cached_source = $p_file_buf_N001;
   }
  }
 else
  {
   $sys_loaded_src = 1;
   $p_file_buf_N001 = $globexport::sys_script_cached_source;
  }
 if($sys_loaded_src)
  {
   @globexport::sys_pre_defined_vars = ();
   $globexport::sys_script_cached_source =~ s/\n[\ \t]{1,}(\<\!\-\-\#onActivate\>)(.*?)(\<\/\#onActivate\-\-\>)/\n$1$2$3/sig;
   $globexport::sys_script_cached_source =~ s/(\<\!\-\-\#onActivate\>)(.*?)(\<\/\#onActivate\-\-\>)[\ \t]{1,}/$1$2$3/sig;
   $globexport::sys_script_cached_source =~ s/(\r\n|\n)(\<\!\-\-\#onActivate\>)(.*?)(\<\/\#onActivate\-\-\>)/$2$3$4/sig;
   $globexport::sys_script_cached_source =~ s/(\<\!\-\-\#onActivate\>)(.*?)(\<\/\#onActivate\-\-\>)(\r\n|\n)/$1$2$3/sig;
   my $sys_bkp = $globexport::sys_script_cached_source;
   $sys_bkp =~ s/(\<\!\-\-\#onActivate\>)(.*?)(\<\/\#onActivate\-\-\>)/do{
     push(@sys_pre_defined_vars,$2);
    };/sgioe;
   # Clear tags
   $globexport::sys_script_cached_source =~ s/(\<\!\-\-\#onActivate\>)(.*?)(\<\/\#onActivate\-\-\>)//sig;
   $p_file_buf_N001 = $globexport::sys_script_cached_source;
   my $sys_str;
   # WARNNING: Follow iterative loop change configuration variables (in this script)!
   foreach $sys_str (@globexport::sys_pre_defined_vars)
    {
      # Parse confing constants
      $sys_str =~ s/\#(.*?)(\r\n|\n)/$2/sgi;
      eval $sys_str;
      my $codeerr = $@;
      if($@ ne '')
       {
        Header(type => 'content');
        $print_flush_buffer = '';
        flush_print();
        print "<br><font color='red'><h3>Perl Subsystem: Syntax error in Activate section of <font color='blue'>$p_file_name_N001</font> !</h3>";
        $codeerr =~ s/\r\n/\n/sg;
        $codeerr =~ s/\n/<BR>/sgi;
        my $res = $webtools::debugging eq 'on' ? "<br>$codeerr</font>" : "";
        print $res;
        onExit('withOutDB');
        exit;
       }
    }
   StartUpInit();
   $p_file_buf_N001 =~ s/\<\!\-\- PERL:(.*?)(\<\?perl.*?\?\>.*?)\/\/\-\-\>(\r\n|\n)?/$2/gsio;
   $p_file_buf_N001 =~ s/\<\!\-\- PERL:(.*?)\/\/\-\-\>(\r\n|\n)?//gsio;
   $p_file_buf_N001 = pre_process_templates($p_file_buf_N001);  # Process all build-in templates
   
   # Remove all the COMMENTS!!! That will reduce perl computing and printing!                
   ExecuteHTMLfile($p_file_name_N001,$p_file_buf_N001);
   onExit();
   if(exists($webtools::SIGNALS{'OnExit'}))
     {
      eval {
      	    my $OnExit_code = $webtools::SIGNALS{'OnExit'};
      	    &$OnExit_code;
      	   };
     }
  }
 else
  {
   Header(type => 'content');
   $print_flush_buffer = '';
   flush_print();
   print "<br><font color='red'><h2>Error: Invalid file request!</h2></font>";
   onExit('withOutDB');
   exit;
  }
}
sub ExecuteHTMLfile
{
 my ($f_name,$sys_p_buf_N001) = @_;
 my @h_N001 = ();
 my @html_N001 = split(/\<\?perl/is,$sys_p_buf_N001);
 my $sys_a_N001;
 my $error_locator_N001 = 1;
 my $sys_all_code_in_one = "\n";
 foreach $sys_l_N001 (@html_N001)
  {
   $sys_l_N001 =~ s/(.*)\?\>(\r\n|\n)?//is;
   push(@h_N001,$sys_l_N001);
  }
 my @code_N001 = ();
 $sys_p_buf_N001 =~ s/\<\?perl *(.*?)\?\>/do{
  $sys_a_N001 = $1;
  if ($sys_a_N001 ne '') { push(@code_N001,$sys_a_N001); }
 };/isge;
 my $i_N001 = 0;
 foreach $sys_l_N001 (@h_N001)
  {
    chomp($sys_l_N001);
    if($sys_l_N001 ne '')
      {
       $sys_l_N001 =~ s/\|/\\\|/sgo;
       my $sys_cpy_l_N001 = $sys_l_N001;
       $sys_cpy_l_N001 =~ s!\\\\\|!do{
           $sys_l_N001 =~ s%\\\\\|%\\\\\\\\\\\|%so;
         };!sgeo;
       $sys_all_code_in_one .= 'if ($var_printing_mode eq "buffered"){$print_flush_buffer .= q|'.$sys_l_N001.'|;} else {print q|'.$sys_l_N001.'|;}'."\n";
      }
    my $cd_N001 = $code_N001[$i_N001]; $i_N001++;
    $sys_all_code_in_one .= $cd_N001;
  }
 $sys_all_code_in_one .= "\n".'$error_locator_N001 = 0;';
 SetCGIScript_Timeout();
 eval $sys_all_code_in_one;
 my $cd = $@;
 my $codeerr = $cd;
 if($error_locator_N001)
   {
    onExit();
    if($cd =~ m/\:QUIT\:(.*)/i) 
      {
       if(exists($webtools::SIGNALS{'OnError'}))
         {
          eval {
      	        my $OnEvent_code = $webtools::SIGNALS{'OnError'};
      	        &$OnEvent_code($1);
      	       };
         }
       return;
      }
    if($cd =~ m/\:EXIT\:(.*)/i) 
      {
       return;
      }
    Header(type => 'content');
    $print_flush_buffer = '';
    flush_print();
    print "<br><font color='red'><h3>Perl Subsystem: Syntax error in code(<font color='blue'>$f_name</font>)!</h3>";
    $codeerr =~ s/\r\n/\n/sg;
    $codeerr =~ s/\n/<BR>/sgi;
    my $res = $debugging eq 'on' ? "<br>$codeerr</font>" : "";
    print $res;
    exit;
   }
}
sub b_print # Only for backware compatibility!
{
  my ($p) = @_;
  $print_flush_buffer .= $p;
}

###########################################
# Cookies
###########################################
sub read_cookie   # Read one scalar from cookie
{
 my ($name) = @_;
 return($sess_cookies{$name});
}
sub write_cookie
{
 my ($name,$value,$expires,$path,$domain) = @_;
 SetCookieExpDate($expires) if($expires ne '');
 SetCookiePath($path) if($path ne '');
 SetCookieDomain($domain) if($domain ne '');
 my $cuky = SetCookies($name,$value);
 Header(type=>'raw',val=>$cuky);
 return(1);
}
sub delete_cookie
{
 my ($name) = @_;
 my $expires = '-1d';
 SetCookieExpDate($expires);
 my $cuky = SetCookies($name,'');
 Header(type=>'raw',val=>$cuky); # Expires data is -1 minute!
 return(1);
}

########################################################
sub Default_CGI_Script_ALARM_SUB
 {
  my $obj    = shift;
  my $what   = shift;
  if(exists($webtools::SIGNALS{'OnTimeOut'}))
     {
      eval {
      	    my $OnEvent_code = $webtools::SIGNALS{'OnTimeOut'};
      	    &$OnEvent_code;
      	   };
     }
  else
   {
    ClearHeader();
    ClearBuffer(); 
    Header(type=>'content');
    print "<center><B>Error: Script timeout (liftime of script run out)!</B></center>\n";
   }
  CORE::exit;
 }
sub SetCGIScript_Timeout
{
 if((defined($cgi_script_timeout)) and ($cgi_script_timeout != 0) and ($cgi_script_timeout > 1))
  {
   $Errors::Errors::sys_ERROR->install('onTimeout',\&Default_CGI_Script_ALARM_SUB);
my $script_time_eval = << "TIME_EVAL_TERMINATOR";
   alarm($cgi_script_timeout);
TIME_EVAL_TERMINATOR
   eval $script_time_eval;
  }
}

sub save_database_handlers
{
 my $current = $webtools::db_support;
 if($current =~ m/^db_mysql$/si)
    {
     $webtools::system_database_handle_mysql  = $webtools::system_database_handle;
    }
  if($current =~ m/^db_flat$/si)
    {
     $webtools::system_database_handle_flat  = $webtools::system_database_handle;
    }
  if($current =~ m/^db_access$/si)
    {
     $webtools::system_database_handle_access  = $webtools::system_database_handle;
    }
   $webtools::system_database_handle = undef;
}
##########################################################################
# Load (reload) database driver
# PROTO: load_database_driver($driver);
# where: $driver can be: 'mysql','flat','access', 'sess_flat' and 'none'
##########################################################################
sub load_database_driver
{
 my $new_driver = shift;
 
 my $current = $webtools::db_support;
 
 if($new_driver =~ m/^flat$/si)
  {
   &save_database_handlers();
   if($webtools::system_database_handle_flat ne undef)
    {
     $webtools::system_database_handle = $webtools::system_database_handle_flat;
    }
   if(!($webtools::loaded_functions & 4))
    {
     require $driver_path.'db_flat.pl';
     $webtools::loaded_functions = $webtools::loaded_functions | 4;
    }
   else
    {
     $webtools::sys__subs__->{'DB_OnExit'} = \&flat_DB_OnExit;
     $webtools::sys__subs__->{'hideerror'} = \&flat_hideerror;
     $webtools::sys__subs__->{'sql_connect'} = \&flat_sql_connect;
     $webtools::sys__subs__->{'sql_connect2'} = \&flat_sql_connect2;
     $webtools::sys__subs__->{'test_connect'} = \&flat_test_connect;
     $webtools::sys__subs__->{'sql_disconnect'} = \&flat_sql_disconnect;
     $webtools::sys__subs__->{'sql_query'} = \&flat_sql_query;
     $webtools::sys__subs__->{'sql_fetchrow'} = \&flat_sql_fetchrow;
     $webtools::sys__subs__->{'sql_affected_rows'} = \&flat_sql_affected_rows;
     $webtools::sys__subs__->{'sql_inserted_id'} = \&flat_sql_inserted_id;
     $webtools::sys__subs__->{'sql_create_db'} = \&flat_sql_create_db;
     $webtools::sys__subs__->{'sql_drop_db'} = \&flat_sql_drop_db;
     $webtools::sys__subs__->{'sql_select_db'} = \&flat_sql_select_db;
     $webtools::sys__subs__->{'sql_num_fields'} = \&flat_sql_num_fields;
     $webtools::sys__subs__->{'sql_num_rows'} = \&flat_sql_num_rows;
     $webtools::sys__subs__->{'sql_data_seek'} = \&flat_sql_data_seek;
     $webtools::sys__subs__->{'sql_errmsg'} = \&flat_sql_errmsg;
     $webtools::sys__subs__->{'sql_errno'} = \&flat_sql_errno;
     $webtools::sys__subs__->{'sql_quote'} = \&flat_sql_quote;
     $webtools::sys__subs__->{'unsupported_types'} = \&flat_sql_unsupported_types;
     $webtools::sys__subs__->{'session_clear_expired'} = \&flat_session_clear_expired;
     $webtools::sys__subs__->{'session_expire_update'} = \&flat_session_expire_update;
     $webtools::sys__subs__->{'insert_sessions_row'} = \&flat_insert_sessions_row;
     $webtools::sys__subs__->{'DB_OnDestroy'} = \&flat_DB_OnDestroy;
     $webtools::sys__subs__->{'SignUpUser'} = \&flat_SignUpUser;
     $webtools::sys__subs__->{'SignInUser'} = \&flat_SignInUser;
    }
  }
 if($new_driver =~ m/^mysql$/si)
  {
   &save_database_handlers();
   if($webtools::system_database_handle_mysql ne undef)
    {
     $webtools::system_database_handle = $webtools::system_database_handle_mysql;
    }
   if(!($webtools::loaded_functions & 1))
    {
     require $driver_path.'db_mysql.pl';
     $webtools::loaded_functions = $webtools::loaded_functions | 1;
    }
   else
    {
     $webtools::sys__subs__->{'DB_OnExit'} = \&mysql_DB_OnExit;
     $webtools::sys__subs__->{'hideerror'} = \&mysql_hideerror;
     $webtools::sys__subs__->{'sql_connect'} = \&mysql_sql_connect;
     $webtools::sys__subs__->{'test_connect'} = \&mysql_test_connect;
     $webtools::sys__subs__->{'sql_disconnect'} = \&mysql_sql_disconnect;
     $webtools::sys__subs__->{'sql_query'} = \&mysql_sql_query;
     $webtools::sys__subs__->{'sql_fetchrow'} = \&mysql_sql_fetchrow;
     $webtools::sys__subs__->{'sql_affected_rows'} = \&mysql_sql_affected_rows;
     $webtools::sys__subs__->{'sql_inserted_id'} = \&mysql_sql_inserted_id;
     $webtools::sys__subs__->{'sql_create_db'} = \&mysql_sql_create_db;
     $webtools::sys__subs__->{'sql_drop_db'} = \&mysql_sql_drop_db;
     $webtools::sys__subs__->{'sql_select_db'} = \&mysql_sql_select_db;
     $webtools::sys__subs__->{'sql_num_fields'} = \&mysql_sql_num_fields;
     $webtools::sys__subs__->{'sql_num_rows'} = \&mysql_sql_num_rows;
     $webtools::sys__subs__->{'sql_data_seek'} = \&mysql_sql_data_seek;
     $webtools::sys__subs__->{'sql_errmsg'} = \&mysql_sql_errmsg;
     $webtools::sys__subs__->{'sql_errno'} = \&mysql_sql_errno;
     $webtools::sys__subs__->{'sql_quote'} = \&mysql_sql_quote;
     $webtools::sys__subs__->{'unsupported_types'} = \&mysql_sql_unsupported_types;
     $webtools::sys__subs__->{'session_clear_expired'} = \&mysql_session_clear_expired;
     $webtools::sys__subs__->{'session_expire_update'} = \&mysql_session_expire_update;
     $webtools::sys__subs__->{'insert_sessions_row'} = \&mysql_insert_sessions_row;
     $webtools::sys__subs__->{'DB_OnDestroy'} = \&mysql_DB_OnDestroy;
     $webtools::sys__subs__->{'SignUpUser'} = \&mysql_SignUpUser;
     $webtools::sys__subs__->{'SignInUser'} = \&mysql_SignInUser;
    }
  }
 if($new_driver =~ m/^access$/si)
  {
   &save_database_handlers();
   if($webtools::system_database_handle_access ne undef)
    {
     $webtools::system_database_handle = $webtools::system_database_handle_access;
    }
   if(!($webtools::loaded_functions & 2))
    {
     require $driver_path.'db_access.pl';
     $webtools::loaded_functions = $webtools::loaded_functions | 2;
    }
   else
    {
     $webtools::sys__subs__->{'DB_OnExit'} = \&access_DB_OnExit;
     $webtools::sys__subs__->{'hideerror'} = \&access_hideerror;
     $webtools::sys__subs__->{'sql_connect'} = \&access_sql_connect;
     $webtools::sys__subs__->{'sql_connect2'} = \&access_sql_connect2;
     $webtools::sys__subs__->{'test_connect'} = \&access_test_connect;
     $webtools::sys__subs__->{'sql_disconnect'} = \&access_sql_disconnect;
     $webtools::sys__subs__->{'sql_query'} = \&access_sql_query;
     $webtools::sys__subs__->{'sql_fetchrow'} = \&access_sql_fetchrow;
     $webtools::sys__subs__->{'sql_affected_rows'} = \&access_sql_affected_rows;
     $webtools::sys__subs__->{'sql_inserted_id'} = \&access_sql_inserted_id;
     $webtools::sys__subs__->{'sql_create_db'} = \&access_sql_create_db;
     $webtools::sys__subs__->{'sql_drop_db'} = \&access_sql_drop_db;
     $webtools::sys__subs__->{'sql_select_db'} = \&access_sql_select_db;
     $webtools::sys__subs__->{'sql_num_fields'} = \&access_sql_num_fields;
     $webtools::sys__subs__->{'sql_num_rows'} = \&access_sql_num_rows;
     $webtools::sys__subs__->{'sql_data_seek'} = \&access_sql_data_seek;
     $webtools::sys__subs__->{'sql_errmsg'} = \&access_sql_errmsg;
     $webtools::sys__subs__->{'sql_errno'} = \&access_sql_errno;
     $webtools::sys__subs__->{'sql_quote'} = \&access_sql_quote;
     $webtools::sys__subs__->{'unsupported_types'} = \&access_sql_unsupported_types;
     $webtools::sys__subs__->{'session_clear_expired'} = \&access_session_clear_expired;
     $webtools::sys__subs__->{'session_expire_update'} = \&access_session_expire_update;
     $webtools::sys__subs__->{'insert_sessions_row'} = \&access_insert_sessions_row;
     $webtools::sys__subs__->{'DB_OnDestroy'} = \&access_DB_OnDestroy;
     $webtools::sys__subs__->{'SignUpUser'} = \&access_SignUpUser;
     $webtools::sys__subs__->{'SignInUser'} = \&access_SignInUser;
    }
  }
 if($new_driver =~ m/^sess_flat$/si)
  {
   if(!($webtools::loaded_functions & 16))
    {
     require $driver_path.'sess_flat.pl';
     $webtools::loaded_functions = $webtools::loaded_functions | 16;
    }
   else
    {
     if($sess_force_flat =~ m/^on$/si)
      {
       $webtools::sys__subs__->{'session_clear_expired'} = \&sess_flat_session_clear_expired;
       $webtools::sys__subs__->{'session_expire_update'} = \&sess_flat_session_expire_update;
       $webtools::sys__subs__->{'insert_sessions_row'} = \&sess_flat_insert_sessions_row;
       $webtools::sys__subs__->{'DB_OnDestroy'} = \&sess_flat_DB_OnDestroy;
      }
    }
   }
 if($new_driver =~ m/^none$/si)
  {
   &save_database_handlers();
   
   $webtools::sys__subs__->{'DB_OnExit'} = \&none_DB_Empty_Sub;
   $webtools::sys__subs__->{'hideerror'} = \&none_DB_Empty_Sub;
   $webtools::sys__subs__->{'sql_connect'} = \&none_DB_Empty_Sub;
   $webtools::sys__subs__->{'sql_connect2'} = \&none_DB_Empty_Sub;
   $webtools::sys__subs__->{'test_connect'} = \&none_DB_Empty_Sub;
   $webtools::sys__subs__->{'sql_disconnect'} = \&none_DB_Empty_Sub;
   $webtools::sys__subs__->{'sql_query'} = \&none_DB_Empty_Sub;
   $webtools::sys__subs__->{'sql_fetchrow'} = \&none_DB_Empty_Sub;
   $webtools::sys__subs__->{'sql_affected_rows'} = \&none_DB_Empty_Sub;
   $webtools::sys__subs__->{'sql_inserted_id'} = \&none_DB_Empty_Sub;
   $webtools::sys__subs__->{'sql_create_db'} = \&none_DB_Empty_Sub;
   $webtools::sys__subs__->{'sql_drop_db'} = \&none_DB_Empty_Sub;
   $webtools::sys__subs__->{'sql_select_db'} = \&none_DB_Empty_Sub;
   $webtools::sys__subs__->{'sql_num_fields'} = \&none_DB_Empty_Sub;
   $webtools::sys__subs__->{'sql_num_rows'} = \&none_DB_Empty_Sub;
   $webtools::sys__subs__->{'sql_data_seek'} = \&none_DB_Empty_Sub;
   $webtools::sys__subs__->{'sql_errmsg'} = \&none_DB_Empty_Sub;
   $webtools::sys__subs__->{'sql_errno'} = \&none_DB_Empty_Sub;
   $webtools::sys__subs__->{'sql_quote'} = \&none_DB_Empty_Sub;
   $webtools::sys__subs__->{'unsupported_types'} = \&none_DB_Empty_Sub;
   $webtools::sys__subs__->{'session_clear_expired'} = \&none_DB_Empty_Sub;
   $webtools::sys__subs__->{'session_expire_update'} = \&none_DB_Empty_Sub;
   $webtools::sys__subs__->{'insert_sessions_row'} = \&none_DB_Empty_Sub;
   $webtools::sys__subs__->{'DB_OnDestroy'} = \&none_DB_Empty_Sub;
   $webtools::sys__subs__->{'SignUpUser'} = \&none_DB_Empty_Sub;
   $webtools::sys__subs__->{'SignInUser'} = \&none_DB_Empty_Sub;
  }
 return(1);
}
sub none_DB_Empty_Sub
{
 return(1);
}
##########################################################################
sub base_rand_maker
{
 my ($n) = @_;
 srand($n);
 my $i = rand(12);
 my $load = $l_charset[$i];
 return(substr($load,$n,1))
}
sub convert_ses_time
{
 my ($cs,$l) = @_;
 my $rs = "";
 for($i=0;$i<$l;$i++)
  {
   $n = substr($cs,$i,1);
   $rs .= base_rand_maker($n);
  }
 return($rs);
}
sub DieAlert
 {
  ClearBuffer();
  ClearHeader();
  print '<font color="red"><B><h2>'.shift().'</h2></B></font>';
  fush_print();
  exit;
 }
############################################
# Parse Form
############################################
sub Parse_Form
{
 return (1);
}
#####################################################################
# User Defined Functions
#####################################################################

#####################################################################
sub onExit
{ 
  my $todo = shift;
  # now we are going to erase all the files uploaded on the server ...
  my $delete_uploaded_files = << 'EVAL_TERMINATOR';
  while ( my ($file_name,$full_path_to_file) = each( %uploaded_files) )
    {
      if (-e $full_path_to_file)
        {
          unlink ($full_path_to_file); 
        }
    }
 if($todo ne 'withOutDB')
  {
   if($webtools::db_support ne "") {DB_OnDestroy($webtools::system_database_handle);}
  }
EVAL_TERMINATOR
 eval $delete_uploaded_files;
 return(1);
}

sub onLockedFileErrorEvent
{
 Header(type => 'content');
 $print_flush_buffer = '';
 flush_print();
 print "<br><font color='red'><h3>Error: Server is too busy! Please press Ctrl+R after few seconds (20-30)</h3></font>";
 onExit();
 exit;
}

sub set_ignore_termination
{
 $webtools::sys_ignore_term = shift;
}
sub get_ignore_termination
{
 return($webtools::sys_ignore_term);
}

sub On_Term_Event
     {
      my $obj   = shift;
      my $err   = shift;
      my $name  = shift;
      # User hit STOP button or...admin shutdown Apache server :-)
      if(!$webtools::sys_ignore_term)
       {
        if(exists($webtools::SIGNALS{'OnTerm'}))
           {
            eval {
      	          my $OnEvent_code = $webtools::SIGNALS{'OnTerm'};
      	          &$OnEvent_code;
      	         };
           }
       }
      if(!$webtools::sys_ignore_term)
       {
  	if($webtools::system_database_handle ne undef)
  	  {
  	   my $q =<<'THAT_TERM_SIG_STR';
  	   DB_OnExit($webtools::system_database_handle);
  	   $webtools::system_database_handle = undef;
  	   $usystem_database_handle = undef;
THAT_TERM_SIG_STR
  	   eval $q;
  	  }
  	eval {onExit();};
        CORE::exit;
       }
  }

##########################################################
# Case insensetive list function "exists"
# PROTO: ($status,[$key,$value]) = exists_insensetive(
#        $lookup_key,%hash);
##########################################################
sub exists_insensetive
{
 my $lookup = uc(shift);
 my @data = @_;
 my %hash = @_;
 my $i = 0;
 my $k;
 foreach $k (@data)
  {
   $i++;
   if($i % 2)
    {
     if($lookup eq uc($k))
      {
       return(('1',$k,$hash{$k}));  # Return '1',$key,$value
      }
    }
  }
 return((0,'','')); # Not found
}

sub set_variables_dump
{
 my $dmp = shift(@_);
 my $style = shift(@_) || 'layer';
 if ($dmp =~ m/^(YES|ON|OK|Y|TRUE|DONE|1)$/si)
  {
   $webtools::global_variables_dump = 1;
   eval 'require "dump.pl";';
  }
 else
  {
   $webtools::global_variables_dump = 0;
  }
 $webtools::global_variables_dump_style = $style;
}

# Follow code process all supported INLINE tags for fast code writings!
sub pre_process_templates ($)
{
 my $sys_temp_buffer = shift(@_);
 local *SYS_PRE_PROCESS_TEMPLATES_FILE;
 my $sys_binlinet = '\<\!\-\-\©INLINE\©\>';   # <!--©INLINE©>
 my $sys_einlinet = '\<\/\©INLINE\©\-\-\>';   # </©INLINE©-->
 my $sys_binlinep = '\<\!\-\-\©INPERL\©\>';   # <!--©INPERL©>
 my $sys_einlinep = '\<\/\©INPERL\©\-\-\>';   # </©INPERL©-->
 
 my $sys_binlinet_new = '\%\%\%INLINE\%\%\%';   # %%%INLINE%%%
 my $sys_einlinet_new = '\%\%\%\/INLINE\%\%\%'; # %%%/INLINE%%%
 my $sys_binlinep_new = '\%\%\%INPERL\%\%\%';   # %%%INPERL%%%
 my $sys_einlinep_new = '\%\%\%\/INPERL\%\%\%'; # %%%/INPERL%%%
 
 my $sys_include_file = '\<\!\-\-\©INCLUDE\©(.*?)\©\-\-\>';     # <!--©INCLUDE©file.ext©-->
 my $sys_include_file_new = '\<\!\-\-\%INCLUDE\%(.*?)\%\-\-\>'; # <!--%INCLUDE%file.ext%-->
 my $sys_include_file_new2 = '\%\%\%INCLUDE\%(.*?)\%\%\%';      # %%%INCLUDE%file.ext%%%
 
 my $work_buffer = $sys_temp_buffer;
 
 $sys_temp_buffer =~ s#$sys_include_file#do{
    my $sys_prd_template;
    if(open(SYS_PRE_PROCESS_TEMPLATES_FILE,$1))
     {
      binmode(SYS_PRE_PROCESS_TEMPLATES_FILE);
      local $/ = undef;
      read(SYS_PRE_PROCESS_TEMPLATES_FILE,$sys_prd_template,(-s SYS_PRE_PROCESS_TEMPLATES_FILE));
      $sys_prd_template =~ s/\r\n/\n/gs;
      $sys_prd_template =~ s/\<\!\-\- PERL:(.*?)(\<\?perl.*?\?\>.*?)\/\/\-\-\>\n?/$2/gsi;
      $sys_prd_template =~ s/\<\!\-\- PERL:(.*?)\/\/\-\-\>\n?//gsi;
      close(SYS_PRE_PROCESS_TEMPLATES_FILE);
     }
    else {$sys_prd_template = '';}
    $work_buffer =~ s/$sys_include_file/$sys_prd_template/si;
   };#sgie;
 
 $sys_temp_buffer = $work_buffer;
 
 $sys_temp_buffer =~ s#$sys_include_file_new#do{
    my $sys_prd_template;
    if(open(SYS_PRE_PROCESS_TEMPLATES_FILE,$1))
     {
      binmode(SYS_PRE_PROCESS_TEMPLATES_FILE);
      local $/ = undef;
      read(SYS_PRE_PROCESS_TEMPLATES_FILE,$sys_prd_template,(-s SYS_PRE_PROCESS_TEMPLATES_FILE));
      $sys_prd_template =~ s/\r\n/\n/gs;
      $sys_prd_template =~ s/\<\!\-\- PERL:(.*?)(\<\?perl.*?\?\>.*?)\/\/\-\-\>\n?/$2/gsi;
      $sys_prd_template =~ s/\<\!\-\- PERL:(.*?)\/\/\-\-\>\n?//gsi;
      close(SYS_PRE_PROCESS_TEMPLATES_FILE);
     }
    else {$sys_prd_template = '';}
    $work_buffer =~ s/$sys_include_file_new/$sys_prd_template/si;
   };#sgie;
 
 $sys_temp_buffer = $work_buffer;
 
 $sys_temp_buffer =~ s#$sys_include_file_new2#do{
    my $sys_prd_template;
    if(open(SYS_PRE_PROCESS_TEMPLATES_FILE,$1))
     {
      binmode(SYS_PRE_PROCESS_TEMPLATES_FILE);
      local $/ = undef;
      read(SYS_PRE_PROCESS_TEMPLATES_FILE,$sys_prd_template,(-s SYS_PRE_PROCESS_TEMPLATES_FILE));
      $sys_prd_template =~ s/\r\n/\n/gs;
      $sys_prd_template =~ s/\<\!\-\- PERL:(.*?)(\<\?perl.*?\?\>.*?)\/\/\-\-\>\n?/$2/gsi;
      $sys_prd_template =~ s/\<\!\-\- PERL:(.*?)\/\/\-\-\>\n?//gsi;
      close(SYS_PRE_PROCESS_TEMPLATES_FILE);
     }
    else {$sys_prd_template = '';}
    $work_buffer =~ s/$sys_include_file_new2/$sys_prd_template/si;
   };#sgie;
 
 $sys_temp_buffer = $work_buffer;
 $sys_temp_buffer =~ s#$sys_binlinet(.*?)$sys_einlinet#do{
    my $sys_prd_template = sys_make_template_code($1,'h');
    $work_buffer =~ s/$sys_binlinet(.*?)$sys_einlinet/$sys_prd_template/si;
   };#sgie;
 
 $sys_temp_buffer = $work_buffer;
 $sys_temp_buffer =~ s#$sys_binlinep(.*?)$sys_einlinep#do{
    my $sys_prd_template = sys_make_template_code($1,'p');
    $work_buffer =~ s/$sys_binlinep(.*?)$sys_einlinep/$sys_prd_template/si;
   };#sgie;
 
 $sys_temp_buffer = $work_buffer;
 $sys_temp_buffer =~ s#$sys_binlinet_new(.*?)$sys_einlinet_new#do{
    my $sys_prd_template = sys_make_template_code($1,'h');
    $work_buffer =~ s/$sys_binlinet_new(.*?)$sys_einlinet_new/$sys_prd_template/si;
   };#sgie;
 
 $sys_temp_buffer = $work_buffer;
 $sys_temp_buffer =~ s#$sys_binlinep_new(.*?)$sys_einlinep_new#do{
    my $sys_prd_template = sys_make_template_code($1,'p');
    $work_buffer =~ s/$sys_binlinep_new(.*?)$sys_einlinep_new/$sys_prd_template/si;
   };#sgie;
 
 return($work_buffer);
}

# This sub process all supported form INLINE template formats
sub sys_make_template_code
{
 my $sys_my_pre_process_tempf = shift(@_);
 my $sys_my_pre_process_ph_b = "<?perl \n";
 my $sys_my_pre_process_ph_e = "\n?>";
 my $sys_my_pre_process_print = "print ";
 $syspre_process_counter++;
 
 if($_[0] eq 'p')
   {
    $sys_my_pre_process_ph_b = "\n";
    $sys_my_pre_process_ph_e = "\n";
    $sys_my_pre_process_print = '$_ = ';
   }
 
 # ----- Make code for simple TEMPLATES -----
 # example: <§TEMPLATE:7:$val:§>
 if($sys_my_pre_process_tempf =~ m/\<\§TEMPLATE\:(\d{1,})\:(.*?)\:\§\>/si)
  {
   my $sys_my_pre_process_num = $1;
   my $sys_my_pre_process_val = $2;
   if($sys_my_pre_process_val =~ m/^(\$|\@|\%)/s)
     {
      $sys_my_pre_process_sys_code = $sys_my_pre_process_ph_b.$sys_my_pre_process_print.'('.$sys_my_pre_process_val.');'.$sys_my_pre_process_ph_e;
     }
   else
     {
      $sys_my_pre_process_sys_code = $sys_my_pre_process_ph_b.$sys_my_pre_process_print."('".$sys_my_pre_process_val."');".$sys_my_pre_process_ph_e;
     }
   return($sys_my_pre_process_sys_code);
  }
 
 # ----- Make code for simple TEMPLATES -----
 # example: %%TEMPLATE:7:$val:%%
 if($sys_my_pre_process_tempf =~ m/\%\%TEMPLATE\:(\d{1,})\:(.*?)\:\%\%/si)
  {
   my $sys_my_pre_process_num = $1;
   my $sys_my_pre_process_val = $2;
   if($sys_my_pre_process_val =~ m/^(\$|\@|\%)/s)
     {
      $sys_my_pre_process_sys_code = $sys_my_pre_process_ph_b.$sys_my_pre_process_print.'('.$sys_my_pre_process_val.');'.$sys_my_pre_process_ph_e;
     }
   else
     {
      $sys_my_pre_process_sys_code = $sys_my_pre_process_ph_b.$sys_my_pre_process_print."('".$sys_my_pre_process_val."');".$sys_my_pre_process_ph_e;
     }
   return($sys_my_pre_process_sys_code);
  }
 
 # ----- Make code for simple TEMPLATES -----
 # example: ??TEMPLATE:7:$val:??
 if($sys_my_pre_process_tempf =~ m/\?\?TEMPLATE\:(\d{1,})\:(.*?)\:\?\?/si)
  {
   my $sys_my_pre_process_num = $1;
   my $sys_my_pre_process_val = $2;
   if($sys_my_pre_process_val =~ m/^(\$|\@|\%)/s)
     {
      $sys_my_pre_process_sys_code = $sys_my_pre_process_ph_b.$sys_my_pre_process_print.'('.$sys_my_pre_process_val.');'.$sys_my_pre_process_ph_e;
     }
   else
     {
      $sys_my_pre_process_sys_code = $sys_my_pre_process_ph_b.$sys_my_pre_process_print."('".$sys_my_pre_process_val."');".$sys_my_pre_process_ph_e;
     }
   return($sys_my_pre_process_sys_code);
  }

 # ----- Make code for XREADER -----
 if($sys_my_pre_process_tempf =~ m/\<XREADER:.+?\:(.*?)\:(.*?)\>/si)
  {
    my $sys_my_pre_process_sys_code = $sys_my_pre_process_ph_b.q# my $rztl_sconn;
     if(($webtools::system_database_handle eq undef) and ($webtools::db_support ne ''))
        {
          $rztl_sconn = sql_connect(); 
        }
     if(!($webtools::loaded_functions & 8)) {eval 'require $library_path.'."'xreader.pl';";}
     xreader_dbh($rztl_sconn);#;
     
   $sys_my_pre_process_tmp_eval = '$sys_my_pre_process_val_N_'.$syspre_process_counter.' = $sys_my_pre_process_tempf;';
   eval $sys_my_pre_process_tmp_eval;
   
   $sys_my_pre_process_sys_code .= "\n".$sys_my_pre_process_print.'sys_run_time_process_xread('.'$sys_my_pre_process_val_N_'.$syspre_process_counter.');'.$sys_my_pre_process_ph_e;
   return($sys_my_pre_process_sys_code);
  }
 # ----- Make code for XREADER -----
 if($sys_my_pre_process_tempf =~ m/\%\%XREADER:.+?\:(.*?)\:(.*?)\%\%/si)
  {
    my $sys_my_pre_process_sys_code = $sys_my_pre_process_ph_b.q# my $rztl_sconn;
     if(($webtools::system_database_handle eq undef) and ($webtools::db_support ne ''))
        {
          $rztl_sconn = sql_connect(); 
        }
     if(!($webtools::loaded_functions & 8)) {eval 'require $library_path.'."'xreader.pl';";}
     xreader_dbh($rztl_sconn);#;
     
   $sys_my_pre_process_tmp_eval = '$sys_my_pre_process_val_N_'.$syspre_process_counter.' = $sys_my_pre_process_tempf;';
   eval $sys_my_pre_process_tmp_eval;
   
   $sys_my_pre_process_sys_code .= "\n".$sys_my_pre_process_print.'sys_run_time_process_xread('.'$sys_my_pre_process_val_N_'.$syspre_process_counter.');'.$sys_my_pre_process_ph_e;
   return($sys_my_pre_process_sys_code);
  }
  
 # ----- Make code for SQL Templates -----
 if($sys_my_pre_process_tempf =~ m/\<S\©L\:\d{1,}\:(.*?)\:.+?\:.+?\:.+?\:.+?\:S\©L\>/si)
  {
    my $sys_my_pre_process_sys_code = $sys_my_pre_process_ph_b.q# my $rztl_sconn;
     if(($webtools::system_database_handle eq undef) and ($webtools::db_support ne ''))
        {
          $rztl_sconn = sql_connect(); 
          if($rztl_sconn eq undef) { print '?C?'; exit(-1);}
        }
     if(!($webtools::loaded_functions & 8)) {eval 'require $library_path.'."'xreader.pl';";}
     xreader_dbh($rztl_sconn);#;

   $sys_my_pre_process_tmp_eval = '$sys_my_pre_process_val_N_'.$syspre_process_counter.' = $sys_my_pre_process_tempf;';
   eval $sys_my_pre_process_tmp_eval;
   
   $sys_my_pre_process_sys_code .= "\n".$sys_my_pre_process_print.'sys_run_time_process_sql('.'$sys_my_pre_process_val_N_'.$syspre_process_counter.');'.$sys_my_pre_process_ph_e;
   return($sys_my_pre_process_sys_code);
  }
 # ----- Make code for SQL Templates -----
 if($sys_my_pre_process_tempf =~ m/\%\%SQL\:\d{1,}\:(.*?)\:.+?\:.+?\:.+?\:.+?\:SQL\%\%/si)
  {
    my $sys_my_pre_process_sys_code = $sys_my_pre_process_ph_b.q# my $rztl_sconn;
     if(($webtools::system_database_handle eq undef) and ($webtools::db_support ne ''))
        {
          $rztl_sconn = sql_connect(); 
          if($rztl_sconn eq undef) { print '?C?'; exit(-1);}
        }
     if(!($webtools::loaded_functions & 8)) {eval 'require $library_path.'."'xreader.pl';";}
     xreader_dbh($rztl_sconn);#;

   $sys_my_pre_process_tmp_eval = '$sys_my_pre_process_val_N_'.$syspre_process_counter.' = $sys_my_pre_process_tempf;';
   eval $sys_my_pre_process_tmp_eval;
   
   $sys_my_pre_process_sys_code .= "\n".$sys_my_pre_process_print.'sys_run_time_process_sql('.'$sys_my_pre_process_val_N_'.$syspre_process_counter.');'.$sys_my_pre_process_ph_e;
   return($sys_my_pre_process_sys_code);
  }
  
 # ----- Make code for SQLVAR Templates -----
 if($sys_my_pre_process_tempf =~ m/\<S\©LVAR\:(.+?)\:S\©L\>/si)
  {
    my $sys_my_pre_process_sys_code = $sys_my_pre_process_ph_b.q# my $rztl_sconn;
     if(($webtools::system_database_handle eq undef) and ($webtools::db_support ne ''))
        {
          $rztl_sconn = sql_connect(); 
          if($rztl_sconn eq undef) { print '?C?'; exit(-1);}
        }
     if(!($webtools::loaded_functions & 8)) {eval 'require $library_path.'."'xreader.pl';";}
     xreader_dbh($rztl_sconn);#;

   $sys_my_pre_process_tmp_eval = '$sys_my_pre_process_val_N_'.$syspre_process_counter.' = $sys_my_pre_process_tempf;';
   eval $sys_my_pre_process_tmp_eval;
   
   $sys_my_pre_process_sys_code .= "\n".$sys_my_pre_process_print.'sys_run_time_process_sqlvar('.'$sys_my_pre_process_val_N_'.$syspre_process_counter.');'.$sys_my_pre_process_ph_e;
   return($sys_my_pre_process_sys_code);
  }
 # ----- Make code for SQLVAR Templates -----
 if($sys_my_pre_process_tempf =~ m/\%\%SQLVAR\:(.+?)\%\%/si)
  {
    my $sys_my_pre_process_sys_code = $sys_my_pre_process_ph_b.q# my $rztl_sconn;
     if(($webtools::system_database_handle eq undef) and ($webtools::db_support ne ''))
        {
          $rztl_sconn = sql_connect(); 
          if($rztl_sconn eq undef) { print '?C?'; exit(-1);}
        }
     if(!($webtools::loaded_functions & 8)) {eval 'require $library_path.'."'xreader.pl';";}
     xreader_dbh($rztl_sconn);#;

   $sys_my_pre_process_tmp_eval = '$sys_my_pre_process_val_N_'.$syspre_process_counter.' = $sys_my_pre_process_tempf;';
   eval $sys_my_pre_process_tmp_eval;
   
   $sys_my_pre_process_sys_code .= "\n".$sys_my_pre_process_print.'sys_run_time_process_sqlvar('.'$sys_my_pre_process_val_N_'.$syspre_process_counter.');'.$sys_my_pre_process_ph_e;
   return($sys_my_pre_process_sys_code);
  }
  
 # ----- Make code for MENUSELECT -----
 if($sys_my_pre_process_tempf =~ m/\<MENUSELECT\:\$(.*?)\:(.*?)\:\$(.*?)\:\$(.*?)\:\$(.*?)\:\$(.*?)\:\>/si)
  {
    my $sys_my_pre_process_sys_code = $sys_my_pre_process_ph_b.q# my $rztl_sconn;
     if(($webtools::system_database_handle eq undef) and ($webtools::db_support ne ''))
        {
          $rztl_sconn = sql_connect();
        }
     if(!($webtools::loaded_functions & 8)) {eval 'require $library_path.'."'xreader.pl';";}
     xreader_dbh($rztl_sconn);#;

   $sys_my_pre_process_tmp_eval = '$sys_my_pre_process_val_N_'.$syspre_process_counter.' = $sys_my_pre_process_tempf;';
   eval $sys_my_pre_process_tmp_eval;
   
   $sys_my_pre_process_sys_code .= "\n".$sys_my_pre_process_print.'sys_run_time_process_menuselect('.'$sys_my_pre_process_val_N_'.$syspre_process_counter.');'.$sys_my_pre_process_ph_e;
   return($sys_my_pre_process_sys_code);
  }
 
 # ----- Make code for MENUSELECT -----
 if($sys_my_pre_process_tempf =~ m/\%\%MENUSELECT\:\$(.*?)\:(.*?)\:\$(.*?)\:\$(.*?)\:\$(.*?)\:\$(.*?)\:\%\%/si)
  {
    my $sys_my_pre_process_sys_code = $sys_my_pre_process_ph_b.q# my $rztl_sconn;
     if(($webtools::system_database_handle eq undef) and ($webtools::db_support ne ''))
        {
          $rztl_sconn = sql_connect();
        }
     if(!($webtools::loaded_functions & 8)) {eval 'require $library_path.'."'xreader.pl';";}
     xreader_dbh($rztl_sconn);#;

   $sys_my_pre_process_tmp_eval = '$sys_my_pre_process_val_N_'.$syspre_process_counter.' = $sys_my_pre_process_tempf;';
   eval $sys_my_pre_process_tmp_eval;
   
   $sys_my_pre_process_sys_code .= "\n".$sys_my_pre_process_print.'sys_run_time_process_menuselect('.'$sys_my_pre_process_val_N_'.$syspre_process_counter.');'.$sys_my_pre_process_ph_e;
   return($sys_my_pre_process_sys_code);
  }
 
 return('<?perl print "?Err?"; ?>');
}


# That sub process XREAD template in run-time and it is a part of INLINE feature.
# example: <XREADER:1:bestbuy.jhtml:$first_param,$second_param>
sub sys_run_time_process_xread
{
 my $sys_my_pre_process_tempf = shift(@_);
 if($sys_my_pre_process_tempf =~ m/\<XREADER:(.+?)\:(.*?)\:(.*?)\>/si)
  {
   my $sys_my_pre_process_numb = $1;
   my $sys_my_pre_process_file = $2;
   my $sys_my_pre_process_vals = $3;
   if($sys_my_pre_process_numb =~ m/^\$(.*)$/s)
    {
     my $sys_temp_ev1 = '$sys_my_pre_process_numb = $'.$1.';';
     eval $sys_temp_ev1;
    }
   if($sys_my_pre_process_file =~ m/^\$(.*)$/s)
    {
     my $sys_temp_ev1 = '$sys_my_pre_process_file = $'.$1.';';
     eval $sys_temp_ev1;
    }
   my @sys_my_pre_process_aval = split('\,',$sys_my_pre_process_vals);
   my @sys_my_pre_process_all = ();
   foreach $sys_my_pre_process_aself (@sys_my_pre_process_aval)
    {
     if($sys_my_pre_process_aself =~ m/^(\$|\@|\%)/s)
      {
       my $sys_my_pre_process_eval = 'push (@sys_my_pre_process_all,'.$sys_my_pre_process_aself.');';
       eval $sys_my_pre_process_eval;
      }
     else
      {
       my $sys_my_pre_process_eval = 'push (@sys_my_pre_process_all,'."'".$sys_my_pre_process_aself."'".');';
       eval $sys_my_pre_process_eval;
      }
    }
   $sys_my_pre_process_sys_code = xreader($sys_my_pre_process_numb,$sys_my_pre_process_file,@sys_my_pre_process_all);
   return($sys_my_pre_process_sys_code);
  }
 if($sys_my_pre_process_tempf =~ m/\%\%XREADER:(.+?)\:(.*?)\:(.*?)\%\%/si)
  {
   my $sys_my_pre_process_numb = $1;
   my $sys_my_pre_process_file = $2;
   my $sys_my_pre_process_vals = $3;
   if($sys_my_pre_process_numb =~ m/^\$(.*)$/s)
    {
     my $sys_temp_ev1 = '$sys_my_pre_process_numb = $'.$1.';';
     eval $sys_temp_ev1;
    }
   if($sys_my_pre_process_file =~ m/^\$(.*)$/s)
    {
     my $sys_temp_ev1 = '$sys_my_pre_process_file = $'.$1.';';
     eval $sys_temp_ev1;
    }
   my @sys_my_pre_process_aval = split('\,',$sys_my_pre_process_vals);
   my @sys_my_pre_process_all = ();
   foreach $sys_my_pre_process_aself (@sys_my_pre_process_aval)
    {
     if($sys_my_pre_process_aself =~ m/^(\$|\@|\%)/s)
      {
       my $sys_my_pre_process_eval = 'push (@sys_my_pre_process_all,'.$sys_my_pre_process_aself.');';
       eval $sys_my_pre_process_eval;
      }
     else
      {
       my $sys_my_pre_process_eval = 'push (@sys_my_pre_process_all,'."'".$sys_my_pre_process_aself."'".');';
       eval $sys_my_pre_process_eval;
      }
    }
   $sys_my_pre_process_sys_code = xreader($sys_my_pre_process_numb,$sys_my_pre_process_file,@sys_my_pre_process_all);
   return($sys_my_pre_process_sys_code);
  }
}

# That sub process SQL template in run-time and it is a part of INLINE feature.
# example: <S©L:1:"select USER,ID from demo_users where id=1;":1:1:1:1:S©L>
sub sys_run_time_process_sql
{
 my $sys_my_pre_process_tempf = shift(@_);
 if($sys_my_pre_process_tempf =~ m/(\<S\©L\:\d{1,}\:)(.*?)(\:.+?\:.+?\:.+?\:.+?\:)S\©L\>/si)
  {
   my $sys_my_pre_process_beg  = $1;
   my $sys_my_pre_process_data = $2;
   my $sys_my_pre_process_end  = $3;
   my @sys_my_pre_a = split(/\:/,$sys_my_pre_process_end);
   my $sys_line;
   $sys_my_pre_process_end = ':';
   foreach $sys_line (@sys_my_pre_a)
    {
     if($sys_line ne '')
      {
       if($sys_line =~ m/^\$(.*)$/s)
        {
         my $sys_temp_ev1 = '$sys_my_pre_process_end .= $'.$1.".':'".';';
         eval $sys_temp_ev1;
        }
       else {$sys_my_pre_process_end .= $sys_line.":";}
      }
    }
   $sys_my_pre_process_end .= 'S©L>';
   my $sys_my_pre_process_tmp  = 0;
   my $sys_pre_process_replce = '';
  
   if($sys_my_pre_process_data =~ m/([\ \']{0,})\$(.*?)([\'\ \;\"])/si)
     {
      my $sys_pre_process_tmp_1 = $1;
      my $sys_pre_process_tmp_2 = $2;
      my $sys_pre_process_tmp_3 = $3;
      my $sys_pre_process_tmp_4 = '$sys_pre_process_replce = $'.$sys_pre_process_tmp_2.';';
      eval $sys_pre_process_tmp_4;
      $sys_pre_process_replce = $sys_pre_process_tmp_1.$sys_pre_process_replce.$sys_pre_process_tmp_3;
      $sys_my_pre_process_data =~ s/([\ \']{0,})\$(.*?)([\'\ \;\"])/$sys_pre_process_replce/si;
     }
   $sys_my_pre_process_tempf = $sys_my_pre_process_beg.$sys_my_pre_process_data.$sys_my_pre_process_end;
   print $sys_my_pre_process_tempf;
   return(_mem_xreader($sys_my_pre_process_tempf));
  }
 if($sys_my_pre_process_tempf =~ m/(\%\%SQL\:\d{1,}\:)(.*?)(\:.+?\:.+?\:.+?\:.+?\:)SQL\%\%/si)
  {
   my $sys_my_pre_process_beg  = $1;
   my $sys_my_pre_process_data = $2;
   my $sys_my_pre_process_end  = $3;
   my @sys_my_pre_a = split(/\:/,$sys_my_pre_process_end);
   my $sys_line;
   $sys_my_pre_process_end = ':';
   foreach $sys_line (@sys_my_pre_a)
    {
     if($sys_line ne '')
      {
       if($sys_line =~ m/^\$(.*)$/s)
        {
         my $sys_temp_ev1 = '$sys_my_pre_process_end .= $'.$1.".':'".';';
         eval $sys_temp_ev1;
        }
       else {$sys_my_pre_process_end .= $sys_line.":";}
      }
    }
   $sys_my_pre_process_end .= 'SQL%%';
   my $sys_my_pre_process_tmp  = 0;
   my $sys_pre_process_replce = '';
  
   if($sys_my_pre_process_data =~ m/([\ \']{0,})\$(.*?)([\'\ \;\"])/si)
     {
      my $sys_pre_process_tmp_1 = $1;
      my $sys_pre_process_tmp_2 = $2;
      my $sys_pre_process_tmp_3 = $3;
      my $sys_pre_process_tmp_4 = '$sys_pre_process_replce = $'.$sys_pre_process_tmp_2.';';
      eval $sys_pre_process_tmp_4;
      $sys_pre_process_replce = $sys_pre_process_tmp_1.$sys_pre_process_replce.$sys_pre_process_tmp_3;
      $sys_my_pre_process_data =~ s/([\ \']{0,})\$(.*?)([\'\ \;\"])/$sys_pre_process_replce/si;
     }
   $sys_my_pre_process_tempf = $sys_my_pre_process_beg.$sys_my_pre_process_data.$sys_my_pre_process_end;
   print $sys_my_pre_process_tempf;
   return(_mem_xreader($sys_my_pre_process_tempf));
  }
}

# That sub process SQLVAR template's variables in run-time and it is a part of INLINE feature.
# example: <S©LVAR:1:S©L>
sub sys_run_time_process_sqlvar
{
 my $sys_my_pre_process_tempf = shift(@_);
 if($sys_my_pre_process_tempf =~ m/(\<S\©LVAR)(\:.*?\:)(S\©L\>)/si)
  {
   my $sys_my_pre_process_beg  = $1;
   my $sys_my_pre_process_data = $2;
   my $sys_my_pre_process_end  = $3;
   my $sys_my_pre_process_tmp  = 0;
   my $sys_pre_process_replce = '';
  
   if($sys_my_pre_process_data =~ m/(\:)\$(.*?)(\:)/si)
     {
      my $sys_pre_process_tmp_1 = $1;
      my $sys_pre_process_tmp_2 = $2;
      my $sys_pre_process_tmp_3 = $3;
      my $sys_pre_process_tmp_4 = '$sys_pre_process_replce = $'.$sys_pre_process_tmp_2.';';
      eval $sys_pre_process_tmp_4;
      $sys_pre_process_replce = $sys_pre_process_tmp_1.$sys_pre_process_replce.$sys_pre_process_tmp_3;
      $sys_my_pre_process_data =~ s/(\:)\$(.*?)(\:)/$sys_pre_process_replce/si;
     }
   $sys_my_pre_process_tempf = $sys_my_pre_process_beg.$sys_my_pre_process_data.$sys_my_pre_process_end;
   return(_mem_xreader($sys_my_pre_process_tempf));
  }
 if($sys_my_pre_process_tempf =~ m/(\%\%SQLVAR)(\:.*?)(\%\%)/si)
  {
   my $sys_my_pre_process_beg  = $1;
   my $sys_my_pre_process_data = $2;
   my $sys_my_pre_process_end  = $3;
   my $sys_my_pre_process_tmp  = 0;
   my $sys_pre_process_replce = '';
  
   if($sys_my_pre_process_data =~ m/(\:)\$(.*?)$/si)
     {
      my $sys_pre_process_tmp_1 = $1;
      my $sys_pre_process_tmp_2 = $2;
      my $sys_pre_process_tmp_4 = '$sys_pre_process_replce = $'.$sys_pre_process_tmp_2.';';
      eval $sys_pre_process_tmp_4;
      $sys_pre_process_replce = $sys_pre_process_tmp_1.$sys_pre_process_replce;
      $sys_my_pre_process_data =~ s/(\:)\$(.*?)$/$sys_pre_process_replce/si;
     }
   $sys_my_pre_process_tempf = $sys_my_pre_process_beg.$sys_my_pre_process_data.$sys_my_pre_process_end;
   return(_mem_xreader($sys_my_pre_process_tempf));
  }
}

# That sub process MENUSELECT template in run-time and it is a part of INLINE feature.
# exmp: <MENUSELECT:$SOURCE:"SELECT MenuState FROM MyTable WHERE Condition1 = $C1 AND ...":\@DB_VALUES:\@TEMPLATE_NUMBERS:\@HTML_VALUES:$dbh:>
sub sys_run_time_process_menuselect
{
 my $sys_my_pre_process_tempf = shift(@_);
 if($sys_my_pre_process_tempf =~ m/\<MENUSELECT\:\$(.*?)\:\$(.*?)\:\$(.*?)\:\$(.*?)\:\$(.*?)\:\$(.*?)\:\>/si)
  {
   my $sys_my_pre_process_src  = $1;
   my $sys_my_pre_process_sql  = $2;
   my $sys_my_pre_process_dbv  = $3;
   my $sys_my_pre_process_tem  = $4;
   my $sys_my_pre_process_htm  = $5;
   my $sys_my_pre_process_dbh  = $6;
   my $sys_pre_process_replce = '';

   my $sys_my_pre_process_tmp = '$sys_my_pre_process_src = $'.$sys_my_pre_process_src.';';
   eval $sys_my_pre_process_tmp;
   $sys_my_pre_process_tmp = '$sys_my_pre_process_dbv = $'.$sys_my_pre_process_dbv.';';
   eval $sys_my_pre_process_tmp;
   $sys_my_pre_process_tmp = '$sys_my_pre_process_tem = $'.$sys_my_pre_process_tem.';';
   eval $sys_my_pre_process_tmp;
   $sys_my_pre_process_tmp = '$sys_my_pre_process_htm = $'.$sys_my_pre_process_htm.';';
   eval $sys_my_pre_process_tmp;
   $sys_my_pre_process_tmp = '$sys_my_pre_process_sql = $'.$sys_my_pre_process_sql.';';
   eval $sys_my_pre_process_tmp;
   $sys_my_pre_process_tmp = '$sys_my_pre_process_dbh = $'.$sys_my_pre_process_dbh.';';
   eval $sys_my_pre_process_tmp;

   if(($sys_my_pre_process_dbh eq '') or ($sys_my_pre_process_dbh eq undef))
      {$sys_my_pre_process_dbh = $webtools::system_database_handle;}
   
   my @sys_my_pre_process_dbv_a  = @$sys_my_pre_process_dbv;
   my @sys_my_pre_process_tem_a  = @$sys_my_pre_process_tem;
   my @sys_my_pre_process_htm_a  = @$sys_my_pre_process_htm;

   $sys_my_pre_process_src = MenuSelect($sys_my_pre_process_src,$sys_my_pre_process_sql,$sys_my_pre_process_dbv,
                                        $sys_my_pre_process_tem,$sys_my_pre_process_htm,$sys_my_pre_process_dbh);
   return($sys_my_pre_process_src);
  }
 if($sys_my_pre_process_tempf =~ m/\%\%MENUSELECT\:\$(.*?)\:\$(.*?)\:\$(.*?)\:\$(.*?)\:\$(.*?)\:\$(.*?)\:\%\%/si)
  {
   my $sys_my_pre_process_src  = $1;
   my $sys_my_pre_process_sql  = $2;
   my $sys_my_pre_process_dbv  = $3;
   my $sys_my_pre_process_tem  = $4;
   my $sys_my_pre_process_htm  = $5;
   my $sys_my_pre_process_dbh  = $6;
   my $sys_pre_process_replce = '';

   my $sys_my_pre_process_tmp = '$sys_my_pre_process_src = $'.$sys_my_pre_process_src.';';
   eval $sys_my_pre_process_tmp;
   $sys_my_pre_process_tmp = '$sys_my_pre_process_dbv = $'.$sys_my_pre_process_dbv.';';
   eval $sys_my_pre_process_tmp;
   $sys_my_pre_process_tmp = '$sys_my_pre_process_tem = $'.$sys_my_pre_process_tem.';';
   eval $sys_my_pre_process_tmp;
   $sys_my_pre_process_tmp = '$sys_my_pre_process_htm = $'.$sys_my_pre_process_htm.';';
   eval $sys_my_pre_process_tmp;
   $sys_my_pre_process_tmp = '$sys_my_pre_process_sql = $'.$sys_my_pre_process_sql.';';
   eval $sys_my_pre_process_tmp;
   $sys_my_pre_process_tmp = '$sys_my_pre_process_dbh = $'.$sys_my_pre_process_dbh.';';
   eval $sys_my_pre_process_tmp;

   if(($sys_my_pre_process_dbh eq '') or ($sys_my_pre_process_dbh eq undef))
      {$sys_my_pre_process_dbh = $webtools::system_database_handle;}
   
   my @sys_my_pre_process_dbv_a  = @$sys_my_pre_process_dbv;
   my @sys_my_pre_process_tem_a  = @$sys_my_pre_process_tem;
   my @sys_my_pre_process_htm_a  = @$sys_my_pre_process_htm;

   $sys_my_pre_process_src = MenuSelect($sys_my_pre_process_src,$sys_my_pre_process_sql,$sys_my_pre_process_dbv,
                                        $sys_my_pre_process_tem,$sys_my_pre_process_htm,$sys_my_pre_process_dbh);
   return($sys_my_pre_process_src);
  }
}

1;  # Well done...
__END__

=head1 NAME

webtools - Full featured WEB Development Tools (compare with Php language) in Perl syntax

=head1 DESCRIPTION

=over 4

This package is written in pure Perl and its main purpose is: to help all Web developers. 
It brings in self many features of modern Web developing:

  -  Grabs best of Php but in Perl syntax.
  -  Embedded Perl into HTML files.
  -  Buffered output.
  -  Easy reading input forms and cookies using global variables.
  -  Flat files database support.
  -  MySQL/MS Access support.
  -  Full Sessions support (via flat files or via DB)
  -  Easy User support (SignIn / SignUp)
  -  Cookies support.
  -  Attached variables.
  -  Html/SQL templates and variables.
  -  Mail functions (plain/html mails/uploads)
  -  Upload/download functions via Perl scripts.
  -  DES III encription/decription in MIME style
  and more...

=back

=head1 SYNOPSIS

 Follow example show session capabilities, when WebTools is configured with 
 Flat file session support(default):

 <?perl 
    
    $sid = session_start();
    
    %h = read_hash('myhash');
    
    if($h{'city'} ne "Pleven")
      {
       print "<B>New session started!</B>";
       %h = (city=>"Pleven",country=>"Bulgaria");
       $reg_data = register_var('hash','myhash',%h);
       # $reg_data .= register_var('scalar','scl_name',$cnt);
       # $reg_data .= register_var('array',''arrname',@arr);
       session_register($reg_data);
      }
    else
      {
       print "Current session is: <B>$sid</B> <BR> and registrated data are:<BR>";
       print "Country: <B>".$h{'country'}."</B><BR>";
       print "City: <B>".$h{'city'}."</B><BR>";
       session_destroy();
       print "Session Destroyed!";
      }
    Header(type=>'content',val=>'text/html; charset=Windows-1251');
    # SURPRISE: We send header after html data??? (Is Php capable of this? ;-)
 ?>
 
 Above code can be saved in 'htmls' directory under 'test.whtml' file name and you can
 run it in browser location with follow line:
 http://your_host.com/cgi-bin/webtools/process.cgi?file=test.whtml


 
 Code below show how easy is to send e-mails with WebTools
 (Don't forget to set $debug_mail = 'off' in config.pl)
 <?perl 
 
    require 'mail.pl';
    
    $to   = 'some@where.com';
    $from = 'me@myhost.com';
    $subject = 'Test';
    $body = 'Hello there!';
    
    $orginal_filename = $uploaded_original_file_names{'myupload'};
    # 'myupload' is name of input field in html form.
    
    $fn = $uploaded_files{'myupload'};
    
    set_mail_attachment($orginal_filename,$fn);
    
    send_mail($from,$to,$subject,$body);
    print 'Mail sent!';
 ?>

 Above code can be saved in 'htmls' directory under 'mail.whtml' file name and you can
 run it in browser location with follow line:
 http://your_host.com/cgi-bin/webtools/process.cgi?file=mail.whtml
 

=over 4

=item Specifications and examples

=back

 Please read HELP.doc and see all examples in docs/examples directory

=cut