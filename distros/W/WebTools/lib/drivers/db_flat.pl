#####################################################################
#  ###   ###     ###   ####   #####  #   #  #####  ####             #
#  #  #  #  #    #  #  #   #    #    #   #  #      #   #            #
#  #  #  ####    #  #  ####     #    #   #  #####  ####             #
#  #  #  #  #    #  #  #  #     #     # #   #      #  #             #
#  ###   ###     ###   #  ##  #####    #    #####  #  ##            #
#####################################################################
#  DRIVER FOR Flat DB (DBD::WTSprite)
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
use lib '../../modules/';
eval 'use DBD::WTSprite;';
if($@ ne '')
 {
  print "<br><font color='red'><h3>Error: DBD::WTSprite module was not installed on your server!</h3></font><BR>";
  print "<br><font color='red'><h3>NOTE: This DBD::WTSprite module must be into WebTools package, not into standart LIB directory!</h3></font><BR>";
  print "<br><font color='red'><h3>Please try to reinstall your WebTools! (don't try to install DBD::WTSprite)</h3></font><BR>";
  exit;
 }
 
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

sub flat_DB_OnExit
   {
    my ($system_database_handle) = @_;
    if(!$system_database_handle->{AutoCommit}){$system_database_handle->commit();}
    flat_sql_disconnect($system_database_handle);
    undef($system_database_handle);
    return(1);
   }
sub flat_hideerror 
     {
      eval
       {
        ClearBuffer();
        flush_print();
        select(STDOUT);
        my $t = tied(*SESSIONSTDOUT);
        $t->reset;
       };
      print "<br><font color='red'><h2>Error: Can`t connect to Flat database!</h2></font>";
      if($debugging =~ m/^on$/i)
        {
         print "<BR><font color='red'><h3>Debug mode: ON<BR>Error: ".$DBI::errstr."</h3></font><BR>";
        }
      print "<font color='green' size=2>Please think over follow things at all...</font>";
      print "<br><font color='green' size=2> - What is your DB name, User name and password?</font>";
      print "<br><font color='green' size=2> - Where is DB located and how it is linked?</font>";
      print "<br><font color='green' size=2> - There is DBD::WTSprite and is it correct installed?</font>";
      print "<br><font color='green' size=2> - Is Apache has a correct user (permission to access DB files)?</font>";
      print "<br><BR><font color='black'><h3>Please be nice and send e-mail to: $support_email </h3></font>";
      exit;
     }
sub flat_sql_connect   # No params needed!
    {
     if($#_ == -1)
      {
       if($system_database_handle ne undef) {flat_sql_disconnect($system_database_handle);}
       my $oldslcthnd = select(STDOUT);
       if($db_path =~ m/^\.\./s) {$db_path = './';}
       $oldh = $SIG{'__WARN__'};
       $SIG{'__WARN__'} = "flat_hideerror";
       my $OurSQL = DBI->connect("DBI:WTSprite:".$db_path."$sql_database_sessions",$sql_user,$sql_pass,{AutoCommit => 0, PrintError => 0}) or flat_hideerror;
       $SIG{'__WARN__'} = $oldh;
       $system_database_handle = $OurSQL;   # That is current opened DB Handler!
       select($oldslcthnd);
       return($OurSQL);
      }
     else  # ($host,$database,$user,$pass,[$port],[$full_path])
      {
       my ($host,$database,$user,$pass,$port,$path) = @_;
       my $oldslcthnd = select(STDOUT);
       $host = $host || 'localhost';
       $database = $database || $sql_database_sessions;
       $user = $user || $sql_user;

       $oldh = $SIG{'__WARN__'};
       $SIG{'__WARN__'} = "flat_hideerror";
       my $port = $port eq '' ? '' : ';port='.$port;
       my $uOurSQL = DBI->connect("DBI:WTSprite:".$path."$database",$user,$pass,{AutoCommit => 0, PrintError => 0}) or flat_hideerror;
       $SIG{'__WARN__'} = $oldh;
       $webtools::usystem_database_handle_flat = $uOurSQL;   # That is current opened DB Handler!
       select($oldslcthnd);
       return($uOurSQL);
      }
    }
sub flat_test_connect
   {
     my $oldslcthnd = select(STDOUT);
     if($db_path =~ m/^\.\./s) {$db_path = './';}
     $oldh = $SIG{'__WARN__'};
     $SIG{'__WARN__'} = '';
     my $OurSQL = DBI->connect("DBI:WTSprite:".$db_path."$sql_database_sessions",$sql_user,$sql_pass,{AutoCommit => 0, PrintError => 0}) or return(0);
     $SIG{'__WARN__'} = $oldh;
     $system_database_handle = $OurSQL;   # That is current opened DB Handler!
     select($oldslcthnd);
     return($OurSQL);
   }
sub flat_sql_connect2
    {
     my ($db) = @_;
     my $oldslcthnd = select(STDOUT);
     $oldh = $SIG{'__WARN__'};
     $SIG{'__WARN__'} = "flat_hideerror";
     my $OurSQL = DBI->connect("DBI:WTSprite:".$db_path."$db",$sql_user,$sql_pass,{AutoCommit => 0, PrintError => 0}) or flat_hideerror();
     $SIG{'__WARN__'} = $oldh;
     $system_database_handle = $OurSQL;   # That is current opened DB Handler!
     select($oldslcthnd);
     return($OurSQL);     
    }
sub flat_sql_disconnect # Only db handler is required!
   {
    my ($DBH) = @_;
    if(!$DBH->{AutoCommit}){$DBH->commit();}
    $DBH->disconnect();
    undef($DBH);
    return (1);
   }
sub flat_sql_query   # ($query,$db_handler)
    {
     my ($q,$DBH) = @_;
     $q =~ s/;$//s;
     my $hSt = $DBH->prepare($q);
     if($hSt)
      {
       my $er = $hSt->execute();
       if(!$er) 
          {
           flush_print();
           print "<BR><font color='red'><B>Error: Incorrect query!<B></font>";exit;
           return $DBH->errstr();
          }
       $DBH->commit();      # Can it work without commit???
       return ($hSt);
      }
     else {flush_print();print "<BR><font color='red'><B>Error: Incorrect query!<B></font>";exit;return $DBH->errstr();}
    }
sub flat_sql_fetchrow    # ($result_handler)
    {
     my ($resdb) = @_;
     my $raRes = $resdb->fetchrow_arrayref();
     my @arr = @$raRes;
     return(@arr);
    }
sub flat_sql_affected_rows   # ($result_handler)
    {    
     my ($resdb) = @_;
     my $number = $resdb->rows;
     return($number);
    }
sub flat_sql_inserted_id   # ($result_handler)
    {    
     my ($resdb) = @_;
     my $number = undef;
     return($number);
    }    
sub flat_sql_create_db   # ($table_description,$db_handler) -> Not DB! This is TABLE!
    {    
     my ($db,$DBH) = @_;
     $db =~ s/;$//s;
     my $res = $DBH->do('CREATE TABLE '.$db);
     $DBH->commit();
     return($res);        # Just like Access Driver?
    }        
sub flat_sql_drop_db   # ($db_name,$db_handler) -> Not DB! This is TABLE!
    {    
     my ($db,$DBH) = @_;
     $db =~ s/;$//s;
     my $res = $DBH->do('DROP TABLE '.$db);
     $DBH->commit();
     return($res);
    } 
sub flat_sql_select_db
 {
    my($db, $self) = @_;
    if($db_path =~ m/^\.\./s) {$db_path = './';}
    my $dbh = flat_sql_connect('localhost',$db,$sql_user, $sql_pass, 0, $db_path);
    if (!$dbh) 
     {
      return(undef);
     }
    else
     {
      if ($self) 
        {
	 flat_sql_disconnect($self);
   	}
     }
    return($dbh);
 }
sub flat_sql_num_fields   # ($result_handler)
    {    
     my ($resdb) = @_;
     my $number = $resdb->{NUM_OF_FIELDS};
     return($number);
    }
sub flat_sql_num_rows   # ($result_handler)
    {    
     my ($resdb) = @_;
     my $number = flat_sql_affected_rows($resdb);
     return($number);
    }
sub flat_sql_data_seek
{
 my ($row,$res) = @_;
 return(-1);
}
sub flat_sql_errmsg
{
  my ($dbh) = @_;
  return($DBI::errstr);
}
sub flat_sql_errno
{
  my ($dbh) = @_;
  return($DBI::err);
}
sub flat_sql_quote
{
 my ($unquoted_string,$dbh) = @_;
 my $str = $dbh->quote($unquoted_string);
 return($str);
}
sub flat_sql_unsupported_types
{
 my ($q,$DBH) = @_;
 return($q);
}
#####################################################################
# Session Support Functions
#####################################################################
sub flat_session_clear_expired
{
 my ($dbh) = @_;
 my $i_id;
 my $ctime = scalar(time());
 my @my_array;
 if($sess_force_flat eq 'off') ###DB###
 {
  my $er = flat_sql_query("delete from $sql_sessions_table where EXPIRE < $ctime;",$dbh);
  if ($er eq undef) { return(0); }
 }
 else
 {
  ###FLAT###
  remove_SF_OldSessions($tmp,time()-$sys_time_for_flat_sess);
 }
 return(1);
}
sub flat_session_expire_update
{
 my ($dbh) = @_;
 my %calmin  = ('second',1,'minute',60,'hour',3600,'day',86400,'month',2678400,'year',31536000);
 my %globmin = ('s',1,'m',60,'h',3600,'d',86400,'M',2678400,'y',31536000);
 my $inter = $sess_time * $calmin{$sess_datetype};
 $inter += time();
 my $i_id;
 if($sess_force_flat eq 'off') ###DB###
 {
  my $ip = $ENV{'REMOTE_ADDR'}; # Get remote IP address
  my $r_q = '';
  if($ip_restrict_mode =~ m/^on$/i)
    {
     $r_q = " and IP = \'$ip\'";    # Restrict session on IP!
    }
  my $r = flat_sql_query("update $sql_sessions_table set EXPIRE = $inter where S_ID = \'$sys_local_sess_id\'".$r_q,$dbh);
  if ($r eq undef) { return(0);}
 }
 else
 {
  ###FLAT###
  return(update_SF_File($tmp,$sys_local_sess_id));
 }
 return (1);
}
sub flat_insert_sessions_row   # ($session_id,$db_handler)
{
  my ($dbh) = @_;
  my %calmin  = ('second',1,'minute',60,'hour',3600,'day',86400,'month',2678400,'year',31536000);
  my %globmin = ('s',1,'m',60,'h',3600,'d',86400,'M',2678400,'y',31536000);
  my $inter = $sess_time * $calmin{$sess_datetype};
  $inter += time();
  my $sid = $sys_local_sess_id;
  my $ip = $ENV{'REMOTE_ADDR'}; # Get remote IP address
  if($sess_force_flat eq 'off') ###DB###
  {
   my $q = "INSERT INTO $sql_sessions_table VALUES(MAXVAL('ID|$sql_sessions_table'),?,?,?,?,?)";
   my $res = $dbh->do($q,undef,$sid,$ip,$inter,0,'');
   $dbh->commit();

   if ($res eq '1')
     {
      return(1);
     }
  }
  else
  {
   ###FLAT###
   write_SF_File($tmp,$sys_local_sess_id,'');
   return(1);
  }
  return(0);
}
sub flat_DB_OnDestroy
 {
   return(1);        # Something like Commit!
 }
#####################################################################
# USER DEFINED FUNCTIONS
#####################################################################
sub flat_SignUpUser
{
 my ($user,$pass,$data,$active,$fname,$lname,$email,$dbh) = @_;
 my $ut = "SELECT USER FROM $sql_user_table WHERE USER=?";
 my $q = "INSERT INTO $sql_user_table VALUES (MAXVAL('ID|$sql_user_table'),?,?,?,?,?,?,?,?)";
 $active = uc($active);
 my $rut = $dbh->prepare($ut);
 $rut->execute($user);

 my @arr = ();
 eval {@arr = flat_sql_fetchrow($rut);};
 if ($arr[0] ne '') {return(0);}
 else
  {
   my $res = $dbh->do($q,undef,$user,$pass,$active,$data,time(),$fname,$lname,$email);
   $dbh->commit();
   if ($res eq '1')
     {
       return(1);
     }
   return(0);
  } 
 return(0); 
}
sub flat_SignInUser
{
 my ($user,$pass,$dbh) = @_;
 $user = flat_sql_quote($user,$dbh);
 $pass = flat_sql_quote($pass,$dbh);
 my $q = "SELECT ID,DATA FROM $sql_user_table WHERE USER=$user and PASSWORD=$pass and ACTIVE='Y';";
 my $res = flat_sql_query($q,$dbh);
 if ($res eq undef)
   {
    return((undef,undef));
   }
 my ($ID,$DATA) = flat_sql_fetchrow($res);
 if ($ID eq '') {return((undef,undef)); }
 return($ID,$DATA);
}

1;