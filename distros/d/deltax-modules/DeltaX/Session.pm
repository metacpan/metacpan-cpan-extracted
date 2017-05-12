#-----------------------------------------------------------------
package DeltaX::Session;
#-----------------------------------------------------------------
# $Id: Session.pm,v 1.1 2003/03/17 13:01:36 spicak Exp $
#
# (c) DELTA E.S., 2002 - 2003
# This package is free software; you can use it under "Artistic License" from
# Perl.
#-----------------------------------------------------------------

$DeltaX::Session::VERSION = '1.0';

use strict;
use Exporter;
use Carp;
use Fcntl qw(O_RDWR LOCK_EX LOCK_UN);

use vars qw(@ISA @EXPORT @EXPORT_OK $gs);
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw();

#-----------------------------------------------------------------
sub new {
#-----------------------------------------------------------------
# CONSTRUCTOR
#
	my $pkg = shift;
	my $self = {};
	bless ($self, $pkg);

	croak ("new() called with odd number of parameters - should be of the form field => value")
		if (@_ % 2);

	# default values
	$self->{db}						= undef;
	$self->{table_name}		= 'sessions';
	$self->{shm_key}			= undef;
	$self->{shm_segment}	= 10000;
	$self->{shm_max}			= 1000000;
	$self->{shm_timeout}	= 300;
	$self->{file}					= undef;
	$self->{db_file}			= 'GDBM_File';

	for (my $x = 0; $x <= $#_; $x += 2) {
		croak ("Unkown parameter $_[$x] in new()")
			unless exists $self->{lc($_[$x])};
		$self->{lc($_[$x])} = $_[$x+1];
	}

	# one of db and file must be set
	if (!defined $self->{db} and !defined $self->{file}) {
		croak ("At least one from 'db' and 'file' parameters must be set!");
	}

	if ($self->{db}) {
		require DeltaX::Database;
		import	DeltaX::Database;
	}
	if ($self->{file}) {
		my $tmp = $self->{db_file};
		eval "require $tmp";
		eval "import	$tmp";
	}
	if ($self->{shm_key}) {
		require IPC::SharedCache;
		import	IPC::SharedCache;
	}

	$self->_init_db() if $self->{db};
	$self->_init_file() if $self->{file};
	$self->_init_shm() if $self->{shm_key};

	return $self;
}
# END OF new()


#-----------------------------------------------------------------
sub _init_db {
#-----------------------------------------------------------------
#
	my $self = shift;
	my $db = $self->{db};
	my $tab = $self->{table_name};
	my $result;

	$result = 1;
	$result = $db->open_statement('DeltaX_Session_INS',
		"INSERT INTO $tab VALUES(?, ?, ".$db->date2db('PREPARED','??').")")
			if (! $db->exists_statement('DeltaX_Session_INS'));
	croak ("Cannot initialize statement DeltaX_Session_INS") unless $result > 0;

	$result = 1;
	$result = $db->open_statement('DeltaX_Session_UPD',
		"UPDATE $tab SET sdata = ? WHERE sid = ?")
			if (! $db->exists_statement('DeltaX_Session_UPD'));
	croak ("Cannot initialize statement DeltaX_Session_UPD") unless $result > 0;

	$result = 1;
	$result = $db->open_statement('DeltaX_Session_DEL',
		"DELETE FROM $tab WHERE sid = ?")
			if (! $db->exists_statement('DeltaX_Session_DEL'));
	croak ("Cannot initialize statement DeltaX_Session_DEL") unless $result > 0;

	$result = 1;
	$result = $db->open_statement('DeltaX_Session_TCH',
		"UPDATE $tab SET ts = ".$db->date2db('PREPARED','??')." WHERE sid = ?")
			if (! $db->exists_statement('DeltaX_Session_TCH'));
	croak ("Cannot initialize statement DeltaX_Session_TCH") unless $result > 0;

	$result = 1;
	$result = $db->open_statement('DeltaX_Session_SEL',
		"SELECT * FROM $tab WHERE sid = ?")
			if (! $db->exists_statement('DeltaX_Session_SEL'));
	croak ("Cannot initialize statement DeltaX_Session_SEL") unless $result > 0;

}
# END OF _init_db()

#-----------------------------------------------------------------
sub _destroy_db {
#-----------------------------------------------------------------
#
	my $self = shift;
	my $db = $self->{db};

	$db->close_statement('DeltaX_Session_INS');
	$db->close_statement('DeltaX_Session_UPD');
	$db->close_statement('DeltaX_Session_DEL');
	$db->close_statement('DeltaX_Session_TCH');
	$db->close_statement('DeltaX_Session_SEL');

}
# END OF _destroy_db()

#-----------------------------------------------------------------
sub _init_file {
#-----------------------------------------------------------------
#
	my $self = shift;

	$self->{dbf} = {};
	if (! tie %{$self->{dbf}}, $self->{db_file}, $self->{file}, O_RDWR, 0600) {
		croak ("Cannot open file!");
	}

}
# END OF _init_file()

#-----------------------------------------------------------------
sub _init_shm {
#-----------------------------------------------------------------
#
	my $self = shift;

	$self->{cache} = {};
	if (! tie %{$self->{cache}}, 'IPC::SharedCache', ipc_key => $self->{shm_key},
		load_callback => \&_shm_load,
		validate_callback => \&_shm_validate,
		ipc_segment_size => $self->{shm_segment},
		max_size => $self->{shm_max}) {
		croak ("Cannot connect to shared memory!");
	} 

}
# END OF _init_shm()

#-----------------------------------------------------------------
sub _shm_load {
#-----------------------------------------------------------------
#
	my $key = shift;

	my %rec;

	my %data;
	if ($gs->{db})	 { %data = $gs->_get_db($key); }
	if ($gs->{file}) { %data = $gs->_get_file($key); }

	my @tmp = keys %data;
	return undef unless $#tmp > -1;

	$rec{contnt} = \%data;
	$rec{ltime}  = time();
	return \%rec;
}
# END OF _shm_load()

#-----------------------------------------------------------------
sub _shm_validate {
#-----------------------------------------------------------------
#
	my ($key, $record) = @_;

	my $ltime = $record->{ltime};
	if ( (time() - $ltime) > $gs->{shm_timeout}) {
		return 0;
	}
	return 1;
}
# END OF _shm_validate()

#-----------------------------------------------------------------
sub put {
#-----------------------------------------------------------------
#
	my $self = shift;

	my $sid = shift;
	return -1 unless defined $sid;
	return -2 if $self->exist($sid,1);

	return -3 if (@_ % 2);

	my @data;
	for (my $x = 0; $x <= $#_; $x += 2) {
		push @data, $_[$x].'='.$_[$x+1];
	}
	my $data = join('^^',@data);

	if ($self->{file}) {
		$self->{dbf}->{$sid} = time().'^^'.$data;
	}
	if ($self->{db}) {
		my $result = $self->{db}->perform_statement('DeltaX_Session_INS',
			$sid, $data, $self->{db}->date2db('PREPARED'));
		return -5 unless $result > 0;
	} 

	return 1;
}
# END OF put()


#-----------------------------------------------------------------
sub exist {
#-----------------------------------------------------------------
#
	my $self = shift;

	my $sid = shift;
	return 0 unless defined $sid;

	my $from_put = shift || 0;

	if ($self->{shm_key} and !$from_put) {
		$gs = $self;
		return defined $self->{cache}->{$sid};
	}
	if ($self->{file}) {
		return exists $self->{dbf}->{$sid};
	}
	if ($self->{db}) {
		my ($result) = $self->{db}->perform_statement('DeltaX_Session_SEL', $sid);
		return 1 if $result > 0;
		return 0;
	}
}
# END OF exist()

#-----------------------------------------------------------------
sub get {
#-----------------------------------------------------------------
#
	my $self = shift;

	my $sid = shift;
	return undef unless defined $sid;

	if ($self->{shm_key}) {
		$gs = $self;
		my $tmp = $self->{cache}->{$sid};
		$tmp->{ltime} = time();
		$self->{cache}->{$sid} = $tmp;
		return %{$tmp->{contnt}};
	}
	if ($self->{db}) {
		return $self->_get_db($sid);
	}
	if ($self->{file}) {
		return $self->_get_file($sid);
	}

	return undef;  

}
# END OF get()

#-----------------------------------------------------------------
sub _get_db {
#-----------------------------------------------------------------
#
	my $self = shift;
	my $sid = shift;

	my ($result,undef,$data,$ts) = 
		$self->{db}->perform_statement('DeltaX_Session_SEL', $sid);
	return undef unless $result > 0;
	$result = $self->{db}->perform_statement('DeltaX_Session_TCH',
																$self->{db}->date2db('PREPARED'), $sid);
	#return undef unless $result > 0;
	my @tmp = split(/\^/,$data);
	my %tmp;
	foreach my $tmp (@tmp) {
		my ($key,$val) = split(/=/,$tmp);
		$tmp{$key} = $val if $key;
	}
	
	return %tmp;
}
# END OF _get_db()

#-----------------------------------------------------------------
sub _get_file {
#-----------------------------------------------------------------
#
	my $self = shift;
	my $sid = shift;

	return undef unless exists $self->{dbf}->{$sid};
	my $data = $self->{dbf}->{$sid};
	my @tmp = split(/\^\^/, $data);
	my $ts = shift @tmp;
	my %tmp;
	foreach my $tmp (@tmp) {
		my ($key,$val) = split(/=/,$tmp);
		$tmp{$key} = $val;
	}
	$data = time().'^^'.join('^^',@tmp);
	$self->{dbf}->{$sid} = $data;
	
	return %tmp;
}
# END OF _get_file()

#-----------------------------------------------------------------
sub free {
#-----------------------------------------------------------------
#
	my $self = shift;

	if ($self->{file}) { untie %{$self->{dbf}}; }
	if ($self->{shm_key}) { untie %{$self->{cache}}; }
	if ($self->{db}) { $self->_destroy_db(); }

}
# END OF free()

1;

=head1 NAME

DeltaX::Session - Perl module for session management

     _____
    /     \ _____    ______ ______ ___________
   /  \ /  \\__  \  /  ___//  ___// __ \_  __ \
  /    Y    \/ __ \_\___ \ \___ \\  ___/|  | \/
  \____|__  (____  /____  >____  >\___  >__|
          \/     \/     \/     \/     \/        project


=head1 SYNOPSIS

 use DeltaX::Database;
 use DeltaX::Session;

 my $db = new DeltaX::Database(...);
 my $sess = new DeltaX::Session(db=>$db, table_name=>'my_sessions');

 my $sid = '12345';    # Session ID
 $sess->put($sid, key1=>'data1', key2=>'data2');

 if (!$sess->exist($sid)) { 
  # some error
 }
 
 my %data = $sess->get($sid);

=head1 DESCRIPTION

This module is prepared for session management (especially for masser
applications). It can store session information in database table (preffered),
shared memory or file (both in practise untested).
Session is identified by SID - Session IDentification - some unique identifier
composed from a-z, A-Z and 0-9 characters (for example md5_hex from Digest::MD5
is good for creating it).
If you use database table, you must create table with this structure:

 create table <name_as_you_want> (
  sid    varchar(32) not null,              -- according to SID you will use
  sdata  varchar(2000),                     -- as data you will store
  ts     timestamp                          -- date & time
  primary key (sid)
 );

If you use shared memory, you must have IPC::SharedCache installed. WARNING: Not
fully implemented.

If you use file, you must have module for selected storage type installed
(default is GDBM_File).

There are no functions which allow you to modify or delete SID (because of
performance issues).

=head1 FUNCTIONS

=head2 new()

Constructor. It uses parameters in key => value form:

=over

=item db

Reference to initialized DeltaX::Database. If set, session data will be stored
in this database.

=item table_name

If you are using database storage, this is a table name which will hold data
(default is 'sessions').

=item shm_key

Shared memory key (up to 4 characters - see IPC::SharedCache). If set, session
data will be stored in shared memory with this key.

=item shm_segment

Shared memory segment size (only valid if shm_key set) - see IPC::SharedCache
for explanation. Default is 10000 bytes.

=item shm_max

Maximum shared memory size (only valid if shm_key set) - see IPC::SharedCache
for explanation. Default is 1000000 bytes.

=item shm_timeout

Timeout in seconds, after which will be record in cache invalidated (see
IPC::SharedCache, validate_callback). Default is 300 seconds.

=item file

Filename of file in which session data will be stored.

=item db_file

Database file type to store session data, default is GDBM_File. Appropriate
module must be installed.

=back

=head2 put()

This function allows you to put some data linked to given SID. The first
parameter is SID, other parameters are in key => value form. Returned values:

=over

=item -1 - no SID given

=item -2 - SID already exists

=item -3 - parameters are not in key => value form

=item -5 - database error while inserting new data

=item 1  - ok

=back

=head2 exist()

Tests if given SID exists in storage, only one required parameter is SID.
Returns true if SID exists, otherwise returns false (0).

=head2 get()

Returns hash with values assigned to given SID (first and required parameter).
Returns undef in case of error.

=head2 free()

Frees resources used by module (especially closes opened statements if using
database).

=cut
