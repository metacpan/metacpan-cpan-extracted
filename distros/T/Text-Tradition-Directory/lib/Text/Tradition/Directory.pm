package Text::Tradition::Directory;

use strict;
use warnings;
use Moose;
use DBI;
use Encode qw/ encode decode_utf8 /;
use KiokuDB::GC::Naive;
use KiokuDB::TypeMap;
use KiokuDB::TypeMap::Entry::Naive;
use Safe::Isa;
use Text::Tradition::Error;

## users
use KiokuX::User::Util qw(crypt_password);
use Text::Tradition::Store;
use Text::Tradition::User;
use Text::Tradition::TypeMap::Entry;

extends 'KiokuX::Model';

use vars qw/ $VERSION /;
$VERSION = "1.2";

=head1 NAME

Text::Tradition::Directory - a KiokuDB interface for storing and retrieving 
traditions and their owners

=head1 SYNOPSIS

  use Text::Tradition::Directory;
  my $d = Text::Tradition::Directory->new( 
    'dsn' => 'dbi:SQLite:mytraditions.db',
    'extra_args' => { 'create' => 1 },
  );
  
  my $tradition = Text::Tradition->new( @args );
  my $stemma = $tradition->add_stemma( dotfile => $dotfile ); # if Analysis module installed
  $d->save_tradition( $tradition );
  
  foreach my $id ( $d->traditions ) {
  	print $d->tradition( $id )->name;
  }

  ## Users:
  my $userstore = Text::Tradition::UserStore->new(dsn => 'dbi:SQLite:foo.db');
  my $newuser = $userstore->add_user({ username => 'fred',
                                       password => 'somepassword' });

  my $fetchuser = $userstore->find_user({ username => 'fred' });
  if($fetchuser->check_password('somepassword')) { 
     ## login user or .. whatever
  }

  my $user = $userstore->deactivate_user({ username => 'fred' });
  if(!$user->active) { 
    ## shouldnt be able to login etc
  }
    
=head1 DESCRIPTION

Text::Tradition::Directory is an interface for storing and retrieving text
traditions and all their data, including an associated stemma hypothesis
and a user who has ownership rights to the tradition data. It is an
instantiation of a KiokuDB::Model, storing traditions and associated
stemmas by UUID.

The Text::Tradition::Directory package also includes the
L<Text::Tradition::User> class for user objects, and the
L<Text::Tradition::Ownership> role which extends the Text::Tradition class
to handle user ownership.

=head1 ATTRIBUTES

=head2 MIN_PASS_LEN

Constant for the minimum password length when validating passwords,
defaults to "8".

=cut

has MIN_PASS_LEN => ( is => 'ro', isa => 'Num', default => sub { 8 } );

=head1 METHODS

=head2 new

Returns a Directory object. 

=head2 traditionlist

Returns a hashref mapping of ID => name for all traditions in the directory.

=head2 tradition( $id )

Returns the Text::Tradition object of the given ID.

=head2 save( $tradition )

Writes the given tradition to the database, returning its ID.

=head2 delete( $tradition )

Deletes the given tradition object from the database.
WARNING!! Garbage collection does not yet work. Use this sparingly.

=begin testing

use TryCatch;
use File::Temp;
use Safe::Isa;
use Text::Tradition;
use_ok 'Text::Tradition::Directory';

my $fh = File::Temp->new();
my $file = $fh->filename;
$fh->close;
my $dsn = "dbi:SQLite:dbname=$file";
my $uuid;
my $user = 'user@example.org';
my $t = Text::Tradition->new( 
	'name'  => 'inline', 
	'input' => 'Tabular',
	'file'  => 't/data/simple.txt',
	);
my $stemma_enabled = $t->can( 'add_stemma' );

{
	my $d = Text::Tradition::Directory->new( 'dsn' => $dsn,
		'extra_args' => { 'create' => 1 } );
	ok( $d->$_isa('Text::Tradition::Directory'), "Got directory object" );
	
	my $scope = $d->new_scope;
	$uuid = $d->save( $t );
	ok( $uuid, "Saved test tradition" );
	
	# Add a test user
	my $user = $d->add_user({ username => $user, password => 'UserPass' }); 
	$user->add_tradition( $t );
	$d->store( $user );
	is( $t->user, $user, "Assigned tradition to test user" );
	
	SKIP: {
		skip "Analysis package not installed", 5 unless $stemma_enabled;
		my $s = $t->add_stemma( dotfile => 't/data/simple.dot' );
		ok( $d->save( $t ), "Updated tradition with stemma" );
		is( $d->tradition( $uuid ), $t, "Correct tradition returned for id" );
		is( $d->tradition( $uuid )->stemma(0), $s, "...and it has the correct stemma" );
		try {
			$d->save( $s );
		} catch( Text::Tradition::Error $e ) {
			is( $e->ident, 'database error', "Got exception trying to save stemma directly" );
			like( $e->message, qr/Cannot directly save non-Tradition object/, 
				"Exception has correct message" );
		}
	}
}
my $nt = Text::Tradition->new(
	'name' => 'CX',
	'input' => 'CollateX',
	'file' => 't/data/Collatex-16.xml',
	);
ok( $nt->$_isa('Text::Tradition'), "Made new tradition" );

{
	my $f = Text::Tradition::Directory->new( 'dsn' => $dsn );
	my $scope = $f->new_scope;
	is( scalar $f->traditionlist, 1, "Directory index has our tradition" );
	my $nuuid = $f->save( $nt );
	ok( $nuuid, "Stored second tradition" );
	my @tlist = $f->traditionlist;
	is( scalar @tlist, 2, "Directory index has both traditions" );
	my $tf = $f->tradition( $uuid );
	my( $tlobj ) = grep { $_->{'id'} eq $uuid } @tlist;
	is( $tlobj->{'name'}, $tf->name, "Directory index has correct tradition name" );
	is( $tf->name, $t->name, "Retrieved the tradition from a new directory" );
	my $sid;
	SKIP: {
		skip "Analysis package not installed", 4 unless $stemma_enabled;
		$sid = $f->object_to_id( $tf->stemma(0) );
		try {
			$f->tradition( $sid );
		} catch( Text::Tradition::Error $e ) {
			is( $e->ident, 'database error', "Got exception trying to fetch stemma directly" );
			like( $e->message, qr/not a Text::Tradition/, "Exception has correct message" );
		}
		if( $ENV{TEST_DELETION} ) {
			try {
				$f->delete( $sid );
			} catch( Text::Tradition::Error $e ) {
				is( $e->ident, 'database error', "Got exception trying to delete stemma directly" );
				like( $e->message, qr/Cannot directly delete non-Tradition object/, 
					"Exception has correct message" );
			}
		}
	}
	
	SKIP: {
		skip "Set TEST_DELETION in env to test DB deletion functionality", 3
			unless $ENV{TEST_DELETION};
		$f->delete( $uuid );
		ok( !$f->exists( $uuid ), "Object is deleted from DB" );
		ok( !$f->exists( $sid ), "Object stemma also deleted from DB" ) if $stemma_enabled;
		is( scalar $f->traditionlist, 1, "Object is deleted from index" );
	}
}

{
	my $g = Text::Tradition::Directory->new( 'dsn' => $dsn );
	my $scope = $g->new_scope;
	SKIP: {
		skip "Set TEST_DELETION in env to test DB deletion functionality", 1
			unless $ENV{TEST_DELETION};
		is( scalar $g->traditionlist, 1, "Now one object in new directory index" );
	}
	my $ntobj = $g->tradition( 'CX' );
	my @w1 = sort { $a->sigil cmp $b->sigil } $ntobj->witnesses;
	my @w2 = sort{ $a->sigil cmp $b->sigil } $nt->witnesses;
	is_deeply( \@w1, \@w2, "Looked up remaining tradition by name" );
}

=end testing

=cut
use Text::Tradition::TypeMap::Entry;

has +typemap => (
  is      => 'rw',
  isa     => 'KiokuDB::TypeMap',
  default => sub {
    KiokuDB::TypeMap->new(
      isa_entries => {
	# now that we fall back to YAML deflation, all attributes of
	# Text::Tradition will be serialized to YAML as individual objects
	# Except if we declare a specific entry type here
        "Text::Tradition" =>
          KiokuDB::TypeMap::Entry::MOP->new(),
	# We need users to be naive entries so that they hold
	# references to the original tradition objects, not clones
        "Text::Tradition::User" =>
          KiokuDB::TypeMap::Entry::MOP->new(),
        "Text::Tradition::Collation" =>
          KiokuDB::TypeMap::Entry::MOP->new(),
        "Text::Tradition::Witness" =>
          KiokuDB::TypeMap::Entry::MOP->new(),
        "Graph" => Text::Tradition::TypeMap::Entry->new(),
        "Set::Scalar" => Text::Tradition::TypeMap::Entry->new(),
      }
    );
  },
);

has '_mysql_utf8_hack' => (
	is => 'ro',
	isa => 'Bool',
	default => undef,
);

# Push some columns into the extra_args
around BUILDARGS => sub {
	my $orig = shift;
	my $class = shift;
	my $args;
	if( @_ == 1 ) {
		$args = $_[0];
	} else {
		$args = { @_ };
	}
	my @column_args;
	if( $args->{'dsn'} =~ /^dbi:(\w+):/ ) { # We're using Backend::DBI
		my $dbtype = $1;
		@column_args = ( 'columns',
			[ 'name' => { 'data_type' => 'varchar', 'is_nullable' => 1 },
			  'public' => { 'data_type' => 'bool', 'is_nullable' => 1 } ] );
		if( $dbtype eq 'mysql' && 
			exists $args->{extra_args}->{dbi_attrs} &&
			$args->{extra_args}->{dbi_attrs}->{mysql_enable_utf8} ) {
			# There is a bad interaction with MySQL in utf-8 mode.
			# Work around it here.
			# TODO fix the underlying storage problem
			$args->{extra_args}->{dbi_attrs}->{mysql_enable_utf8} = undef;
			$args->{_mysql_utf8_hack} = 1;
		}
	}
	my $ea = $args->{'extra_args'};
	if( ref( $ea ) eq 'ARRAY' ) {
		push( @$ea, @column_args );
	} elsif( ref( $ea ) eq 'HASH' ) {
		$ea = { %$ea, @column_args };
	} else {
		$ea = { @column_args };
	}
	$args->{'extra_args'} = $ea;

	return $class->$orig( $args );
};

override _build_directory => sub {
  my($self) = @_;
  Text::Tradition::Store->connect(@{ $self->_connect_args },
    resolver_constructor => sub {
      my($class) = @_;
      $class->new({ typemap => $self->directory->merged_typemap,
                    fallback_entry => Text::Tradition::TypeMap::Entry->new() });
  });
};

## These checks don't cover store($id, $obj)
# before [ qw/ store update insert delete / ] => sub {
before [ qw/ delete / ] => sub {
	my $self = shift;
	my @nontrad;
	foreach my $obj ( @_ ) {
		if( ref( $obj ) && !$obj->$_isa( 'Text::Tradition' )
            && !$obj->$_isa('Text::Tradition::User') ) {
			# Is it an id => Tradition hash?
			if( ref( $obj ) eq 'HASH' && keys( %$obj ) == 1 ) {
				my( $k ) = keys %$obj;
				next if $obj->{$k}->$_isa('Text::Tradition');
			}
			push( @nontrad, $obj );
		}
	}
	if( @nontrad ) {
		throw( "Cannot directly save non-Tradition object of type "
			. ref( $nontrad[0] ) );
	}
};

# TODO Garbage collection doesn't work. Suck it up and live with the 
# inflated DB.
after delete => sub {
	my $self = shift;
	my $gc = KiokuDB::GC::Naive->new( backend => $self->directory->backend );
	$self->directory->backend->delete( $gc->garbage->members );
};

sub save {
	my $self = shift;
	return $self->store( @_ );
}

sub tradition {
	my( $self, $id ) = @_;
	my $obj = $self->lookup( $id );
	unless( $obj ) {
		# Try looking up by name.
		foreach my $item ( $self->traditionlist ) {
			if( $item->{'name'} eq $id ) {
				$obj = $self->lookup( $item->{'id'} );
				last;
			}
		}
	}
	if( $obj && !$obj->$_isa('Text::Tradition') ) {
		throw( "Retrieved object is a " . ref( $obj ) . ", not a Text::Tradition" );
	}
	return $obj;
}

sub traditionlist {
	my $self = shift;
    my ($user) = @_;

    return $self->user_traditionlist($user) if($user);
	return $self->_get_object_idlist( 'Text::Tradition' );
}

sub _get_object_idlist {
	my( $self, $objclass ) = @_;
	my @tlist;
	# If we are using DBI, we can do it the easy way; if not, the hard way.
	# Easy way still involves making a separate DBI connection. Ew.
	if( $self->dsn =~ /^dbi:(\w+):/ ) {
		my $dbtype = $1;
		my @connection = @{$self->directory->backend->connect_info};
		# Get rid of KiokuDB-specific arg
		pop @connection if scalar @connection > 4;
		$connection[3]->{'sqlite_unicode'} = 1 if $dbtype eq 'SQLite';
		$connection[3]->{'pg_enable_utf8'} = 1 if $dbtype eq 'Pg';
		my $dbh = DBI->connect( @connection );
		my $q = $dbh->prepare( 'SELECT id, name, public from entries WHERE class = "'
			. $objclass . '"' );
		$q->execute();
		while( my @row = $q->fetchrow_array ) {
			# Horrible horrible hack. Re-convert the name to UTF-8.
			if( $self->_mysql_utf8_hack ) {
				# Convert the chars into a raw bytestring.
				my $octets = encode( 'ISO-8859-1', $row[1] );
				$row[1] = decode_utf8( $octets );
			}
			push( @tlist, { 'id' => $row[0], 'name' => $row[1], 'public' => $row[2] } );
		}
	} else {
		$self->scan( sub { my $o = shift; 
						   push( @tlist, { 'id' => $self->object_to_id( $o ), 
										   'name' => $o->name,
										   'public' => $o->public } ) 
								if( ref $o eq $objclass ) } );
	}
	return @tlist;
}

sub throw {
	Text::Tradition::Error->throw( 
		'ident' => 'database error',
		'message' => $_[0],
		);
}


# has 'directory' => ( 
#     is => 'rw', 
#     isa => 'KiokuX::Model',
#     handles => []
#     );

## TODO: Some of these methods should probably optionally take $user objects
## instead of hashrefs.

## It also occurs to me that all these methods don't need to be named
## XX_user, but leaving that way for now incase we merge this code
## into ::Directory for one-store.

=head1 USER DIRECTORY METHODS

=head2 add_user( $userinfo )

Takes a hashref of C<username>, C<password>.

Create a new user object, store in the KiokuDB backend, and return it.

=cut

sub add_user {
    my ($self, $userinfo) = @_;

    my $username = $userinfo->{username};
    my $password = $userinfo->{password};
    my $role = $userinfo->{role} || 'user';

	throw( "No username given" ) unless $username;
	throw( "Invalid password - must be at least " . $self->MIN_PASS_LEN 
		. " characters long" )
		unless ( $self->validate_password($password) || $username =~ /^https?:/ );

    my $user = Text::Tradition::User->new(
        id => $username,
        password => ($password ? crypt_password($password) : ''),
        email => ($userinfo->{email} ? $userinfo->{email} : $username),
        role => $role,
    );

    $self->store($user->kiokudb_object_id, $user);

    return $user;
}

=head2 create_user( $userinfo )

Takes a hashref that can either be suitable for add_user (see above) or be
a hash of OpenID user information from Credential::OpenID.

=cut

sub create_user {
    my ($self, $userinfo) = @_;

    ## No username means probably an OpenID based user
    if(!exists $userinfo->{username}) {
        _extract_openid_data($userinfo);
    }

    return $self->add_user($userinfo);
}

## Not quite sure where this method should be.. Auth /
## Credential::OpenID just pass us back the chunk of extension data
sub _extract_openid_data {
    my ($userinfo) = @_;

    ## Spec says SHOULD use url as identifier
    $userinfo->{username} = $userinfo->{url};

    ## Use email addy as display if available
    if(exists $userinfo->{extensions} &&
         exists $userinfo->{extensions}{'http://openid.net/srv/ax/1.0'} &&
         defined $userinfo->{extensions}{'http://openid.net/srv/ax/1.0'}{'value.email'}) {
        ## Somewhat ugly attribute extension reponse, contains
        ## google-email string which we can use as the id

        $userinfo->{email} = $userinfo->{extensions}{'http://openid.net/srv/ax/1.0'}{'value.email'};
    }

    return;
}

=head2 find_user( $userinfo )

Takes a hashref of C<username> or C<email>, and possibly openIDish results from
L<Net::OpenID::Consumer>.

Fetches the user object for the given username and returns it.

=cut

sub find_user {
    my ($self, $userinfo) = @_;

    ## A URL field means probably an OpenID based user
    if( exists $userinfo->{url} ) {
        _extract_openid_data($userinfo);
    }

	my $user;
	if( exists $userinfo->{username} ) {
    	my $username = $userinfo->{username};
		## No logins if user is deactivated (use lookup to fetch to re-activate)
		$user = $self->lookup(Text::Tradition::User->id_for_user($username));
		## If there is an inactive user, skip it
		return if( $user && !$user->active );
	} elsif( exists $userinfo->{email} ) {
		## Scan the users looking for a matching email
		my @matches;
		$self->scan( sub { push( @matches, @_ ) 
			if $_[0]->isa('Text::Tradition::User') 
			&& $_[0]->email eq $userinfo->{email} } );
		$user = shift @matches;
	}
#    print STDERR "Found user, $username, email is :", $user->email, ":\n";
    return $user;
}

=head2 modify_user( $userinfo )

Takes a hashref of C<username> and C<password> (same as add_user).

Retrieves the user, and updates it with the new information. Username
changing is not currently supported.

Returns the updated user object, or undef if not found.

=cut

sub modify_user {
    my ($self, $userinfo) = @_;
    my $username = $userinfo->{username};
    my $password = $userinfo->{password};
    my $role = $userinfo->{role};

    throw( "Missing username" ) unless $username;

    my $user = $self->find_user({ username => $username });
    throw( "Could not find user $username" ) unless $user;

    if($password) {
    	throw( "Bad password" ) unless $self->validate_password($password);
        $user->password(crypt_password($password));
    }
    if($role) {
        $user->role($role);
    }

    $self->update($user);

    return $user;
}

=head2 deactivate_user( $userinfo )

Takes a hashref of C<username>.

Sets the users C<active> flag to false (0), and sets all traditions
assigned to them to non-public, updates the storage and returns the
deactivated user.

Returns undef if user not found.

=cut

sub deactivate_user {
    my ($self, $userinfo) = @_;
    my $username = $userinfo->{username};

    throw( "Need to specify a username for deactivation" ) unless $username;

    my $user = $self->find_user({ username => $username });
    throw( "User $username not found" ) unless $user;

    $user->active(0);
    foreach my $tradition (@{ $user->traditions }) {
        ## Not implemented yet
        # $tradition->public(0);
    }

    ## Should we be using Text::Tradition::Directory also?
    $self->update(@{ $user->traditions });

    $self->update($user);

    return $user;
}

=head2 reactivate_user( $userinfo )

Takes a hashref of C<username>.

Returns the user object if already activated. Activates (sets the
active flag to true (1)), updates the storage and returns the user.

Returns undef if the user is not found.

=cut

sub reactivate_user {
    my ($self, $userinfo) = @_;
    my $username = $userinfo->{username};

    throw( "Need to specify a username for reactivation" ) unless $username;

    my $user = $self->lookup(Text::Tradition::User->id_for_user($username));
    throw( "User $username not found" ) unless $user;

    return $user if $user->active;

    $user->active(1);
    $self->update($user);

    return $user;    
}

=head2 delete_user( $userinfo )

CAUTION: Deletes actual data!

Takes a hashref of C<username>.

Returns undef if the user doesn't exist.

Removes the user from the store and returns 1.

=cut

sub delete_user {
    my ($self, $userinfo) = @_;
    my $username = $userinfo->{username};

    throw( "Need to specify a username for deletion" ) unless $username;

    my $user = $self->find_user({ username => $username });
    throw( "User $username not found" ) unless $user;

    ## Should we be using Text::Tradition::Directory for this bit?
    $self->delete( @{ $user->traditions });

    ## Poof, gone.
    $self->delete($user);

    return 1;
}

=head2 validate_password( $password )

Takes a password string. Returns true if it is longer than
L</MIN_PASS_LEN>, false otherwise.

Used internally by L</add_user>.

=cut

sub validate_password {
    my ($self, $password) = @_;

    return if !$password;
    return if length($password) < $self->MIN_PASS_LEN;

    return 1;
}

=head2 user_traditionlist( $user )

Returns a tradition list (see specification above) but containing only
those traditions visible to the specified user.  If $user is the string
'public', returns only publicly-viewable traditions.

=cut

sub user_traditionlist {
    my ($self, $user) = @_;
    
    my @tlist;
    if(ref $user && $user->is_admin) {
        ## Admin sees all
        return $self->traditionlist();
    } elsif(ref $user) {
        ## We have a user object already, so just fetch its traditions and use tose
        foreach my $t (@{ $user->traditions }) {
            push( @tlist, { 'id' => $self->object_to_id( $t ), 
                            'name' => $t->name } );
        }
        return @tlist;
    } elsif($user ne 'public') {
        die "Passed neither a user object nor 'public' to user_traditionlist";
    }
    
    ## Search for all traditions which allow public viewing
	my @list = grep { $_->{public} } $self->traditionlist();
	return @list;
}

1;
	
=head1 LICENSE

This package is free software and is provided "as is" without express
or implied warranty.  You can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHORS

Tara L Andrews E<lt>aurum@cpan.orgE<gt> (initial release)

Shadowcat Systems L<http://www.scsys.co.uk/> (user functionality; making it all work)

