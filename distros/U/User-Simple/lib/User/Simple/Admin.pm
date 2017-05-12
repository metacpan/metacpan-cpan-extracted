use warnings;
use strict;

package User::Simple::Admin;

=encoding UTF-8

=head1 NAME

User::Simple::Admin - User::Simple user administration

=head1 SYNOPSIS

  $ua = User::Simple::Admin->new($db, $user_table);

  $ua = User::Simple::Admin->create_rdbms_db_structure($db, $user_table,
      [$extra_sql]);
  $ua = User::Simple::Admin->create_plain_db_structure($db, $user_table,
      [$extra_sql]);
  $ok = User::Simple::Admin->has_db_structure($db, $user_table);

  %users = $ua->dump_users;

  $id = $ua->id($login);
  $login = $ua->login($id);

  $otherattrib = $user->otherattrib($id);

  $ok = $usr->set_login($id, $login);
  $ok = $usr->set_passwd($id, $passwd);
  $ok = $usr->set_otherattrib($id, $value);
  $ok = $usr->clear_session($id);

  $id = $ua->new_user(login => $login, passwd => $passwd, 
        [otherattribute => $otherattribute]);

  $ok = $ua->remove_user($id);

=head1 DESCRIPTION

User::Simple::Admin manages the administrative part of the User::Simple
modules - Please check L<User::Simple> for a general overview of these modules
and an explanation on what-goes-where.

User::Simple::Admin works as a regular administrator would: The module should
be instantiated only once for all of your users' administration, if possible,
and not instantiated once for each user (in contraposition to L<User::Simple>,
as it works from each of the users' perspective in independent instantiations).

Note also that User::Simple::Admin does b<not> perform the administrative user
checks - It is meant to be integrated to your system, and it is your system 
which should carry out all of the needed authentication checks.

=head2 CONSTRUCTOR

Administrative actions for User::Simple modules are handled through this
Admin object. To instantiate it:

  $ua = User::Simple::Admin->new($db, $user_table);

$db is an open connection to the database where the user data is stored.

$user_table is the name of the table that holds the users' data.

If we do not yet have the needed DB structure to store the user information,
we can use this class method as a constructor as well:

  $ua = User::Simple::Admin->create_rdbms_db_structure($db, $user_table,
      [$extra_sql]);

  $ua = User::Simple::Admin->create_plain_db_structure($db, $user_table,
      [$extra_sql]);

The first one should be used if your DBI handle ($db) points to a real RDBMS,
such as PostgreSQL or MySQL. In case you are using a file-based DBD (such as
DBD::XBase, DBD::DBM, DBD::CVS or any other which does not use a real RDBMS
for storage), use C<User::Simple::Admin-E<gt>create_plain_db_structure>
instead. What is the difference? In the first case, we will create a table
that has internal consistency checks - Some fields are declared NOT NULL, some
fields are declared UNIQUE, and the user ID is used as a PRIMARY KEY. This 
cannot, of course, be achieved using file-based structures, so the integrity
can only be maintained from within our scripts.

This module does not provide the functionality to modify the created tables
by adding columns to it, although methods do exist to access and modify the
values stored in those columns (see the L<CREATING, QUERYING AND MODIFYING
USERS> section below), as many DBDs do not implement the ALTER TABLE SQL 
commands. It does, however, allow you to specify extra fields in the tables at
creation time - If you specify a third extra parameter, it will be included as 
part of the table creation - i.e., you can create a User::Simple table with
fields for the user's first and family names and a UNIQUE constraint over
them this way:

  $ua = User::Simple::Admin->create_rdbms_db_structure($db, $user_table,
      'firstname varchar(30) NOT NULL, famname varchar(30) NOT NULL,
       UNIQUE (firstname,famname)');

Keep in mind that the internal fields are C<id>, C<login>, C<passwd>, 
C<session> and C<session_exp>. Don't mess with them ;-) Avoid adding any fields
starting with C<set_> or called as any method defined here, as they will 
become unreachable. And, of course, keep in mind what SQL construct does your 
DBD support.

If you add any fields with names starting with C<adm_>, they will be visible 
but not modifiable from within L<User::Simple> - You will only be able to
modify them from L<User::Simple::Admin>.

=head2 QUERYING FOR DATABASE READINESS

In order to check if the database is ready to be used by this module with the
specified table name, use the C<has_db_structure> class method:

  $ok = User::Simple::Admin->has_db_structure($db, $user_table);  

=head2 RETRIEVING THE SET OF USERS

  %users = $ua->dump_users;

Will return a hash with the data regarding the registered users with all of the
existing DB fields, in the following form:

  ( $id1 => { login=>$login1, firstname=>$firstname1, famname=>$famname1 },
    $id2 => { login=>$login2, firstname=>$firstname2, famname=>$famname2 },
    (...) )

Of course, with the appropriate attributes. The internal attributes C<id>, 
C<session> and C<session_exp> will not be included in the resulting hashes (you
have the C<id> as the hash keys).

=head2 CREATING, QUERYING AND MODIFYING USERS

  $id = $ua->new_user(login => $login, passwd => $passwd, 
        [otherattribute => $otherattribute]);

Creates a new user with the specified data. Returns the new user's ID. Only
the login is mandatory (as it uniquely identifies the user), unless you have
specified extra NOT NULL fields or constraints in the DB. If no password is 
supplied, the account will be created, but no login will be allowed until one 
is supplied.

  $ok = $ua->remove_user($id);

Removes the user specified by the ID.

  $id = $ua->id($login);
  $login = $ua->login($id);

  $otherattrib = $user->otherattrib($id);

Get the value of each of the mentioned attributes. Note that in order to get
the ID you can supply the login, every other method answers only to the ID. In
case you have the login and want to get the firstname, you can use 
C<$ua->firstname($ua->id($login));>

Of course, beware: if you request for a field which does not exist in your
table, User::Simple will raise an  error and die just as if an unknown method 
had been called.

  $ok = $usr->set_login($id, $login);
  $ok = $usr->set_passwd($id, $passwd);

Modifies the requested attribute of the specified user, setting it to the new 
value. Except for the login, they can all be set to null values - If the 
password is set to a null or empty value, the account will be locked (that is, 
no password will be accepted). The internal attributes C<id>, C<session> and 
C<session_exp> cannot be directly modified (you have the C<id> as the hash 
keys).

Just as with the accessors, if you have extra columns, you can modify them the
same way:

  $ok = $usr->set_otherattrib($id, $value);

i.e.

  $ok = $usr->set_name($id, $name);

=head2 SESSIONS

  $ok = $usr->clear_session($id);

Removes the session which the current user had open, if any.

Note that you cannot create a new session through this module - The only way of
creating a session is through the C<ck_login> method of L<User::Simple>.

=head1 DEPENDS ON

L<Digest::MD5>

=head1 SEE ALSO

L<User::Simple> for the regular user authentication routines (that is, to
use the functionality this module adimisters)

=head1 AUTHOR

Gunnar Wolf <gwolf@gwolf.org>

=head1 COPYRIGHT

Copyright 2005-2009 Gunnar Wolf / Instituto de Investigaciones
Económicas UNAM 

This module is Free Software; it can be redistributed under the same
terms as Perl.

=cut

use Carp;
use Digest::MD5 qw(md5_hex);
use UNIVERSAL qw(isa);
our $AUTOLOAD;

######################################################################
# Constructor/destructor

sub new {
    my ($self, $class, $db, $table);
    $class = shift;
    $db = shift;
    $table = shift;

    # Verify we got the right arguments
    unless (isa($db, 'DBI::db')) {
	carp "First argument must be a DBI connection";
	return undef;
    }

    # In order to check if the table exists, check if it consists only of
    # valid characters and query for a random user
    unless ($table =~ /^[\w\_]+$/) {
	carp "Invalid table name $table";
	return undef;
    }
    unless ($class->has_db_structure($db, $table)) {
	carp "Table $table does not exist or has wrong structure";
	carp "Use $class->create_db_structure first.";
	return undef;
    }

    $self = { db => $db, tbl => $table };

    bless $self, $class;
    return $self;
}

# As we are using autoload, better explicitly leave this as an empty sub
sub DESTROY {}

######################################################################
# Creating the needed structure

sub create_rdbms_db_structure {
    my ($class, $db, $table, $extra_sql, $sql, $sth);
    $class = shift;
    $db = shift;
    $table = shift;
    $extra_sql = shift || ''; # Avoid warnings on undef

    # Remember some DBD backends don't implement 'serial' - Use 'integer' and
    # some logic on our side instead
    $sql = sprintf('CREATE TABLE %s (
            id serial PRIMARY KEY, 
            login varchar(100) NOT NULL UNIQUE,
            passwd char(32),
            session char(32) UNIQUE,
            session_exp varchar(20)
            %s)', $table, $extra_sql ? ", $extra_sql" : '');

    unless ($sth = $db->prepare($sql) and $sth->execute) {
	carp "Could not create database structure using table $table";
	return undef;
    }

    return $class->new($db, $table);
}

sub create_plain_db_structure {
    my ($class, $db, $table, $extra_sql, $sql, $sth);
    $class = shift;
    $db = shift;
    $table = shift;
    $extra_sql = shift || ''; # Avoid warnings on undef

    # Remember some DBD backends don't implement 'serial' - Use 'integer' and
    # some logic on our side instead
    $sql = sprintf('CREATE TABLE %s (
            id integer, 
            login varchar(100),
            passwd char(32),
            session char(32),
            session_exp varchar(20)
            %s)', $table, $extra_sql  ? ", $extra_sql" : '');

    unless ($sth = $db->prepare($sql) and $sth->execute) {
	carp "Could not create database structure using table $table";
	return undef;
    }

    return $class->new($db, $table);
}

sub has_db_structure {
    my ($class, $db, $table, $sth);
    $class = shift;
    $db = shift;
    $table = shift;

    # We check for the DB structure by querying for any given row. 
    # Yes, this method can fail if the needed fields exist but have the wrong
    # data, if the ID is not linked to a trigger and a sequence, and so on...
    # But usually, this check will be enough just to determine if we have the
    # structure ready.
    return 1 if ($sth=$db->prepare("SELECT id, login, passwd, session, 
        session_exp FROM $table") and $sth->execute);
    return 0;
}

######################################################################
# Retrieving information

sub dump_users { 
    my ($self, $order, $sth, %users);
    $self = shift;

    unless ($sth = $self->{db}->prepare("SELECT * FROM $self->{tbl}") 
	    and $sth->execute) {
	carp 'Could not query for the user list';
	return undef;
    }
    $sth->execute;


    # Keep to myself the internal fields, translate the fieldnames to lowercase
    while (my $row = $sth->fetchrow_hashref) {
	for my $in_field (keys %$row) {
	    my ($id);
	    # Some DBDs are case-insensitive towards Perl (we can query/modify 
	    # the columns case-insensitively), but internally are case
	    # sensitive. Gah, we work around that to provide the much more 
	    # common lowercase fields... This might still have some problems
	    # attached, please tell me if it breaks for you.
	    for my $case (qw(id ID Id iD)) {
		if (exists $row->{$case}) {
		    $id = $row->{$case};
		    last;
		}
	    }
	    carp "Did not find an ID field - Cannot continue" unless $id;
	    my $out_field = lc($in_field);
	    next if $out_field =~ /^(?:id|session|session_exp)$/;

	    $users{$id}{$out_field} = $row->{$in_field};
	}
    }
    return %users;
}

sub id { 
    my ($self, $login, $sth, $id);
    $self = shift;
    $login = shift;

    $sth = $self->{db}->prepare("SELECT id FROM $self->{tbl} WHERE login = ?");
    $sth->execute($login);

    ($id) = $sth->fetchrow_array;

    return $id;
}

sub login {
    my ($self, $id);
    $self = shift;
    $id = shift;
    return undef unless $id;
    return $self->_get_field($id, 'login'); 
}

######################################################################
# Modifying information

# We need only the mutators for the special case fields - Handle everything
# else via AUTOLOAD
sub set_login { 
    my ($self, $id, $new, $sth, $ret, $used);
    $self = shift;
    $id = shift;
    $new = shift;

    return undef unless $id;

    # Setting the login to the current login? Noop doomed to fail, make it look
    # as a success
    $used = $self->id($new);
    return 1 if $used and $used == $self->id($self->login($id));

    if ($used) {
	carp "The requested login is already used (ID $used).";
	return undef;
    }

    return $self->_set_field($id, 'login', $new);
}

sub set_passwd { 
    my ($self, $id, $new, $crypted, $sth);
    $self = shift;
    $id = shift;
    $new = shift;
    return undef unless $id;

    # No password was supplied? Prevent anybody from logging in with a blank
    # password (nothing will get a MD5 equal to this string).
    if ($new) {
	$crypted = md5_hex($new, $id);
    } else {
	$crypted = '-!- Disabled -!-';
    }

    return $self->_set_field($id, 'passwd', $crypted);
}

sub clear_session {
    my ($self, $id);
    $self = shift;
    $id = shift;
    return undef unless $id;
    return ($self->_set_field($id,'session','') && 
	    $self->_set_field($id, 'sesson_exp', ''));
}

# Other attributes will be retreived via AUTOLOAD
sub AUTOLOAD {
    my ($self, $id, $new, $name, $myclass, $set, $field);
    $self = shift;
    $id = shift;
    $new = shift;

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

    return undef unless $id;

    # Do we know how to handle the request?
    if ($name =~ /^set_(.+)$/) {
	$set = 1;
	$field = $1;
    } else {
	$field = $name;
    }

    if ($set) {
	if ($field =~ /^(id|session|sesion_exp)$/) {
	    die "Attempt to modify internal field $field";
	}

	return $self->_set_field($id, $field, $new);

    } 
    return $self->_get_field($id, $field);
}

######################################################################
# User creation and removal

sub new_user { 
    my ($self, %param, $id, $db, $orig_state, $has_transact);
    $self = shift;
    %param = @_;

    # We will use the database handler over and over - Get a shortcut.
    $db = $self->{db};

    # If available, we will do all this work inside a transaction. Sadly, not
    # every DBD provides such a facility - By trying to begin_work and
    # then commit on an empty transaction, we can check if this DBD does 
    # provide it. 
    eval { 
	$db->begin_work; 
	$db->commit;
    };
    $has_transact = $@ ? 0 : 1;

    # We require a login - Check if we got one.
    unless ($param{login}) {
	carp 'A login is required for user creation';
	return undef;
    }

    # Check first if we have a registered user with this same login
    if (my $id = $self->id($param{login})) {
	carp "There is already a user registered with desired login (ID $id)";
	return undef;
    }

    $orig_state = $db->{RaiseError};
    eval {
	my ($sth);
	$db->begin_work if $has_transact;
	$db->{RaiseError} = 1;

	# Not all DBD backends implement the 'serial' datatype - We use a
	# simple integer, and we just move the 'serial' logic to this point,
	# the only new user creation area. 
	# Yes, this could lead to a race condition and to the attempt to insert
	# two users with the same ID - We have, however, the column as a 
	# 'primary key'. Any DBD implementing unicity will correctly fail. 
	# And... Well, nobody expects too high trust from a DBD backend which
	# does not implement unicity, right? :)
	$sth = $db->prepare("SELECT id FROM $self->{tbl} ORDER BY
            id desc");
	$sth->execute;
	($id) = $sth->fetchrow_array;
	$id++;

	$sth = $db->prepare("INSERT INTO $self->{tbl} (id, login) 
            VALUES (?, ?)");
	$sth->execute($id, $param{login});

	# But just to be sure, lets retreive the ID from the login.
	$id = $self->id($param{login});

	$self->set_passwd($id, $param{passwd});

	# Set all the other fields we got as parameters
	for my $field (keys %param) {
	    next if $field =~ /^(login|passwd)$/; # Already handled.
	    $self->_set_field($id, $field, $param{$field});
	}

	$db->commit if $has_transact;
	$db->{RaiseError} = $orig_state;
    };
    if ($@) {
	if ($has_transact) {
	    $db->rollback;
	} else {
	    carp 'User creation was not successful. This DBD does not support'.
		' transactions - You might have a half-created user!';
	}
	$db->{RaiseError} = $orig_state;
	carp "Could not create specified user";
	return undef;
    }
    return $id;
}

sub remove_user { 
    my ($self, $id, $sth);
    $self = shift;
    $id = shift;

    unless ($sth = $self->{db}->prepare("DELETE FROM $self->{tbl} WHERE id=?")
	    and $sth->execute($id)) {
	carp "Could not remove user $id";
	return undef;
    }

    return 1;
}

######################################################################
# Private methods and functions

sub _get_field {
    my ($self, $id, $field, $sth);
    $self = shift;
    $id = shift;
    $field = shift;

    unless ($self->_is_valid_field($field)) {
	carp "Invalid field: $field";
	return undef;
    }

    $sth=$self->{db}->prepare("SELECT $field FROM $self->{tbl} WHERE id = ?");
    $sth->execute($id);

    return $sth->fetchrow_array;
}

sub _set_field { 
    my ($self, $id, $field, $val, $sth);
    $self = shift;
    $id = shift;
    $field = shift;
    $val = shift;

    unless ($self->_is_valid_field($field) or $field eq 'passwd') {
	carp "Invalid field: $field";
	return undef;
    }

    unless ($sth = $self->{db}->prepare("UPDATE $self->{tbl} SET $field = ? 
            WHERE id = ?") and $sth->execute($val, $id)) {
	carp "Could not set $field to $val for user $id";
	return undef;
    }

    return 1;
}

sub _is_valid_field {
    my ($self, $field, $raise_error);
    $self = shift;
    $field = shift;

    # If it is one of our internal fields, return successfully right away
    return 1 if $field =~ /^(login)$/;

    # Explicitly disallow direct passwd handling
    return 0 if $field eq 'passwd';

    # Allow only valid fields - alphanumeric characters or underscores
    $field =~ /^[\w\d\_]+$/ or return 0;

    $raise_error = $self->{db}{RaiseError};

    eval {
	my $sth;
	$self->{db}{RaiseError} = 1;
	$sth = $self->{db}->prepare("SELECT $field FROM $self->{tbl}");
	$sth->execute;
    };
    if ($@) {
	# If an error was raised, the field does not exist - Return 0
	# Restore the RaiseError

	$self->{db}{RaiseError} = $raise_error;
	return 0;
    }

    # The field is valid! Return 1.
    # Restore the RaiseError
    $self->{db}{RaiseError} = $raise_error;

    return 1;
}

1;
