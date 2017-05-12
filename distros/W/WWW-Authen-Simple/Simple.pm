package WWW::Authen::Simple;

# $Source: /usr/local/cvs/WWW-Authen-Simple/pm/Simple.pm,v $
# $Revision: 1.24 $
# $Date: 2004/05/12 03:21:32 $
# $Author: jmiller $

use 5.00503;
use strict;
use Digest::MD5 ();
use Carp;
use CGI qw(:standard);
use lib './';

use vars qw($VERSION $REVISION);

$REVISION = sprintf "%d.%03d", q$Revision: 1.24 $ =~ /(\d+)/g;
$VERSION = '1.22';

# Config for table layout and such.
# we'll provide methods to override this, so that WWW:A:S can 
# adapt to other systems
my $conf = {
	session_table	=> {
		_table	=> 'sessions',	# table name
		login	=> 'username', 	# username field
		address	=> 'address',	# remote address field
		ticket	=> 'ticket',	# session ticket field
		point	=> 'point', 	# timestamp point field
		},
	user_table	=> {
		_table	=> 'Users', 	# table name
		uid   	=> 'uid',   	# user unique id field
		login	=> 'login', 	# username field
		passwd	=> 'passwd',	# password field
		status	=> 'disabled',	# status field
		# sub ref to determine if status value is active
		_active_status	=> sub { return 1 if ($_[0] != 1); },
		# sub ref to determine if status value is disabled
		_disabled_status	=> sub { return 1 if ($_[0] == 1); },
		},
	# group statement is used to get the groups. It should
	# fetch a groupname, groupid, and an accessbit.
	# If you don't want to use the accessbit field, just stick
	# the groupid field there as well.
	# %uid% will be replaced with a quoted uid value for the user.
	# here's an alternate statement, to give you some ideas:
	#   SELECT groupname, gid, gid FROM Users WHERE uid = %uid%
	group_statement	=> 'SELECT g.Name, ug.gid, ug.accessbit
	                    FROM Groups g, UserGroups ug
	                    WHERE g.gid = ug.gid AND ug.uid = %uid%',
	# subroutine ref used to encrypt password for db storage
	'crypt'	=> sub { return Digest::MD5::md5_base64($_[0]); }
	};

sub new
{
    my ($this) = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless( $self, $class );
   
	my %opts = @_;
	
	$self->conf($conf);
	my $debug = (defined($opts{debug}) && ($opts{debug} =~ /^\d+$/))
                ? $opts{debug} : 0;
    $self->debug($debug);

	my $expire_seconds = (defined($opts{expire_seconds})  && ($opts{expire_seconds} =~ /^\d+$/))
				? $opts{expire_seconds} : 3600;
	$self->expire_seconds($expire_seconds);

	my $cleanup_seconds = (defined($opts{cleanup_seconds}) && ($opts{cleanup_seconds} =~ /^\d+$/))
				? $opts{cleanup_seconds} : 43200;
	$self->cleanup_seconds($cleanup_seconds);

	$self->cookie_domain($opts{cookie_domain});
	$self->db($opts{db}) if($opts{db});

	return $self;
}

sub db
{
    ref(my $self = shift) or croak "instance variable needed";
    if (@_)
    {
        $self->{_db} = $_[0];
        return $self->{_db};
    } else {
        return $self->{_db};
    }
}

sub cookie_domain
{
    ref(my $self = shift) or croak "instance variable needed";
    if (@_)
    {
        $self->{_cookie_domain} = $_[0];
        return $self->{_cookie_domain};
    } else {
        return $self->{_cookie_domain};
    }
}

sub expire_seconds 
{   
    ref(my $self = shift) or croak "instance variable needed";
    if (@_)
    {   
        croak "expire must be a possitive integer" unless ($_[0] =~ /^\d+$/);
        $self->{_expire_seconds} = $_[0];
        return $self->{_expire_seconds};
    } else {
        return $self->{_expire_seconds};
    }
}

sub cleanup_seconds 
{
    ref(my $self = shift) or croak "instance variable needed";
    if (@_)
    {
        croak "expire must be a possitive integer" unless ($_[0] =~ /^\d+$/);
        $self->{_cleanup_seconds} = $_[0];
        return $self->{_cleanup_seconds};
    } else {
        return $self->{_cleanup_seconds};
    }
}

sub debug
{
    ref(my $self = shift) or croak "instance variable needed";
    if (@_)
    {
        $self->{_debug} = $_[0];
        return $self->{_debug};
    } else {
        return $self->{_debug};
    }
}


sub cleanup
{
	ref(my $self = shift) or croak "instance variable needed";

	my $cleanup_point = time() - $self->cleanup_seconds();
	$self->db->do( 'DELETE FROM '.
		$self->conf->{session_table}{_table} .
		' WHERE '.
		$self->conf->{session_table}{point} .
		' < ' . 
		$self->db->quote($cleanup_point) );
}

sub username
{
	ref(my $self = shift) or croak "instance variable needed";
	return $self->{_store}{username} if($self->{_store}{username});
	return undef;
}

sub uid
{
	ref(my $self = shift) or croak "instance variable needed";
	return $self->{_store}{uid} if($self->{_store}{username});
	return undef;
}

sub logged_in
{
	ref(my $self = shift) or croak "instance variable needed";

	return 1 if($self->{_store}{username});
	return undef unless(($self->{_store}{login_called}) && ($self->{_store}{username}));
	return 0;
}

sub groups
{
	ref(my $self = shift) or croak "instance variable needed";

	# load groups for this user if we haven't loaded them already
	unless (defined $self->{_store}{_groups})
	{
		$self->_load_groups();
	}

	my @return_array;

	foreach my $group (keys %{$self->{_store}{_groups}})
	{
		push(@return_array,$group); # group could be a name or gid
	}

	return @return_array;
}

sub _load_groups
{
	ref(my $self = shift) or croak "instance variable needed";

	my $group_statement = $self->conf->{group_statement};
	# inject uid
	my $q_uid = $self->db->quote( $self->{_store}{uid} );
	$group_statement =~ s/\%uid\%/$q_uid/g;
	my $get_groups = $self->db->prepare( $group_statement )
		or croak "Unable to prepare group select statement '$group_statement'";
	$get_groups->execute
		or croak "Unable to execute group select statement '$group_statement'";
	while (my ($name,$gid,$accessbit) = $get_groups->fetchrow_array)
	{
		$self->{_store}{_groups}{$name} = $accessbit;
		$self->{_store}{_groups}{$gid} = $accessbit;
	}
	$get_groups->finish;
}

sub in_group
{
	ref(my $self = shift) or croak "instance variable needed";

	my ($group,$rw) = @_;

	my $rwbit;
	if ($rw && ($rw =~ /^\d+$/))
	{	# it's a number
		$rwbit = $rw;
	} elsif ($rw && ($rw =~ /^(r|w)/i)) {
		# it's a name (should be either "r", "w", or "rw"
		$rwbit += 1 if ($rw =~ /r/i);
		$rwbit += 2 if ($rw =~ /w/i);
	} else {
		# just return the bits, since they didn't ask for something
		$rwbit = 0;
	}

	# load groups for this user if we haven't loaded them already
	unless (defined $self->{_store}{_groups})
	{
		$self->_load_groups();
	}

	# $group can be either a gid or a group name.
	# we just make sure we don't name any of our groups w/ numbers
	if (defined $self->{_store}{_groups}{$group})
	{	# they're in the group they asked for
		# either return the accessbits,
		# or true/false if they specified a $rw bit
		if ($rwbit)
		{	# we check the access bit in here (using bitwise AND)
			warn "in_group(G[$group] rw[$rwbit])\n\tstored rwbit[".$self->{_store}{_groups}{$group}."]\n\tRV[".(($self->{_store}{_groups}{$group} & $rwbit) == $rwbit)."]\n" if $self->debug();
			return (($self->{_store}{_groups}{$group} & $rwbit) == $rwbit);
		} else {
			# just return the access bit
			return $self->{_store}{_groups}{$group};
		}
	} else {
		return 0; # zero is no read, no write
	}
}

sub login
{
	    
	ref(my $self = shift) or croak "instance variable needed";
	my ($login,$passwd) = @_;

	my $cgi = new CGI;

	my $remote_address = $ENV{REMOTE_ADDR};
	$self->{_store}{login_called} = 1;

	if ($login && $passwd)
	{	# if neither are null, they're trying to login.
		my ($uid,$local_passwd,$status) = $self->_get_user_info($login);

		# invalid login (user doesn't exist)
		return (0,$login) unless $uid;
		# invalid login (account is disabled)
		return (0,$login) if &{$self->conf->{user_table}{_disabled_status}}($status);

		my $crypt_passwd = $self->_getcrypt($passwd);
		if ($crypt_passwd eq $local_passwd)
		{
			# they're authenticated... need to update local session, set cookie ticket for them, and return "1" for logged in
			my $new_ticket = $self->_ticket;
			my $point = time;
			$self->{_store}{username} = $login;
			$self->{_store}{uid} = $uid;
			$self->_set_session($login,$remote_address,$new_ticket,$point);
			return (1,$login,$uid);
		} else {
			return (0,$login); # invalid login (passwd doesn't match)
		}
	}

	my $remote_login = $cgi->cookie('login');
	my $remote_ticket = $cgi->cookie('ticket');
	if ($remote_login && $remote_ticket)
	{	# they've logged in before (or are spoofing)
		my $get_ticket = $self->db->prepare(
			'SELECT '.
			$self->conf->{session_table}{ticket} .', '.
			$self->conf->{session_table}{point} .
			' FROM '.
			$self->conf->{session_table}{_table} .
			' WHERE '.
			$self->conf->{session_table}{login} .' = '.
			$self->db->quote($remote_login) .
			' AND '.
			$self->conf->{session_table}{address} .' = '.
			$self->db->quote($remote_address)
			) or croak "Unable to prepare get_ticket statement";
		$get_ticket->execute()
			or croak "Unable to execute get_ticket statement";
			
		my ($local_ticket,$local_point) = $get_ticket->fetchrow_array();
		$get_ticket->finish;

		my $point = time;
		if ($local_ticket && ($remote_ticket eq $local_ticket))
		{
			if ($local_point > ($point - $self->expire_seconds()))
			{	# valid ticket, continue sesson
				# keep using existing ticket, update point on it
				# set remote cookie's (so they don't time out)
				# return logged in signal

				# make sure they're not disabled
				my ($uid,$local_passwd,$status) = $self->_get_user_info($remote_login);

				return (0,$remote_login) if &{$self->conf->{user_table}{_disabled_status}}($status);

				my $point = time;
				$self->_set_session($remote_login,$remote_address,$local_ticket,$point);
				$self->{_store}{username} = $remote_login;
				$self->{_store}{uid} = $uid;
				return (1,$remote_login,$uid);
			} else {
				# login has expired
				return (-1,$remote_login); #login expired
			}
		} else {
			# invalid ticket (username cookie matched, ticket cookie didn't)
			return (0,$remote_login); # invalid login
		}
	} else {
		# didn't try to login, and no cookies set
		return (0,0);
	}
}

sub conf
{
	ref(my $self = shift) or croak "instance variable needed";
    if (@_)
    {
        $self->{_conf} = $_[0];
        return $self->{_conf};
    } else {
        return $self->{_conf};
    }
	return $self->{_conf};
}

sub _get_user_info
{
	ref(my $self = shift) or croak "instance variable needed";
	my $login = shift;
	my $get_user_info = $self->db->prepare(
		'SELECT '.
		$self->conf->{user_table}{uid} .', '.
		$self->conf->{user_table}{passwd} .', '.
		$self->conf->{user_table}{status} .
		' FROM '.
		$self->conf->{user_table}{_table} .
		' WHERE '.
		$self->conf->{user_table}{login} . ' = ' .
		$self->db->quote($login)  )
		or croak "Unable to prepare get_user_info statement";
	$get_user_info->execute
		or croak "Unable to execute get_user_info statement";
	my ($uid,$local_passwd,$status) = $get_user_info->fetchrow_array();
	$get_user_info->finish;
	return ($uid,$local_passwd,$status);
}

sub logout
{
	ref(my $self = shift) or croak "instance variable needed";

	my $cgi = new CGI;
	my $login = $self->username() || $cgi->cookie('login');
	my $remote_address = $ENV{REMOTE_ADDR};
	if ($login && $remote_address)
	{
		$self->_set_session($login,$remote_address,'*',0);
	}
	# clear out the stored data
	$self->{_store}{username} = '';
	$self->{_store}{uid} = '';
	# leave _groups hash ref so that we don't try to reload them
	# but clear all access bits, removing the users access
	foreach my $group (keys %{$self->{_store}{_groups}})
	{
		$self->{_store}{_groups}{$group} = '0';
	}
}

sub _set_cookie
{
	ref(my $self = shift) or croak "instance variable needed";

	my ($login,$ticket,$point) = @_;
	my ($login_cookie,$ticket_cookie);

	my $base_cookie = '; domain=' . $self->cookie_domain();
	if ($point == 0)
	{	# if they hit logout, then try to expire their local cookie
		$base_cookie .= '; max-age=0';
	} else {
		$base_cookie .= '; max-age=' . $self->expire_seconds();
	}
	$base_cookie .= '; path=/';
	$base_cookie .= '; version=1';

	print 'Set-Cookie: login=' . $login . $base_cookie . "\n";
	print 'Set-Cookie: ticket=' . $ticket . $base_cookie . "\n";
}

sub _set_session
{
	ref(my $self = shift) or croak "instance variable needed";

	my ($login,$address,$ticket,$point) = @_;

	$self->_set_cookie($login,$ticket,$point);

	# set local session
	my $get_ticket = $self->db->prepare(
		'SELECT '.
		$self->conf->{session_table}{ticket} .
		' FROM '.
		$self->conf->{session_table}{_table} .
		' WHERE '.
		$self->conf->{session_table}{login} . ' = '.
		$self->db->quote($login) .
		' AND '.
		$self->conf->{session_table}{address} . ' = '.
		$self->db->quote($address)  )
		or croak "Unable to prepare get_ticket statement";
	$get_ticket->execute()
		or croak "Unable to execute get_ticket statement";
	my ($local_ticket) = $get_ticket->fetchrow_array();
	$get_ticket->finish;
		
	if ($local_ticket)
	{	# a session has already been stored for this user/addy
		$self->db->do(
			'UPDATE '.
			$self->conf->{session_table}{_table} .
			' SET '.
			$self->conf->{session_table}{ticket} .' = '.
			$self->db->quote($ticket) .', '.
			$self->conf->{session_table}{point} .' = '.
			$self->db->quote($point) .
			' WHERE '.
			$self->conf->{session_table}{login} .' = '.
			$self->db->quote($login) .
			' AND '.
			$self->conf->{session_table}{address} .' = '.
			$self->db->quote($address)  )
			or croak "Unable to update session table for login[$login] address[$address]";
	} else {
		# set a new local session
		$self->db->do(
			'INSERT INTO '.
			$self->conf->{session_table}{_table} .
			' ('.
			$self->conf->{session_table}{login} .', '.
			$self->conf->{session_table}{address} .', '.
			$self->conf->{session_table}{ticket} .', '.
			$self->conf->{session_table}{point} .
			') VALUES ('.
			$self->db->quote($login) .', '.
			$self->db->quote($address) .', '.
			$self->db->quote($ticket) .', '.
			$self->db->quote($point) .')'
			) or croak "Unable to insert session for login[$login] address[$address]";
	}
}

sub _ticket
{
	my $length = 128;
	my $ticket;
	while($length-- > 0)
	{
		$ticket .= chr(rand(256));
	}
	return Digest::MD5::md5_hex($ticket);
}

sub _getcrypt
{
	ref(my $self = shift) or croak "instance variable needed";
	my $pass = shift;
	return &{$self->conf->{'crypt'}}($pass);
}

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

WWW::Authen::Simple - Cookie based session and authentication module using database backend. Also provides group based authorization.

=head1 SYNOPSIS

 use WWW::Authen::Simple;

 my $simple = WWW::Authen::Simple->new(
 		db => $DBI_handle,
 		cookie_domain => 'cookie_domain'
 );
 # Alternitively, any of the methods to set variables may also be
 # used directly in the constructor
 $simple->logout() if $cgi->param('logout');
 $simple->login( $cgi->param('login'), $cgi->param('pass') );
 if ($simple->logged_in()) {
    if ($simple->in_group('Admin','rw')) {
       &do_admin_page();
    } else {
       &do_something();
    }
 } else {
    print redirect('/login.pl');
 }

=head1 ABSTRACT

WWW::Authen::Simple provides another way to do cookie based sessions and authentication. It's goal is to provide a very simple API to handle sessions and authentication.

The database layout has been abstracted, so you should be able to fit this into whatever database layout you currently use, or use the provided default to base your application.

NOTE: the database abstraction is configured by a hash. If changes to it's structure are needed, you currently have to rebuild the entire hash, and pass it in (ie. there is no API to make it easy to change yet).

=head1 REQUIRES

 DBI and an appropriate DBD driver for your database
 Digest::MD5 (standard perl module)
 CGI

In most common situations, you'll also want to have:

 A web server (untested on windows, but it should work)
 cgi-bin or mod-perl access
 Perl: Perl 5.00503 or later must be installed on the web server.

=head1 INSTALLATION

The module can be installed using the standard Perl procedure:

    perl Makefile.PL
    make
    make test
    make install    # you need to be root

Windows users without a working "make" can get nmake from:

    ftp://ftp.microsoft.com/Softlib/MSLFILES/nmake15.exe

=head1 METHODS

=over

=item C<$simple = WWW::Authen::Simple-E<gt>new();>

This creates a new Simple object.
Optionally, you can pass in a hash with configuration information.
See the method descriptions for more detail on what they mean.

=over 2

   cookie_domain => 'www.somedomain.com', # required
   db => $DBI_handle, # required
   expire_seconds => 3600, # optional. default 3600
   cleanup_seconds =>  43200, # optional. default 43200 
   debug => 0, # optional. default 0
   conf => $config_hash_ref, # optional. defaults hardcoded.

=back

=item C<$simple-E<gt>db( $DBIx_PDlib_object );> 

Required. Database Handle from DBIx::PDlib; 

=item C<$simple-E<gt>cookie_domain( 'www.some_domain.com' );>

Required. The Domain your authenticating into. Needed to store the cookie info.

=item C<$simple-E<gt>login( $login, $password );>

If $login and $password are undef (not set / not passed in), it checks the users cookies for a valid ticket. Otherwise, checks the username/password against the database.

Returns:

   (0,$login) : inactive account, user doesn't exist,
                password doesn't match, or invalid ticket
   (1,$login,$uid) : login successful
   (-1,$login) : login expired
   (0,0) : no user/pass sent, no cookies exist.

=item C<$simple-E<gt>logout();>

Logs the current user out by nulling out their session ticket in the database.

=item C<$simple-E<gt>logged_in();>

Returns 1 if the user is logged in. Returns undef is login() was called, but the user failed authentication. Returns 0 (zero) if the login() hasn't been called yet.

=item C<$simple-E<gt>uid();>

Get the current session user id.

=item C<$simple-E<gt>username();>

Get the current session username.

=item C<$simple-E<gt>groups();>

Returns an array of all groups names and group id's the user belongs to.

=item C<$simple-E<gt>in_group($group,$rw);>

$group can be the group name, or the group id.

$rw (optional) can be:

   1  : Read access for the group.
   2  : Write access for the group.
   3  : Both read and write access for the group.
   r  : Read access for the group.
   w  : Write access for the group.
   rw : Both read and write access for the group.

If called without the $rw option, it returns the raw access bits (will be true if the user is in the group and has any level of access: read, write, or both).

If called with the $rw option, returns true if the user is in the group, and has that level of access. Returns false otherwise.

=item C<$simple-E<gt>debug( [0|1|2] );>

Optional. 
Sets the debugging bit. 1 turns it on, 0 turns it off. 2 will print out verbose messages to STDERR.

=item C<$simple-E<gt>cleanup();>

Cleans out the old sessions from the session database. Should be called once in a while from a cron script. The frequency of calls to this is up to you, and it's need depends on how heavy your usage is. If you never call cleanup(), it won't be the end of the world... things will keep working just fine.

=item C<$simple-E<gt>cleanup_seconds($integer_seconds);>

How old a session entry should be before it get's cleaned out. Defaults to 43200 seconds (12 hours).

=item C<$simple-E<gt>conf($conf);>

$conf is optional. Set's the config hash if it's passed in.

Returns the config hash.

Config hash is structured like so:

  $conf = {
    session_table   => {
        _table  => 'sessions',  # table name
        login   => 'username',  # username field
        address => 'address',   # remote address field
        ticket  => 'ticket',    # session ticket field
        point   => 'point',     # timestamp point field
        },
    user_table  => {
        _table  => 'Users',     # table name
        uid     => 'uid',       # user unique id field
        login   => 'login',     # username field
        passwd  => 'passwd',    # password field
        status  => 'disabled',  # status field
        # sub ref to determine if status value is active
        _active_status  => sub { return 1 if ($_[0] != 1); },
        # sub ref to determine if status value is disabled
        _disabled_status    => sub { return 1 if ($_[0] == 1); },
        },
    # group statement is used to get the groups. It should
    # fetch a groupname, groupid, and an accessbit.
    # If you don't want to use the accessbit field, just stick
    # the groupid field there as well.
    # %uid% will be replaced with a quoted uid value for the user.
    # here's an alternate statement, to give you some ideas:
    #   SELECT groupname, gid, gid FROM Users WHERE uid = %uid%
    group_statement => 'SELECT g.Name, ug.gid, ug.accessbit
                        FROM Groups g, UserGroups ug
                        WHERE ug.uid = %uid%',
    # subroutine ref used to encrypt password for db storage
    'crypt' => sub { return Digest::MD5::md5_base64($_[0]); }
    };

=back

=head1 SEE ALSO

"examples" subdirectory of this distribution.

Averist.pm: http://www.nongnu.org/averist/ : A more flexable session/auth module.

CGI::Session: http://search.cpan.org/dist/CGI-Session

Apache::Session: http://search.cpan.org/dist/Apache-Session

CGI::Session::Auth: http://search.cpan.org/dist/CGI-Session-Auth

=head1 TODO

Tests need written.

Session storage abstraction.

Authentication method abstraction.

=head1 AUTHORS

Josh I. Miller, E<lt>jmiller@purifieddata.netE<gt>

Seth T. Jackson, E<lt>sjackson@purifieddata.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Seth Jackson       

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
