package Apache::WeSQL::Session;

use 5.006;
use strict;
use warnings;
use lib(".");
use lib("..");

use Apache::WeSQL qw(:all);
use Apache::WeSQL::SqlFunc qw(:all);
use Apache::WeSQL::Journalled qw(:all);

use Apache::Constants qw(:common);
require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	session
	sWrite sDelete sRead sReadAll sReadAllLike sOverWrite sDeleteValue sDeleteAll sDeleteAllLike
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );

our $VERSION = '0.53';

# Preloaded methods go here.
############################################################
# session
# Every call to an url passes through this sub (through AppHandler.pm). It makes sure that there is a
# session id for this session. This means that a cookie is set on the client side
# with a random value (16-byte), making it possible to store data in a session, even
# when the user is not logged in!
############################################################
sub session {
	my $dbh = shift;
	my @session;

	# This sub is called from AppHandler.pm _before_ getparams is called, hence _before_ 
	# the %cookies hash is initialised. So get the cookie manually! It's ugly, but the 
	# only solution to the chicken and egg problem where we need the session hash string in
	# WeSQL::getparams, and need the cookies hash here...
  my $r = Apache->request;
  require CGI;
  my $q = new CGI;
  my $sessioncookie = $q->cookie('session');

	if (defined($sessioncookie)) {
		&Apache::WeSQL::log_error("$$: Session: session cookie exists, let's check it against the db") if ($Apache::WeSQL::DEBUG);
		@session = &sqlSelect($dbh,"select id from sessions where hash='$sessioncookie' and status='1'");
	}
	if (!defined($sessioncookie) || !defined($session[0])) {
		&Apache::WeSQL::log_error("$$: Session: building new session hash") if ($Apache::WeSQL::DEBUG);
		# Calculate hash
		my $hashstr = join ('', ('.', '/', 0..9, 'A'..'Z', 'a'..'z')[rand 64, rand 64, rand 64, rand 64, rand 64, rand 64, rand 64, rand 64, rand 64, rand 64, rand 64, rand 64, rand 64, rand 64, rand 64, rand 64]);
		# Store it in the database
		my @cols = ('hash');
		my @vals = ($hashstr);
		&Apache::WeSQL::Journalled::jAdd($dbh,"sessions",\@cols,\@vals,'id');
		# And make the client set it as a cookie
		return "Set-Cookie: session=$hashstr";
	} 
}

############################################################
# The code for storing and retrieving session-data starts here
# Prerequisite: a table like the following in your database (this is the MySQL definition):
# (for the PostgreSQL definition see the sample Addressbook application)
#create table sessiondata (
#  pkey bigint(20) unsigned not null auto_increment,
#  id bigint(20) unsigned not null,
#
#  uid bigint(20) unsigned not null,
#  suid bigint(20) unsigned not NULL default '0',
#  epoch bigint unsigned not null,
#  status tinyint default '1' NOT NULL,
#
#  sessionid bigint(20) unsigned not null,
#  name varchar(50) default '' not null,
#  value varchar(255) default '' not null,
#  primary key (pkey)
#);
#
# Of course, they will also require the table sessions (MySQL definition, see Addressbook application for PostgreSQL):
#create table sessions (
#  pkey bigint(20) unsigned not null auto_increment,
#  id bigint(20) unsigned not null,
#
#  uid bigint(20) unsigned not null,
#  suid bigint(20) unsigned not NULL default '0',
#  epoch bigint unsigned not null,
#  status tinyint default '1' NOT NULL,
#
#  hash varchar(16) default '' not null,
#  primary key (pkey)
#);
############################################################

############################################################
# sWrite
# sWrite is short for session-write, and can add a piece of information,
# described by a key and a value, to the session.
############################################################
sub sWrite {
	my ($dbh,$key,$value) = @_;
	my @session = &sqlSelect($dbh,"select id from sessions where hash='$Apache::WeSQL::cookies{session}' and status='1'");
	my @columns = ('name','value','sessionid');
	my @values = ($key,$value,$session[0]);
	&Apache::WeSQL::log_error("$$: sWrite: add '$key' -> '$value' to session data for session $session[0]") if ($Apache::WeSQL::DEBUG);
	&Apache::WeSQL::Journalled::jAdd($dbh,"sessiondata",\@columns,\@values,"id");
}

############################################################
# sOverWrite
# sOverWrite is short for session-overwrite.
# It writes a key/value pair to the session, but overwrites any existing value for this key.
############################################################
sub sOverWrite {
	my ($dbh,$key,$value) = @_;
	&sDelete($dbh,$key);
	&sWrite($dbh,$key,$value);
}

############################################################
# sRead
# sRead is short for session-read, and will return 1 value for a specified key,
# if stored in the session. Returns undef if there is no such key in the session.
# The optional parameter $sort determines whether the last (default) or the first
# ($sort = 1) value should be returned, if there is more than one key with this
# name.
############################################################
sub sRead {
	my ($dbh,$key,$sort) = @_;
	$sort ||= 0;
	my @session = &sqlSelect($dbh,"select id from sessions where hash='$Apache::WeSQL::cookies{session}' and status='1'");
	&Apache::WeSQL::log_error("$$: sRead: read session data '$key' for session $session[0], " . ($sort == 1?"last added value":"oldest value")) if ($Apache::WeSQL::DEBUG);
	my @result = &sqlSelect($dbh,"select value from sessiondata where sessionid='$session[0]' and name='$key' and status='1' order by id " . ($sort == 1?"DESC":""));
	&Apache::WeSQL::log_error("$$: sRead: session data '$key' for session $session[0] doesn't exist!") if ($Apache::WeSQL::DEBUG && ($#result == -1));
	return undef if ($#result == -1);
	return $result[0];
}

############################################################
# sReadAllCore
# sReadAllCore is called by sReadAll and sReadAllLike, see below
############################################################
sub sReadAllCore {
	my ($dbh,$condition,$sort) = @_;
	$sort ||= 0;
	my @session = &sqlSelect($dbh,"select id from sessions where hash='$Apache::WeSQL::cookies{session}' and status='1'");
	my $c = &sqlSelectMany($dbh,"select name,value from sessiondata where sessionid='$session[0]' and $condition and status='1' order by id " . ($sort == 1?"DESC":""));
	&Apache::WeSQL::log_error("$$: sReadAll: read session data where $condition for session $session[0], order " . ($sort == 1?"LIFO":"FIFO")) if ($Apache::WeSQL::DEBUG);
	return $c;
}

############################################################
# sReadAll
# sRead is short for session-read-all, and will return all values for a specified key,
# if stored in the session. Returns undef if there is no such key in the session.
# The optional parameter $sort determines whether the sorting should be LIFO or FIFO,
# if there is more than one key with this name.
############################################################
sub sReadAll {
	my ($dbh,$key,$sort) = @_;
	return &sReadAllCore($dbh,"name='$key'",$sort);
}

############################################################
# sReadAllLike
# sReadAllLike is nearly identical to sReadAll except that it allows you to get all values
# for all keys that match a certain condition (hence a 'like').
############################################################
sub sReadAllLike {
	my ($dbh,$key,$sort) = @_;
	return &sReadAllCore($dbh,"name like '$key'",$sort);
}

############################################################
# sDelete
# sDelete is short for session-delete, and can delete 1 piece of information,
# described by a key, from a session. Returns the value of the deleted key, so you
# can use sDelete as a 'shift' or 'pop' function.
# Returns undef when no matching key was found.
############################################################
sub sDelete {
	my ($dbh,$key,$sort) = @_;
	$sort ||= 0;
	my @session = &sqlSelect($dbh,"select id from sessions where hash='$Apache::WeSQL::cookies{session}' and status='1'");
	my @result = &sqlSelect($dbh,"select id,value from sessiondata where sessionid='$session[0]' and name='$key' and status='1' order by id " . ($sort == 1?"DESC":""));
	if ($Apache::WeSQL::DEBUG) {
		if ($#result > -1) {
			&Apache::WeSQL::log_error("$$: sDelete: delete '$key' with id '$result[0]' from session data for session $session[0]");
		} else {
			&Apache::WeSQL::log_error("$$: sDelete: '$key' for session $session[0] does not exist");
		}
	}
	return undef if ($#result == -1);
	&Apache::WeSQL::Journalled::jDelete($dbh,"sessiondata","name='$key' and id='$result[0]'");
	return ($result[1]);
}

############################################################
# sDeleteValue
# sDeleteValue is short for session-delete-value, and can delete 1 piece of information,
# described by a key and its value, from a session. 
############################################################
sub sDeleteValue {
	my ($dbh,$key,$value) = @_;
	if ($Apache::WeSQL::DEBUG) {
		my @session = &sqlSelect($dbh,"select id from sessions where hash='$Apache::WeSQL::cookies{session}' and status='1'");
		&Apache::WeSQL::log_error("$$: sDeleteValue: delete '$key' with value '$value' from session data for session $session[0]") 
	}
	&Apache::WeSQL::Journalled::jDelete($dbh,"sessiondata","name='$key' and value='$value'");
}

############################################################
# sDeleteAll
# sDeleteAll is short for session-delete-all, and can delete all session data with a specific key
# WARNING: Unlike sDelete, it will not return the values of the deleted keys...
############################################################
sub sDeleteAll {
	my ($dbh,$key) = @_;
	my @session = &sqlSelect($dbh,"select id from sessions where hash='$Apache::WeSQL::cookies{session}' and status='1'");
	&Apache::WeSQL::Journalled::jDelete($dbh,"sessiondata","name = '$key' and sessionid=$session[0]");
	&Apache::WeSQL::log_error("$$: sDeleteAll: delete all occurences of '$key' from session data for session $session[0]") if ($Apache::WeSQL::DEBUG);
}

############################################################
# sDeleteAllLike
# sDeleteAllLike is nearly identical to sDeleteAll except that it allows you to get all values
# for all keys that match a certain condition (hence a 'like').
# WARNING: Unlike sDelete, it will not return the values of the deleted keys...
############################################################
sub sDeleteAllLike {
	my ($dbh,$key) = @_;
	my @session = &sqlSelect($dbh,"select id from sessions where hash='$Apache::WeSQL::cookies{session}' and status='1'");
	&Apache::WeSQL::Journalled::jDelete($dbh,"sessiondata","name like '$key' and sessionid=$session[0]");
	&Apache::WeSQL::log_error("$$: sDeleteAll: delete all occurences of '$key' from session data for session $session[0]") if ($Apache::WeSQL::DEBUG);
}

############################################################
# The code for storing and retrieving session-data ends here
############################################################

1;
__END__

=head1 NAME

Apache::WeSQL::Session - Session subs for a journalled WeSQL application

=head1 SYNOPSIS

  use Apache::WeSQL::Session qw( :all );

=head1 DESCRIPTION

This module contains the code for session and session data support in WeSQL. 

This module is called from AppHandler.pm, and Journalled.pm

=head1 SESSION DATA

This module also contains some code for storing and retrieving data in a user session. This code is used by the jForm, jDetails and jList code in the Apache::WeSQL::Display module. It needs a table called 'sessiondata' in your database, which is defined as follows (MySQL definition):
(for the PostgreSQL definition see the sample Addressbook application)

    create table sessiondata (
      pkey bigint(20) unsigned not null auto_increment,
      id bigint(20) unsigned not null,

      uid bigint(20) unsigned not null,
      suid bigint(20) unsigned not NULL default '0',
      epoch bigint unsigned not null,
      status tinyint default '1' NOT NULL,

      sessionid bigint(20) unsigned not null,
      name varchar(50) default '' not null,
      value text default '' not null,
      primary key (pkey)
    );

Of course, they will also require the table sessions (MySQL definition, see Addressbook application for PostgreSQL):

		create table sessions (
		  pkey bigint(20) unsigned not null auto_increment,
		  id bigint(20) unsigned not null,

		  uid bigint(20) unsigned not null,
		  suid bigint(20) unsigned not NULL default '0',
		  epoch bigint unsigned not null,
		  status tinyint default '1' NOT NULL,

		  hash varchar(16) default '' not null,
		  primary key (pkey)
		);

The subs for reading/writing/deleting session data are: sWrite sDelete sRead sReadAll sReadAllLike sOverWrite sDeleteValue sDeleteAll sDeleteAllLike. You can use these in EVAL blocks in wesql files, but you'll have to refer to them using the full path, e.g. like this: &Apache::WeSQL::Session::sOverWrite

The sessions work by storing a cookie with a unique value on the user's computer. This means that without cookie support, session support will not be available.

For more information, have a look at the source code of the Apache::WeSQL::Session module.

This module is part of the WeSQL package, version 0.53

(c) 2000-2002 by Ward Vandewege

=head2 EXPORT

None by default. Possible: session sWrite sDelete sRead sReadAll sReadAllLike sOverWrite sDeleteValue sDeleteAll sDeleteAllLike

=head1 AUTHOR

Ward Vandewege, E<lt>ward@pong.beE<gt>

=head1 SEE ALSO

L<Apache::WeSQL>, L<Apache::WeSQL::AppHandler>, L<Apache::WeSQL::Journalled>, L<Apache::WeSQL::Display>

=cut
