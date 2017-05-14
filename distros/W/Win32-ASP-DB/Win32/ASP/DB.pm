############################################################################
#
# Win32::ASP::DB - an abstract parent class for database access
#                  in the Win32-ASP-DB system
#
# Author: Toby Everett
# Revision: 0.02
# Last Change:
############################################################################
# Copyright 1999, 2000 Toby Everett.  All rights reserved.
#
# This file is distributed under the Artistic License. See
# http://www.ActiveState.com/corporate/artistic_license.htm or
# the license that comes with your perl distribution.
#
# For comments, questions, bugs or general interest, feel free to
# contact Toby Everett at teverett@alascom.att.com
############################################################################

package Win32::ASP::DB;
use Error qw/:try/;
use Win32::ASP::Error;
use Win32::OLE::Variant;

use strict vars;

sub new {
  my $class = shift;
  my($provider, $connectstring) = @_;

  my $self = {
    db => undef,
  };

  bless $self, $class;

  $self->{db} = $main::Server->CreateObject('ADODB.Connection') or
      throw Win32::ASP::Error::DB::init;

  $self->{db}->{Provider} = $provider;
  $self->{db}->Open($connectstring);
  $self->{db}->State or
      throw Win32::ASP::Error::DB::connect (username => Win32::LoginName());

  return $self;
}

sub exec_sql {
  my $self = shift;
  my($SQL, %params) = @_;

  my $results = $self->{db}->Execute($SQL) or
      throw Win32::ASP::Error::SQL::exec (SQL => $SQL, DB_obj => $self);

  $params{error_no_records} and $results->EOF and
      throw Win32::ASP::Error::SQL::no_records (SQL => $SQL);

  return $results;
}

sub get_sql_errors {
  my $self = shift;

  my $errors = $self->{db}->Errors;
  my $retval;
  foreach my $i (0..$errors->Count-1) {
    $retval .= "Error $i:\n";
    foreach my $j (qw/Number Description Source SQLState NativeError/) {
      $retval .= "  $j: ".$errors->Item(0)->{$j}."\n";
    }
    $retval .= "\n";
  }
  return $retval;
}

sub insert {
  my $self = shift;
  my($tablename, @data) = @_;

  scalar(@data) or return;

  my $recSet = $main::Server->CreateObject('ADODB.Recordset') or
      throw Win32::ASP::Error::SQL::insert
      (error_type => 'recordset', tablename => $tablename, DB_obj => $self);

  $recSet->Open($tablename, $self->{db}, 1, 3, 512); # adOpenKeyset, adLockOptimistic, adCmdTableDirect
  Win32::OLE->LastError and throw Win32::ASP::Error::SQL::insert
      (error_type => 'tableopen', tablename => $tablename, DB_obj => $self);

  $recSet->AddNew;
  Win32::OLE->LastError and throw Win32::ASP::Error::SQL::insert
      (error_type => 'addnew', tablename => $tablename, DB_obj => $self);

  foreach my $i (@data) {
    $recSet->Fields->Item($i->{field})->{Value} = defined $i->{value} ? $i->{value} : Variant(1);
    Win32::OLE->LastError and throw Win32::ASP::Error::SQL::insert
        (error_type => 'setvalue', tablename => $tablename, DB_obj => $self, write_pair => $i);
  }

  $recSet->Update;
  Win32::OLE->LastError and throw Win32::ASP::Error::SQL::insert
      (error_type => 'update', tablename => $tablename, DB_obj => $self);

  return $recSet;
}

sub update {
  my $self = shift;
  my($tablename, $condition, @data) = @_;

  scalar(@data) or return;

  my $recSet = $main::Server->CreateObject('ADODB.Recordset') or
      throw Win32::ASP::Error::SQL::update
      (error_type => 'recordset', tablename => $tablename, DB_obj => $self);

  $recSet->Open("SELECT * FROM $tablename WHERE $condition", $self->{db}, 3, 3); # adOpenStatic, adLockOptimistic
  Win32::OLE->LastError and throw Win32::ASP::Error::SQL::update
      (error_type => 'tableopen', tablename => $tablename, DB_obj => $self);

  $recSet->{recordCount} != 1 and
      throw Win32::ASP::Error::SQL::update
      (error_type => 'condition', tablename => $tablename, DB_obj => $self, condition => $condition);

  foreach my $i (@data) {
    $recSet->Fields->Item($i->{field})->{Value} = defined $i->{value} ? $i->{value} : Variant(1);
    Win32::OLE->LastError and throw Win32::ASP::Error::SQL::update
        (error_type => 'setvalue', tablename => $tablename, DB_obj => $self, write_pair => $i);
  }

  $recSet->Update;
  Win32::OLE->LastError and throw Win32::ASP::Error::SQL::update
      (error_type => 'update', tablename => $tablename, DB_obj => $self);

  return $recSet;
}

sub begin_trans {
  my $self = shift;

  $self->{translevel}++;
  $self->{translevel} == 1 and $self->{db}->BeginTrans;
}

sub commit_trans {
  my $self = shift;

  $self->{translevel}--;
  $self->{translevel} == 0 and $self->{db}->CommitTrans;
}



#################### Error Classes ############################


package Win32::ASP::Error::DB;
@Win32::ASP::Error::DB::ISA = qw/Win32::ASP::Error/;


package Win32::ASP::Error::DB::init;
@Win32::ASP::Error::DB::init::ISA = qw/Win32::ASP::Error::DB/;

sub _as_html {
  my $self = shift;
  return "Unable to create ADODB.Connection object.  ASP server is incorrectly setup.";
}


package Win32::ASP::Error::DB::connect;
@Win32::ASP::Error::DB::connect::ISA = qw/Win32::ASP::Error::DB/;

#Parameters:  username

sub _as_html {
  my $self = shift;

  my $username = $self->username;
  return "Unable to login to database as $username.";
}



package Win32::ASP::Error::SQL;
@Win32::ASP::Error::SQL::ISA = qw/Win32::ASP::Error/;

sub _error_msg {
  my $self = shift;

  my $error_type = $self->error_type;

  if ($error_type eq 'recordset') {
    return "Couldn't create RecordSet object.";
  } elsif ($error_type eq 'tablename') {
    return "Couldn't open table.";
  } elsif ($error_type eq 'addnew') {
    return  "Couldn't add new record to table.";
  } elsif ($error_type eq 'condition') {
    return "The condition '".$self->condition."' did not uniquely specify a record.";
  } elsif ($error_type eq 'setvalue') {
    return "Couldn't set field '".$self->write_pair->{field}."' to value ".
        (defined $self->write_pair->{value} ? "'".($self->write_pair->{value})."'" : 'NULL').".";
  } elsif ($error_type eq 'update') {
    return "Couldn't write changes to table.";
  }
}


package Win32::ASP::Error::SQL::exec;
@Win32::ASP::Error::SQL::exec::ISA = qw/Win32::ASP::Error::SQL/;

#Parameters:  DB_obj, SQL

sub _as_html {
  my $self = shift;

  my $SQL = $self->SQL;
  my $errors = $self->DB_obj->get_sql_errors;
  return <<ENDHTML;
There was an error executing the following SQL:<P>
<XMP>
$SQL
</XMP>
The errors encountered were:<P>
<XMP>
$errors
</XMP>
ENDHTML
}


package Win32::ASP::Error::SQL::insert;
@Win32::ASP::Error::SQL::insert::ISA = qw/Win32::ASP::Error::SQL/;

#Parameters:  tablename, , error_type, DB_obj

sub _as_html {
  my $self = shift;

  my $tablename = $self->tablename;
  my $error_msg = $self->error_msg;
  my $errors = $self->DB_obj->get_sql_errors;
  return <<ENDHTML;
There were errors encountered inserting a record into the table '$tablename'.<P>
The error type was: $error_msg<P>
The ADO errors were:<P>
<XMP>
$errors
</XMP>
ENDHTML
}


package Win32::ASP::Error::SQL::no_records;
@Win32::ASP::Error::SQL::no_records::ISA = qw/Win32::ASP::Error::SQL/;

#Parameters:  SQL

sub _as_html {
  my $self = shift;

  my $SQL = $self->SQL;
  return <<ENDHTML;
There was an error executing the following SQL:<P>
<XMP>
$SQL
</XMP>
There were no records returned and there should have been.<P>
ENDHTML
}


package Win32::ASP::Error::SQL::update;
@Win32::ASP::Error::SQL::update::ISA = qw/Win32::ASP::Error::SQL/;

#Parameters:  tablename, error_type, DB_obj

sub _as_html {
  my $self = shift;

  my $tablename = $self->tablename;
  my $error_msg = $self->error_msg;
  my $errors = $self->DB_obj->get_sql_errors;
  return <<ENDHTML;
There were errors encountered updating a record into the table '$tablename'.<P>
The error type was: $error_msg<P>
The ADO errors were:<P>
<XMP>
$errors
</XMP>
ENDHTML
}

1;
