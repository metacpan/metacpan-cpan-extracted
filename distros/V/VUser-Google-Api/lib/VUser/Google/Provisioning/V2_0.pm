package VUser::Google::Provisioning::V2_0;
use warnings;
use strict;

our $VERSION = '0.2.0';

use Moose;
extends 'VUser::Google::Provisioning';

use VUser::Google::Provisioning::UserEntry;

has '+base_url' => (default => 'https://apps-apis.google.com/a/feeds/');

#### Methods ####
## Users
#
# %options
#   userName*
#   givenName*
#   familyName*
#   password*
#   hashFunctioName (SHA-1|MD5)
#   suspended       (bool)
#   quota           (in MB)
#   changePasswordAtNextLogin (bool)
#   admin           (bool)
sub CreateUser {
    my $self    = shift;

    my %options = ();

    if (ref $_[0]
	    and $_[0]->isa('VUser::Google::Provisioning::UserEntry')) {
	%options = $_[0]->as_hash;
    }
    else {
	%options = @_;
    }

    $self->google()->Login();
    my $url = $self->base_url.$self->google->domain.'/user/2.0';

    my $post = '<?xml version="1.0" encoding="UTF-8"?>
<atom:entry xmlns:atom="http://www.w3.org/2005/Atom"
  xmlns:apps="http://schemas.google.com/apps/2006">
    <atom:category scheme="http://schemas.google.com/g/2005#kind" 
        term="http://schemas.google.com/apps/2006#user"/>
';

    ## login
    $post .= '<apps:login ';
    $post .= " userName=\"$options{'userName'}\"";

    $post .= " password=\""
	.$self->_escape_quotes($options{'password'})."\"";

    if ($options{hashFunctionName}) {
	$post .= " hashFunctionName=\"$options{hashFunctionName}\"";
    }

    if ($options{suspended}) {
	$post .= ' suspended="'.$self->_as_bool($options{suspended}).'"';
    }

    if ($options{changePasswordAtNextLogin}) {
	$post .= ' changePasswordAtNextLogin="'
	    .$self->_as_bool($options{changePasswordAtNextLogin}).'"';
    }

    if ($options{admin}) {
	$post .= ' admin="'.$self->_as_bool($options{admin}).'"';
    }

    $post .= '/>';

    ## quota
    if ($options{quota}) {
	$post .= "<apps:quota limit=\"$options{quota}\"/>";
    }

    ## name
    $post .= '<apps:name';
    $post .= " familyName=\"$options{familyName}\"";
    $post .= " givenName=\"$options{givenName}\"";
    $post .= '/>';

    $post .= '</atom:entry>';

    if ($self->google->Request('POST', $url, $post)) {
	## build UserEntry
	$self->dprint('Created user');
	my $entry = $self->_build_user_entry($self->google->result);
	return $entry;
    }
    else {
	## ERROR!
	$self->dprint('CreateUser failed: '.$self->google->result->{reason});
	die "Error creating user: ".$self->google->result->{'reason'}."\n";
    }
}

sub RetrieveUser {
    my $self = shift;
    my $username = shift;

    my $url = $self->base_url.$self->google->domain.'/user/2.0/'.$username;

    if ($self->google->Request('GET', $url)) {
	return $self->_build_user_entry($self->google->result);
    }
    else {
	if ($self->google->result->{'reason'} =~ /EntityDoesNotExist/) {
	    return undef;
	}
	else {
	    die "Error retrieving user: ".$self->google->result->{'reason'}."\n";
	}
    }
}

# Retrieve one page of users.
# How to return the next page?
# Returns (
#   entries => \@entries, # list of UserEntry objects
#   next    => $next      # the next username if another page exists
#                         # undef otherwise
#   )
sub RetrieveUsers {
    my $self       = shift;
    my $start_user = shift;

    my @entries = ();
    my $next_user;

    my $url = $self->base_url.$self->google->domain.'/user/2.0';
    if ($start_user) {
	$url .= "?startUsername=$start_user";
    }

    if ($self->google->Request('GET', $url)) {
	foreach my $entry (@{ $self->google->result->{'entry'} }) {
	    ## Create UserEntry object
	    my $user = $self->_build_user_entry($entry);
	    push @entries, $user;
	}
    }
    else {
	## There was an error
	die "Error fetching users: ".$self->google->result->{'reason'}."\n";
    }

    # Look for the a link tag that says there should be more results
    # A link tag with rel=next means there is another page
    foreach my $link (@{ $self->google->result->{'link'} }) {
	if ($link->{'rel'} eq 'next') {
	    $url = $link->{'href'};
	    if ($url =~ /startUsername=([^\"]+)/) {
		$next_user = $1;
	    }
	}
    }

    return ( entries => \@entries, next => $next_user );
}

# Alias for RetrieveUsers
sub RetrievePageOfUsers {
    $_[0]->RetrieveUsers(@_);
}

# Returns a list of UserEntry objects
sub RetrieveAllUsers {
    my $self = shift;

    my @entries = ();
    my $next;

    my %results;

    eval {
	%results = $self->RetrieveUsers;
	push @entries, @{ $results{'entries'} };
	$next = $results{'next'};
    };
    die $@ if $@;

    while ($next) {
	eval {
	    %results = $self->RetrieveUsers($next);
	    push @entries, @{ $results{'entries'} };
	    $next = $results{'next'};
	};
	die $@ if $@;
    }

    return @entries;
}

# %options
#   userName*
#   givenName
#   familyName
#   password
#   hashFunctioName (SHA-1|MD5)
#   suspended       (bool)
#   quota           (in MB)
#   changePasswordAtNextLogin (bool)
#   admin           (admin)
sub UpdateUser {
    my $self = shift;

    my %options = ();

    if (ref $_[0]
	    and $_[0]->isa('VUser::Google::Provisioning::UserEntry')) {
	%options = $_[0]->as_hash;
    }
    else {
	%options = @_;
    }

    die "Can't update user: userName not set\n" unless $options{'userName'};

    my $url = $self->base_url.$self->google->domain
	."/user/2.0/$options{userName}";

    my $post = '<?xml version="1.0" encoding="UTF-8"?>
<atom:entry xmlns:atom="http://www.w3.org/2005/Atom"
  xmlns:apps="http://schemas.google.com/apps/2006">
    <atom:category scheme="http://schemas.google.com/g/2005#kind" 
        term="http://schemas.google.com/apps/2006#user"/>
';

    ## update user info (login tag)
    if ($options{password}
	    or defined $options{suspended}
            or defined $options{changePasswordAtNextLogin}
	    or defined $options{admin}
	) {
	$post .= '<apps:login';

	if (defined $options{password}) {
	    $post .= ' password="';
	    $post .= $self->_escape_quotes($options{'password'});
	    $post .= '"';

	    if (defined $options{hashFunctionName}) {
		$post .= ' hashFunctionName="';
		$post .= $options{hashFunctionName};
		$post .= '"';
	    }
	}

	if (defined $options{suspended}) {
	    $post .= ' suspended="'.$self->_as_bool($options{suspended}).'"';
	}

	if (defined $options{changePasswordAtNextLogin}) {
	    $post .= ' changePasswordAtNextLogin="'
		.$self->_as_bool($options{changePasswordAtNextLogin}).'"';
	}

	if (defined $options{admin}) {
	    $post .= ' admin="'.$self->_as_bool($options{admin}).'"';
	}

	$post .= '/>';
    }

    ## Quota
    if ($options{quota}) {
	$post .= "<apps:quota limit=\"$options{quota}\"/>";
    }

    ## Name
    if ($options{givenName} or $options{familyName}) {
	$post .= '<apps:name';
	$post .= " familyName=\"$options{familyName}\"" if $options{familyName};
	$post .= " givenName=\"$options{givenName}\"" if $options{givenName};
	$post .= '/>';
    }

    $post .= '</atom:entry>';

    if ($self->google->Request('PUT', $url, $post)) {
	$self->dprint('Updated user');
	my $entry = $self->_build_user_entry($self->google->result);
	return $entry;
    }
    else {
	die "Error updating user: ".$self->google->result->{'reason'}."\n";
    }
}

sub RenameUser {
    my $self    = shift;
    my $oldname = shift;
    my $newname = shift;

    die "Can't rename user: old userName not set\n" unless $oldname;
    die "Can't rename user: new userName not set\n" unless $newname;

    my $url = $self->base_url.$self->google->domain
	."/user/2.0/$oldname";

    my $user = $self->RetrieveUser($oldname)
	or die "Unknown user: $oldname\n";

    my $post = '<?xml version="1.0" encoding="UTF-8"?>
<atom:entry xmlns:atom="http://www.w3.org/2005/Atom"
  xmlns:apps="http://schemas.google.com/apps/2006">
    <atom:category scheme="http://schemas.google.com/g/2005#kind" 
        term="http://schemas.google.com/apps/2006#user"/>
';

    $post .= '<atom:title type="text">$oldname</atom:title>';
    $post .= '<atom:link rel="self" type="application/atom+xml"';
    $post .= " href=\"".$self->base_url.
	$self->google->domain."/user/2.0/$oldname\"/>";
    $post .= '<atom:link rel="edit" type="application/atom+xml"';
    $post .= " href=\"".$self->base_url.
	$self->google->domain."/user/2.0/$oldname\"/>";

    $post .= "<apps:login";
    $post .= " userName='$newname'";
    $post .= ' suspended="'.$self->_as_bool($user->Suspended).'"';
    $post .= ' admin="'.$self->_as_bool($user->Admin).'"';
    $post .= ' changePasswordAtNextLogin="'
	.$self->_as_bool($user->ChangePasswordAtNextLogin).'"';
    # $post .= ' agreedToTerms="'.$self->_as_bool($user->AgreedToTerms).'"';
    $post .= "/>";

    $post .= '</atom:entry>';

    if ($self->google->Request('PUT', $url, $post)) {
	$self->dprint("Renamed $oldname to $newname");
	my $entry = $self->_build_user_entry($self->google->result);
	return $entry;
    }
    else {
	die "Error rename user: ".$self->google->result->{'reason'}."\n";
    }
}

sub DeleteUser {
    my $self = shift;
    my $user;

    if (ref $_[0] and $_[0]->isa('VUser::Google::Provisioning::UserEntry')) {
	$user = $_[0]->UserName
    }
    else {
	$user = $_[0];
    }

    my $url = $self->base_url.$self->google->domain.'/user/2.0/'.$user;

    if ($self->google->Request('DELETE', $url)) {
	return 1;
    }
    else {
	return undef;
    }
}

sub ChangePassword {
    my $self          = shift;
    my $username      = shift;
    my $password      = shift;
    my $hash_function = shift;

    if (not $username or not $password) {
	die "Can't change password: username or password not set.\n";
    }

    my $entry = $self->UpdateUser(
	userName         => $username,
	password         => $password,
	hashFunctionName => $hash_function,
    );

    return $entry;
}

## Nicknames
sub CreateNickname {
}

sub RetrieveNickname {
}

sub RetrieveAllNicknamesForUser {
}

sub RetrieveAllNicknamesInDomain {
}

sub DeleteNickname {
}

# Takes the parsed XML object
sub _build_user_entry {
    my $self = shift;
    my $xml  = shift;

    my $entry = VUser::Google::Provisioning::UserEntry->new();

    $entry->UserName($xml->{'apps:login'}[0]{'userName'});

    if ($xml->{'apps:login'}[0]{'suspended'}) {
	if ($xml->{'apps:login'}[0]{'suspended'} eq 'true') {
	    $entry->Suspended(1);
	}
	else {
	    $entry->Suspended(0);
	}
    }

    if ($xml->{'apps:login'}[0]{'changePasswordAtNextLogin'}) {
	if ($xml->{'apps:login'}[0]{'changePasswordAtNextLogin'} eq 'true') {
	    $entry->ChangePasswordAtNextLogin(1);
	}
	else {
	    $entry->ChangePasswordAtNextLogin(0);
	}
    }

    if ($xml->{'apps:login'}[0]{'admin'}) {
	if ($xml->{'apps:login'}[0]{'admin'} eq 'true') {
	    $entry->Admin(1);
	}
	else {
	    $entry->Admin(0);
	}
    }

    if ($xml->{'apps:login'}[0]{'agreedToTerms'}) {
	if ($xml->{'apps:login'}[0]{'agreedToTerms'} eq 'true') {
	    $entry->AgreedToTerms(1);
	}
	else {
	    $entry->AgreedToTerms(0);
	}
    }

    $entry->FamilyName($xml->{'apps:name'}[0]{'familyName'});
    $entry->GivenName($xml->{'apps:name'}[0]{'givenName'});
    $entry->Quota($xml->{'apps:quota'}[0]{'limit'});

    return $entry;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

VUser::Google::Provisioning::V2_0 - Support for version 2.0 of the Google Provisioning API

=head1 SYNOPSIS

 use VUser::Google::ApiProtocol::V2_0;
 use VUser::Google::Provisioning::V2_0;
 
 my $google = VUser::Google::ApiProtocol::V2_0->new(
     domain   => 'example.com',
     admin    => 'admin_user',
     password => 'secret',
 );
 
 my $api = VUser::Google::Provisioning::V2_0->new(
     google => $google,
 );
 
 ## Create user
 my $new_user = $api->CreateUser(
     userName    => 'fflintstone',
     givenName   => 'Fred',
     familyName  => 'Flintstone',
     password    => 'I<3Wilma',
 );
 
 ## Retrieve a user
 my $user = $api->RetrieveUser('fflintstone');
 
 ## Retrieve all userr
 my @users = $api->RetrieveAllUsers();
 
 ## Update a user
 my $updated = $api->UpdateUser(
     userName   => 'fflintstone',
     givenName  => 'Fredrock',
     familyName => 'FlintStone',
     suspended  => 1,
     quota      => 2048,
 );
 
 ## Change password
 $updated = $api->ChangePassword('fflintstone', 'new-pass');
 
 $updated = $api->ChangePassword(
     'fflintstone',
     '51eea05d46317fadd5cad6787a8f562be90b4446',
     'SHA-1',
 );
 
 $updated = $api->ChangePassword(
     'fflintstone',
     'd27117a019717502efe307d110f5eb3d',
     'MD5',
 );
 
 ## Delete a user
 my $rc = $api->DeleteUser('fflintstone');

=head1 DESCRIPTION

VUser::Google::Provisioning::V2_0 provides support for managing users
using version 2.0 of the Google Provisioning API.

In order to use the Google Provisioning API, you must turn on API support
from the Google Apps for Your Domain control panel. The user that is
used to create the VUser::Google::ApiProtocol object must have administrative
privileges on the domain.

B<Note:> It's a good idea to log into the web control panel at least once
as the API user in order to accept the the terms of service and admin terms.
If you don't, you'll get intermittent authentication errors when trying to
use the API.

=head2 METHODS

Unless stated otherwise, these methods will die() if there is an API error.

=head3 CreateUser

CreateUser() takes a hash of create options and returns a
VUser::Google::Provisioning::UserEntry object if the account
was created. CreateUser() will die() if there is an error.

The keys of the hash are:

=over

=item userName (required)

The user name of the account to create

=item givenName (required)

The user's given name

=item familyName (required)

The user's family name

=item password (required)

The user's password. If hashFunctionName is also set, this is
the base16-encoded hash of the password. Otherwise, this is the
user's plaintext password.

Google required that passwords be, at least, six characters.

=item hashFunctionName

hashFunctionName must be I<SHA-1> or I<MD5>. If this is set,
password is the base16-encoded password hash.

=item quota

The user's quota in MB.

Not all domains will be allowed to set users'
quotas. If that's the case, creation will still succeed but the
quota will be set to the default for your domain.

=item changePasswordAtNextLogin

If set to a true value, e.g. C<1>, the user will be required to
change their password the next time they login in. This is the default.
You may turn this off by setting changePasswordAtNextLogin to C<0>.

=item admin

If set to a true value, e.g. C<1>, the user will be granted
administrative privileges. A false value, e.g. C<0>, admin rights will
be revoked. By default, users will not be granted admin rights.

=back

=head3 RetrieveUser

 my $user = $api->RetrieveUser('fflintstone');

Retrieves a specified user by the user name. RetieveUser will return a
VUser::Google::Provisioning::UserEntry if the user exists and undef
if it doesn't.

=head3 RetrieveUsers

 my @users = ();
 
 my %results = $api->RetrieveUsers();
 @users = @{ $results{entries} };
 
 while ($results{next}) {
     %results = $api->RetrieveUsers($results{next});
     push @users, @{ $results{entries} };
 }

Fetches one page of users starting at a given user name. Currently,
a page is defined as 100 users. This is useful if you plan on
paginating the results yourself or if you have a very large number
of users.

The returned result is a hash with the following keys:

=over

=item entries

A list reference containing the user accounts. Each entry
is a VUser::Google::Provisioning::UserEntry object.

=item next

The user name for the start of the next page. This will be
undefined (C<undef>) if there are no more pages.

=back

See RetrieveAllUsers() if you want
to fetch all of the accounts at once.

=head3 RetrievePageOfUsers

This is a synonym for RetrieveUsers()

=head3 RetrieveAllUsers

 my @users = $api->RetrieveAllUsers();

Get a list of all the users for the domain. The entries in the
list are VUser::Google::Provisioning::UserEntry objects.

=head3 UpdateUser

 my $updated = $api->UpdateUser(
     userName  => 'fflintstone',
     givenName => 'Fred',
     # ... other options
 );

Updates an account. UpdateUser takes the same options as CreateUser() but
only userName is required.

UpdateUser() cannot be used to rename an account. See RenameUser().

=head3 RenameUser

 my $user_user = $api->RenameUser($oldname, $newname);

Rename an account. The first parameter is the old user name; the
second is the new user name. RenameUser() will die if the old name
does not exist.

=head3 DeleteUser

 my $rc = $api->DeleteUser('fflintstone');

Deletes a given user. Returns true if the delete succeded and dies
if there was an error.

=head3 ChangePassword

 $updated = $api->ChangePassword('fflintstone', 'new-pass');
 
 $updated = $api->ChangePassword(
     'fflintstone',
     '51eea05d46317fadd5cad6787a8f562be90b4446',
     'SHA-1',
 );
 
 $updated = $api->ChangePassword(
     'fflintstone',
     'd27117a019717502efe307d110f5eb3d',
     'MD5',
 );

Change a users password.

ChangePassword takes the user name, password and, optionally, a
hash function name. If the hash function name is set, the password,
is the base16-encoded password, otherwise it is the clear text password.

Accepted values for the has function name are I<MD5> and I<SHA-1>.

There is no difference between using this and using UpdateUser to change
the user's password.

=head1 SEE ALSO

=over

=item *

VUser::Google::Provisioning

=item *

VUser::Google::ApiProtocol::V2_0

=item *

VUser::Google::EmailSettings::V2_0

=item *

http://code.google.com/apis/apps/gdata_provisioning_api_v2.0_developers_protocol.html

item *

http://code.google.com/apis/apps/gdata_provisioning_api_v2.0_reference.html

=back

=head1 BUGS

Bugs may be reported at http://code.google.com/p/vuser/issues/list.

=head1 AUTHOR

Randy Smith <perlstalker@vuser.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009  Randall Smith

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

=cut
