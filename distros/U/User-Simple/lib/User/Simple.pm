use warnings;
use strict;

package User::Simple;

=encoding UTF-8

=head1 NAME

User::Simple - Simple user sessions management

=head1 SYNOPSIS

  $usr = User::Simple->new(db => $db,
                           [tbl => $user_table],
                           [durat => $duration],
                           [debug => $debug]);

  $ok = $usr->ck_session($session);
  $ok = $usr->ck_login($login, $passwd, [$no_sess]);
  $ok = $usr->set_passwd($new_pass);
  $usr->end_session;

  $id = $usr->id;
  $session = $usr->session;

  $otherattrib = $user->otherattrib
  $ok = $user->set_otherattrib($value);

=head1 DESCRIPTION

User::Simple provides a very simple framework for validating users,
managing their sessions and storing a minimal set of information (this
is, a meaningful user login/password pair, and privilege level) via a database,
while providing a transparent way to access any other attributes you might
define. The sessions can be used as identifiers for i.e. cookies on a Web 
system. The passwords are stored as MD5 hashes (this means, the password is 
never stored in clear text).

User::Simple was originally developed with a PostgreSQL database in
mind, but should work with any real DBMS. Sadly, this rules out DBD::CSV,
DBD::XBase, DBD::Excel and many other implementations based on SQL::Statement -
The user table requires the driver to implement primary keys and 
NOT NULL/UNIQUE constraints. 

The functionality is split into two modules, L<User::Simple> and 
L<User::Simple::Admin>. This module provides the functionality your system
will need for any interaction started by the user - Authentication, session
management, querying the user's data, changing the password and changing any
attributes you define not beginning with C<adm_>. Note that you cannot directly
modify a user's login, session or session expiry from within this module - Just
as a general principle, avoid changing logins. If you absolutely must, use 
User::Simple::Admin instead ;-)

=head2 CONSTRUCTOR

In order to create a User::Simple object, call the new argument with an
active DBI (database connection) object as its only argument:

  $usr = User::Simple->new(db => $db, [tbl => $table], [durat => $duration],
                           [debug => $debug]);

Of course, the database must have the right structure in it - please check
L<User::Simple::Admin> for more information.

The C<tbl> parameter is the name of the table where the user information is 
stored. If not specified, it defaults to 'user_simple'.

C<durat> is the number of minutes a user's session should last. Its default is
of 30 minutes.

C<debug> is the verbosity level of the debugging messages - The default is 2, 
it accepts integers between 0 and 5 (higher means more messages). Messages of 
high relevance (i.e. the database failing to reflect any changes we request it
to make) are shown if debug is >= 1, regular failure messages are shown if 
debug >= 3, absolutely everything is shown if debug == 5. Be warned that when
debug is set to 5, information such as cleartext passwords will be logged as 
well!

=head2 SESSION CREATION/DELETION

Once the object is created, we can ask it to verify that a given user is
valid, either by checking against a session string or against a login/password
pair:

  $ok = $usr->ck_session($session);
  $ok = $usr->ck_login($login, $passwd, [$no_sess]);

The optional $no_sess argument should be used if we do not want to modify the
current session (or to create a new session), we want only to verify the
password matches (i.e. when asking for the current password as a confirmation 
in order to change a user's password). It will almost always be left false.

To end a session:

  $ok = $usr->end_session;

To verify whether we have successfully validated a user:

  $ok = $usr->is_valid;

=head2 QUERYING THE CURRENT USER'S DATA

To check the user's core attributes (login and ID):

  $login = $usr->login;
  $id = $usr->id;

You might add extra columns to the User::Simple table in your database - You
will still be able to query for them in the same way:

  $otherattrib = $user->otherattrib;

i.e.:

  $name = $user->name
  $login = $usr->login;

Note that 'name' and 'level' were core attributes until User::Simple version 
1.0 - In order to keep User::Simple as simple and extensible as possible, they
became extended attributes. You should not have to modify your code using 
C<User::Simple> anyway, as changes are transparent. Some minor API changes do 
happen in C<User::Simple::Admin>, though. 

Extended attributes are not checked in any way by User::Simple, they are just 
stored in the database just as they are received - Some DBDs might not even
verify they are of the correct data type. As always, if you want to ensure
consistence, use a real RDBMS.

Of course, beware: if the field does not exist, User::Simple will raise an 
error and die just as if an unknown method had been called.

To change the user's password:

  $ok = $usr->set_passwd($new_pass);

Note that an empty password will not be accepted.

To change any attribute defined by you and not labeled as for administrative
use (this is, its name does not start with C<adm_>):

  $ok = $usr->set_otherattrib($new_value);

=head1 DEPENDS ON

L<Date::Calc>

L<Digest::MD5>

L<DBI> (and a suitable L<DBD> backend)

=head1 SEE ALSO

L<User::Simple::Admin> for administrative routines

=head1 AUTHOR

Gunnar Wolf <gwolf@gwolf.org>

=head1 COPYRIGHT

Copyright 2005-2009 Gunnar Wolf / Instituto de Investigaciones
Económicas UNAM

This module is Free Software; it can be redistributed under the same
terms as Perl.

=cut

use Carp;
use Date::Calc qw(Today_and_Now Add_Delta_DHMS Delta_DHMS);
use Digest::MD5 qw(md5_hex);
use UNIVERSAL qw(isa);

our $AUTOLOAD;
our $VERSION = '1.45';

######################################################################
# Constructor/destructor

sub new {
    my ($class, $self, %init, $sth);
    $class = shift;
    %init = @_;

    # Verify we got the right arguments
    for my $key (keys %init) {
	next if $key =~ /^(db|debug|durat|tbl|adm_level)$/;
	carp "Unknown argument received: $key";
	return undef;
    }

    if (defined($init{adm_level})) {
	carp "adm_level is deprecated and will be dropped in future releases";
    }

    # Default values
    $init{tbl} = 'user_simple' unless defined $init{tbl};
    $init{durat} = 30 unless defined $init{durat};
    $init{debug} = 2 unless defined $init{debug};
    $init{adm_level} = 1 unless defined $init{adm_level};

    unless (defined($init{db}) and isa($init{db}, 'DBI::db')) {
	carp "Mandatory db argument must be a valid (DBI) database handle";
	return undef;
    }

    # In order to check if the table exists, check if it consists only of
    # valid characters and query for a random user
    unless ($init{tbl} =~ /^[\w\_]+$/) {
	carp "Invalid table name $init{tbl}";
	return undef;
    }
    unless ($sth=$init{db}->prepare("SELECT id, login FROM $init{tbl}") and
	    $sth->execute) {
	carp "Table $init{tbl} does not exist or has wrong structure";
	return undef;
    }

    unless ($init{durat} =~ /^\d+$/) {
	carp "Duration must be set to a positive integer";
	return undef;
    }

    unless ($init{debug} =~ /^\d+$/ and $init{debug} >= 0 and
	    $init{debug} <= 5) {
	carp "Debug level must be an integer between 0 and 5";
	return undef;
    }

    $self = { %init };
    bless $self, $class;

    $self->_debug(5, "$class object successfully created");

    return $self;
}

# As we are using autoload, better explicitly leave this as an empty sub
sub DESTROY {}

######################################################################
# User validation

sub ck_session {
    my ($self, $sess, $sth, $id, $exp);
    $self = shift;
    $sess = shift;

    $self->_debug(5, "Checking session $sess");

    # Before checking anything, make sure we don't retain an expired 
    # authorization
    $self->{id} = undef;

    unless ($sth = $self->{db}->prepare("SELECT id, session_exp 
            FROM $self->{tbl} WHERE session = ?") and $sth->execute($sess) 
	    and ($id, $exp) = $sth->fetchrow_array) {
	# Session does not exist
	$self->_debug(3,"Inexistent session");
	return undef;
    }

    unless ($self->_ck_session_expiry($exp)) {
	$self->_debug(3,"Expired session");
	return undef;
    }

    $self->{id} = $id;
    $self->_refresh_session;
    $self->_debug(5,"Session successfully checked for ID $id");

    return $self->id;
}

sub ck_login {
    my ($self, $login, $pass, $no_sess, $crypted, $sth, $id, $db_pass);
    $self = shift;
    $login = shift;
    $pass = shift;
    $no_sess = shift;
 
    $self->_debug(5, "Verifying login: $login/$pass");

    # Before checking anything, make sure we don't retain an expired 
    # authorization
    $self->{id} = undef;

    # Is this login/password valid?
    unless ($sth = $self->{db}->prepare("SELECT id, passwd FROM $self->{tbl}
            WHERE login = ?") and $sth->execute($login) and
	    ($id, $db_pass) = $sth->fetchrow_array) {
	$self->_debug(3,"Invalid login $login");
	return undef;
    }

    $crypted = md5_hex($pass, $id);
    if ($crypted ne $db_pass) {
	$self->_debug(3,"Invalid password ($crypted)");
	return undef;
    }

    $self->_debug(5, "login/password verified successfully");

    # User authenticated. Now create the session - Use a MD5 hash of the
    # current timestamp. Skip this step if $no_sess is true.
    if ($no_sess) {
	$self->_debug(3, "Not touching session");

    } else {
	my $salt = _session_salt();
	unless ($sth = $self->{db}->prepare("UPDATE $self->{tbl} SET 
                session = ? WHERE id = ?") and 
		$sth->execute(md5_hex(join('-', $salt, Today_and_Now)), $id)) {
	    $self->_debug(1,'Could not create user session');
	    return undef;
	}
    }

    # Populate the object with the user's data
    $self->{id} = $id;
    $self->_refresh_session;
    $self->_debug(5,"Login successfully checked for ID $id");
    return $self->id;
}

sub end_session {
    my ($self, $sth);
    $self = shift;
    $self->_debug(5, 'Closing session for ' .$self->id);

    return undef unless ($self->id);

    $sth = $self->{db}->prepare("UPDATE $self->{tbl} SET session = NULL,
        session_exp = NULL WHERE id = ?");
    $sth->execute($self->id);

    $self->{id} = undef;

    return 1;
}

######################################################################
# Accessors, mutators

sub is_valid { 
    my $self = shift; 
    return $self->id ? 1 : 0; 
}

sub id { 
    my $self = shift; 
    return $self->{id}; 
}

sub set_passwd {
    my ($self, $pass, $crypted, $sth);
    $self = shift;
    $pass = shift;

    return undef unless ($self->id and $pass);

    $crypted = md5_hex($pass, $self->id);

    $self->_debug(5, sprintf('Setting %s\'s password to %s (%s)', 
			     $self->login, $pass, $crypted));

    unless ($sth = $self->{db}->prepare("UPDATE $self->{tbl} SET passwd = ? 
            WHERE id = ?") and 
	    $sth->execute($crypted, $self->id)) {
	$self->_debug(1,"Could not set the requested password");
	return undef;
    }

    return 1;
}

# Other attributes are retreived via AUTOLOAD
sub AUTOLOAD {
    my ($self, $newval, $name, $myclass, $set, $raise_error, $value, $valid);
    $self = shift;
    $newval = shift;
    $name = $AUTOLOAD;

    # Autoload gives us the fully qualified method name being called - Get our
    # class name and strip it off $name. And why the negated index? Just to be
    # sure we don't discard what we don't want to - Either it is at the
    # beginning, or we don't discard a thing
    $name = $AUTOLOAD;
    $myclass = ref($self);
    if (!index($name, $myclass)) {
	# Substitute in $name from the beginning (0) to the length of the class
	# name plus two (that is, strip the '::') with nothing.
	substr($name,0,length($myclass)+2,'');
    }

    # Is the user requesting a value or modifying it?
    $set = 0;
    if ($name =~ /^set_(.+)$/) {
	$set = 1;
	$name = $1;
    }

    $self->_debug(5, sprintf('%s for autoloaded field "%s"', 
			     ($set ? 'Modifying' : 'Querying'), $name));

    # We require the name to consist only of alphanumeric characters or 
    # underscores
    $name =~ /^[\w\d\_]+$/ or croak "Invalid field name '$name'";

    # Store the RaiseError, as we don't want to change state outside our
    # scope
    $raise_error = $self->{db}{RaiseError};

    # In order to check if $name is a valid field in the DB, query for it -
    # but do it inside an eval, as we might get killed!
    eval {
	my ($sth);
	$self->{db}{RaiseError} = 1;

	if ($set) {
	    if ($name =~ /^(session|login|adm_)/) {
		# The field is valid, the access is not - $valid will be used
		# to decide how to die.
		$valid = 1;
		die "Invalid field $name";
	    }

	    $sth = $self->{db}->prepare("UPDATE $self->{tbl} SET $name = ?
                WHERE id = ?");
	    $sth->execute($newval, $self->id);

	    # We should return success/failure - This is a good and easy way to
	    # check - although, yes, it's a second call to AUTOLOAD.
	    $value = ($self->$name eq $newval) ? 1 : 0;
	} else {
	    $sth = $self->{db}->prepare("SELECT $name FROM $self->{tbl} WHERE
                id = ?");
	    $sth->execute($self->id);
	    ($value) = $sth->fetchrow_array;
	}
    };
    if ($@) {
	# Yes, we will croak and die - But this call might be also trapped.
	# Restore the RaiseError anyway.
	$self->{db}{RaiseError} = $raise_error;
	if ($valid) {
	    croak "Access to '$name' restricted";
	} 
	croak "Field '$name' does not exist in the User::Simple table!";
    }

    # Restore the RaiseError
    $self->{db}{RaiseError} = $raise_error;

    return $value;
}

######################################################################
# Private methods

# Warns the message received as the second parameter if the debug level is
# >= the first parameter
sub _debug {
    my ($self, $level, $text);
    $self = shift;
    $level = shift;
    $text = shift;

    carp $text if $self->{debug} >= $level;
    return 1;
}

# Checks if a session's expiration time is still in the future.
# Receives as its only parameter the expiration time as a string as stored in
# the database (this is, year-month-day-hour-minute-second). Returns 1 if
# the session is still valid, 0 if it has expired.
sub _ck_session_expiry {
    my ($self, $exp, @exp, @now, @diff, $diff);
    $self = shift;
    $exp = shift;

    return undef unless $exp;
    @exp = split (/-/, $exp);
    @now = Today_and_Now();

    if (scalar @exp != 6) {
	$self->_debug(1,"Invalid session format");
	return undef;
    }

    @diff = Delta_DHMS(@now, @exp);
    $diff = ((shift(@diff) * 24 + shift(@diff)) * 60 + 
	     shift(@diff)) * 60 + shift(@diff);

    return ($diff > 0) ? 1 : 0;
}

sub _refresh_session {
    my ($self, $sth, $new_exp);
    $self = shift;

    # Do we have an identified user?
    unless ($self->id) {
	$self->_debug(3,"Cannot refresh session: User not yet identified");
	return undef;
    }

    # The new expiration time is set to the current timestamp plus 
    # $self->{durat} minutes
    $new_exp = join('-', Add_Delta_DHMS(Today_and_Now, 
					0, 0, $self->{durat}, 0));

    unless ($sth = $self->{db}->prepare("UPDATE $self->{tbl} SET 
            session_exp = ? WHERE id = ?") and
	    $sth->execute($new_exp, $self->id)) {
	$self->_debug(1,"Couldn't refresh session.");
	return undef;
    }
}

# Generates a random, printable (ASCII 46-126), 10 character long salt
# to mix in the session generation.
sub _session_salt {
    join("", map { chr(rand()*78 + 46) } (0..10))
}


1;
