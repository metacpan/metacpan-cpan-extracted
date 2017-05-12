#####################################################################
#  ###   ###     ###   ####   #####  #   #  #####  ####             #
#  #  #  #  #    #  #  #   #    #    #   #  #      #   #            #
#  #  #  ####    #  #  ####     #    #   #  #####  ####             #
#  #  #  #  #    #  #  #  #     #     # #   #      #  #             #
#  ###   ###     ###   #  ##  #####    #    #####  #  ##            #
#####################################################################
#  DB DRIVER FOR MySQL (DBI)
#####################################################################
#####################################################################

# Copyright (c) 2001, Julian Lishev, Sofia 2002
# All rights reserved.
# This code is free software; you can redistribute
# it and/or modify it under the same terms 
# as Perl itself.

#####################################################################

eval 'use DBI;';
if($@ ne '')
 {
  print "<br><font color='red'><h3>Error: DBI module was not installed on your server!</h3></font>";
  exit;
 }

$DBD::mysql = $mysqlbequiet;

# Prevent warnings in web browser from external programs and drivers
# Send warnings to "null" device. Works great on: Unix/Linux/WinXP

open (STDERR,'>>/dev/null');

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

sub mysql_DB_OnExit
   {
    my ($system_database_handle) = @_;
    if($system_database_handle)
     {
      $system_database_handle->disconnect();
      undef($system_database_handle);
     }
    return(1);
   }
sub mysql_hideerror
     {
      ClearBuffer();
      flush_print();
      select(STDOUT);
      my $t = tied(*SESSIONSTDOUT);
      $t->reset;
      print "<br><font color='red'><h2>Error: Can`t connect to MySQL database!</h2></font>";
      if($debugging =~ m/^on$/i)
        {
         print "<BR><font color='red'><h3>Debug mode: ON<BR>Error: ".$DBI::errstr."</h3></font><BR>";
        }
      print "<font color='green' size=2>Please think over follow things at all...</font>";
      print "<br><font color='green' size=2> - What is your DB name, User name and password?</font>";
      print "<br><BR><font color='black'><h3>Please be nice and send e-mail to: $support_email </h3></font>";
      exit;
     }
sub mysql_sql_connect   # No params needed!
    {
     if($#_ == -1)
      {
       $oldh = $SIG{'__WARN__'};
       $SIG{'__WARN__'} = "mysql_hideerror";
       my $port = $sql_port eq '' ? '' : ';port='.$sql_port;
       my $OurSQL = DBI->connect("DBI:mysql:$sql_database_sessions:$sql_host$port",$sql_user,$sql_pass);
       $SIG{'__WARN__'} = $oldh;
       $system_database_handle = $OurSQL;   # That is current opened DB Handler!
       return($OurSQL);
      }
     else    # ($host,$database,$user,$pass,[$port])
      {
       my ($host,$database,$user,$pass,$port) = @_;
       $port = $port || 3306;
       $host = $host || 'localhost';
       $user = $user || $sql_user;

       $oldh = $SIG{'__WARN__'};
       $SIG{'__WARN__'} = "mysql_hideerror";
       my $port = $port eq '' ? '' : ';port='.$port;
       my $uOurSQL = DBI->connect("DBI:mysql:$database:$host$port",$user,$pass);
       $SIG{'__WARN__'} = $oldh;
       $webtools::usystem_database_handle_mysql = $uOurSQL;   # That is current opened DB Handler!
       return($uOurSQL);
      }
    }
sub mysql_test_connect
   {
     $oldh = $SIG{'__WARN__'};
     $SIG{'__WARN__'} = '';
     my $port = $sql_port eq '' ? '' : ';port='.$sql_port;
     my $OurSQL = DBI->connect("DBI:mysql:$sql_database_sessions:$sql_host$port",$sql_user,$sql_pass) or return(0);
     $SIG{'__WARN__'} = $oldh;
     $system_database_handle = $OurSQL;   # That is current opened DB Handler!
     return($OurSQL);
   }
sub mysql_sql_disconnect # Only db handler is required!
   {
    my ($DBH) = @_;
    $DBH->disconnect();
    undef($DBH);
    return (1);
   }
sub mysql_sql_query   # ($query,$db_handler)
    {
     my ($q,$DBH) = @_;
     $q = mysql_sql_unsupported_types($q,$DBH);
     $q =~ s/;$//s;
     my $hSt = $DBH->prepare($q);
     if($hSt)
      {
       my $er = $hSt->execute();
       if(!$er) 
          {
           return (undef);
          }
       return ($hSt);
      }
     else {flush_print();print "<BR><font color='red'><B>Error: Incorrect MySQL query!<B></font>";exit;return $DBH->errstr();}
    }
sub mysql_sql_fetchrow    # ($result_handler)
    {
     my ($resdb) = @_;
     if($resdb)
      {
       my $raRes = $resdb->fetchrow_arrayref();
       my @arr = @$raRes;
       return(@arr);
      }
     return(0);
    }
sub mysql_sql_affected_rows   # ($result_handler)
    {    
     my ($resdb) = @_;
     if($resdb)
      {
       my $number = $resdb->rows;
       return($number);
      }
     return(0);
    }
sub mysql_sql_inserted_id   # ($result_handler)
    {    
     my ($resdb) = @_;
     if($resdb)
      {
       my $number = $resdb->{'mysql_insertid'};  # ST
       return($number);
      }
     return(0);
    }    
sub mysql_sql_create_db   # ($db_name,$db_handler)
    {    
     my ($db,$DBH) = @_;
     my $r;
     if ($DBH->{'dbh'}) 
      {
	$r = $DBH->{'dbh'}->admin('createdb', $db, 'admin');
      }
     else 
      {
        $r = $DBH->{'drh'}->func('createdb', $db, $DBH->{'host'},
                                 $DBH->{'user'}, $DBH->{'password'}, 'admin');
      }
     return($r);
    }        
sub mysql_sql_drop_db   # ($db_name,$db_handler)
    {    
     my ($db,$DBH) = @_;
     my $r;
     if ($DBH->{'dbh'}) 
      {
	$r = $DBH->{'dbh'}->admin('dropdb', $db, 'admin');
      }
     else 
      {
        $r = $DBH->{'drh'}->func('dropdb', $db, $DBH->{'host'},
                                 $DBH->{'user'}, $DBH->{'password'}, 'admin');
      }
     return($r);
    } 
sub mysql_sql_select_db   # ($db_name,$db_handler)
    {    
     my($db, $self) = @_;
     my $dsn = "DBI:mysql:database=$db:host=" . $self->{'host'};
     my $dbh = DBI->connect($dsn, $self->{'user'}, $self->{'password'});
     if (!$dbh) {
 	$db_errstr = $self->{'errstr'} = $DBI::errstr;
 	$self->{'errno'} = $DBI::err;
 	undef;
     } else {
 	if ($self->{'dbh'}) {
 	    local $SIG{'__WARN__'} = sub {};
 	    $self->{'dbh'}->disconnect();
 	}
 	$self->{'dbh'} = $dbh;
 	$self->{'db'} = $db;
 	$self;
     }
     
    }
sub mysql_sql_num_fields   # ($result_handler)
    {    
     my ($resdb) = @_;
     if($resdb)
      {
       my $number = $resdb->{'NUM_OF_FIELDS'};
       return($number);
      }
     return(0);
    }
sub mysql_sql_num_rows   # ($result_handler)
    {    
     my ($resdb) = @_;
     if($resdb)
      {
       my $number = $resdb->rows();
       return($number);
      }
     return(0);
    }

sub mysql_sql_data_seek
 {
  my($pos, $self) = @_;
  $self->func($pos, 'dataseek');
 }
sub mysql_sql_errmsg
{
  my ($dbh) = @_;
  return($DBI::errstr);
}

sub mysql_sql_errno
{
  my ($dbh) = @_;
  return($DBI::err);
}
sub mysql_sql_quote
{
 my ($unquoted_string,$dbh) = @_;
 return($dbh->quote($unquoted_string));
}
sub mysql_sql_unsupported_types
{
 my ($q,$DBH) = @_;
 while ($q =~ m/MAXVAL( *?)\(.*?\)/si)
    {
      $access_local_id_counter++;
      my $mtime = int(time());                                # It's realy bad way to make new unique IDs but...
      if($mtime < 900000000) {$mtime = $mtime + 1000000000;}  # Add more life for our ID :)
      $q =~ s/MAXVAL( *?)\(.*?\)/$mtime/si;
    }
 return($q);
}
#####################################################################
# Session Support Functions
#####################################################################
sub mysql_session_clear_expired
{
 my ($dbh) = @_;
 my $i_id;
 my @my_array;
 if($sess_force_flat eq 'off') ###DB###
 {
  my $er = mysql_sql_query("delete from $sql_sessions_table where EXPIRE < NOW();",$dbh);
  if ($er eq undef) { return(0); }
 }
 else
 {
  ###FLAT###
  remove_SF_OldSessions($tmp,time()-$sys_time_for_flat_sess);
 }
 return(1);
}
sub mysql_session_expire_update
{
 my ($dbh) = @_;
 my $i_id;
 my $ip = $ENV{'REMOTE_ADDR'}; # Get remote IP address
 my $r_q = '';
 if($sess_force_flat eq 'off') ###DB###
 {
  if($ip_restrict_mode =~ m/^on$/i)
    {
     $r_q = " and IP = \'$ip\'";    # Restrict session on IP!
    }
  my $r = mysql_sql_query("update $sql_sessions_table set EXPIRE = DATE_ADD(NOW(),interval $sess_time $sess_datetype) where S_ID = \'$sys_local_sess_id\'".$r_q,$dbh);
  if ($r eq undef) { return(0);}
 }
 else
 {
  ###FLAT###
  return(update_SF_File($tmp,$sys_local_sess_id));
 }
 return (1);
}
sub mysql_insert_sessions_row   # ($session_id,$db_handler)
{
  my ($dbh) = @_;
  my $sid = $sys_local_sess_id;
  my $ip = $ENV{'REMOTE_ADDR'}; # Get remote IP address
  if($sess_force_flat eq 'off') ###DB###
  {
   my $q = "insert into $sql_sessions_table values(NULL,\'$sid\',\'$ip\',DATE_ADD(NOW(),interval $sess_time $sess_datetype),'0','');";
   my $res = mysql_sql_query($q,$dbh);
   if ($res ne undef)
     {
      return(1);
     }
  }
  else
  {
   ###FLAT###
   write_SF_File($tmp,$sid,'');
   return(1);
  }
  return(0);
}
sub mysql_DB_OnDestroy
 {
   return(1);        # Something like Commit!
 }
#####################################################################
# USER DEFINED FUNCTIONS
#####################################################################
sub mysql_SignUpUser
{
 my ($user,$pass,$data,$active,$fname,$lname,$email,$dbh) = @_;
 $active = uc($active);
 $user = mysql_sql_quote($user,$dbh);
 $pass = mysql_sql_quote($pass,$dbh);
 $data = mysql_sql_quote($data,$dbh);
 $fname = mysql_sql_quote($fname,$dbh);
 $lname = mysql_sql_quote($lname,$dbh);
 $email = mysql_sql_quote($email,$dbh);
 my $q = "insert into $sql_user_table values(NULL,$user,$pass,\'$active\',$data,NOW(),$fname,$lname,$email);";
 my $res = mysql_sql_query($q,$dbh);
 if (($res ne undef) and (mysql_sql_affected_rows($res) > 0))
   {
    return(1);
   }
 return(0);
}
sub mysql_SignInUser
{
 my ($user,$pass,$dbh) = @_;
 $user = mysql_sql_quote($user,$dbh);
 $pass = mysql_sql_quote($pass,$dbh);
 $data = mysql_sql_quote($data,$dbh);
 my $q = "select ID,DATA from $sql_user_table where USER=$user and PASSWORD=$pass and ACTIVE='Y';";
 my $res = mysql_sql_query($q,$dbh);
 if ($res eq undef)
   {
    return((undef,undef));
   }
 my ($ID,$DATA) = mysql_sql_fetchrow($res);
 if ($ID eq '') { return((undef,undef)); }
 return(($ID,$DATA));
}
1;