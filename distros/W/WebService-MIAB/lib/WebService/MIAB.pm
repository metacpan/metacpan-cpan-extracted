package WebService::MIAB;

use 5.006;
use strict;
use warnings;

=head1 NAME

WebService::MIAB - manage emails (users) and alias addresses on a mail-in-a-box server

=head1 VERSION

version 0.03

=cut

use version;
our $VERSION = '0.03';

use Moo;
with 'WebService::Client';

use LWP::UserAgent;
use MIME::Base64;
use Carp qw(croak);
use re qw(is_regexp);
use List::MoreUtils qw(uniq);

use JSON;
my $json = JSON->new->allow_nonref;

#Alias_Address
has alias_get_uri => ( is => 'ro', default => '/mail/aliases?format=json' );
has alias_add_uri => ( is => 'ro', default => '/mail/aliases/add' );
has alias_remove_uri => ( is => 'ro', default => '/mail/aliases/remove' );

#User_Address
has user_get_uri => ( is => 'ro', default => '/mail/users?format=json');
has user_add_uri => ( is => 'ro', default => '/mail/users/add' );
has user_remove_uri => ( is => 'ro', default => '/mail/users/remove' );

#General
has host => (is => 'ro', required => 1);
has pass => ( is => 'ro', required => 1 );
has username => ( is => 'ro', required => 1 );
has '+base_url' => (
	is => 'ro',
	lazy => 1,
	builder => sub {
		my ($self) = @_;
		return 'https://'.$self->host.'/admin';
	},
);

# custom deserializer needed as the MIAB webservice doesn't return JSON for post requests
has '+deserializer' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $usejson = $self->json;
        sub {
            my ($res, %args) = @_;
			my $decoded = $res;

			if ($res->request->uri =~ /json/) {
				$decoded = $json->decode($res->content);
			}
#				else {
#					# no json request - nothing to do
#				}
			return $decoded;
        }
    },
);


sub BUILD(){
	my ($self) = @_;
	my $empty = q{};
	my $colon = q{:};
	return $self->ua->default_header('Authorization' => 'Basic '.encode_base64($self->username.$colon.$self->pass , $empty));
}


=head1 SYNOPSIS

	use WebService::MIAB;

	my $miab = WebService::MIAB->new(
		username => 'adminuser@domain.com',
		pass => 'adminpasswd',
		host => 'domain.com',
	);

	my $users = $miab->get_users();
	my $result = $miab>create_user({
		email => 'bart.simpson@domain.com',
		password => 'EatMyShorts',
	});

=head1 DESCRIPTION

WebService::MIAB is a Perl module that manages user and alias addresses on a
Mail-in-a-box (MIAB) server.

You can list, create and remove user and alias addresses.

The API methods to the DNS system of MIAB is not implemented, yet.
Patches are welcome.

=head1 METHODES

=head2 User methods

The user methods are to handle plain email adresses on a MIAB server.
Each email address  is a user and has (limited) access to the MIAB server.

=head3 get_users

Returns all defined users in JSON format.

	my $users = $miab->get_users();

=cut


sub get_users{
	my ($self) = @_;

	my $result = $self->get($self->user_get_uri);

	return $result;
}


=head3 create_user

Creates a new user account. Expects the email address and the password in
the parameter hash.
Returns the answer from the webservice.

	my $result = $miab->create_user({
		email => 'bart.simpson@springfield.com',
		password => 'EatMyShorts'
	});

=cut


sub create_user{
	my ($self, $param) = @_;

	my $result = $self->post($self->user_add_uri,
				{
					email => $param->{email},
					password => $param->{password},
				},
				headers => { 'Content-Type' => 'application/x-www-form-urlencoded' },
	);

	return $result;
}


=head3 remove_user

Removes the email user account. Expects the email address in the parameter hash.
Returns the answer from the webservice.

	my result = $miab->remove_user({
		email => bart.simpson@springfield.com
	});

=cut


sub remove_user{
	my ($self, $param) = @_;

	my $result = $self->post($self->user_remove_uri,
				{
					email => $param->{email},
				},
				headers => { 'Content-Type' => 'application/x-www-form-urlencoded' },
	);

	return $result;
}


=head3 find_user

Returns a list of users records matching its forward_to record
to the given email_pattern and domain_pattern. The pattern can be a string
that is evaluated to a regexp or a regexp.

	my @users = $miab->find_user('email_pattern', qr/example.com/)

=cut


sub find_user {
	my ($self, $email_pattern, $domain_pattern) = @_;

	my @result;
	if ( !is_regexp($email_pattern) ) {
		$email_pattern = qr/$email_pattern/mxs;
	}
	if ($domain_pattern && !is_regexp($domain_pattern)) {
		$domain_pattern = qr/$domain_pattern/mxs;
	}

	my $users = $self->get_users();
	foreach ( @{$users} ) {
		if (!$domain_pattern || $_->{'domain'} =~ $domain_pattern) {
			foreach (@{$_->{'users'}}) {
				my $value = $_->{'email'};

				# filter list
				push( @result,
					grep {
						$_ && $_ =~ $email_pattern
					} ($value && 'ARRAY' eq ref $value)
						? @{$value}
						: ( $value )
				);
			}
		}
	}

	return @result;
}


=head2 Alias methods

=head3 get_aliases

Returns all aliases in JSON format.

	my $aliases = $miab->get_aliases();

=cut


sub get_aliases{
	my ($self) = @_;

	my $result = $self->get($self->alias_get_uri);

	return $result;
}


=head3 get_domains

Returns a list of all domains used in alias adresses.

	my @domains = $miab->get_domains();

=cut


sub get_domains{
	my ($self) = @_;

	my $aliases = $self->get_aliases();

	my @result;
	map {
		push( @result, $_->{'domain'} );
	} @{$aliases};

	return (uniq @result);
}


=head3 find_forward_to_aliases

Returns a list of alias records matching its forward_to record
to the given alias_pattern and domain_pattern. The pattern can be a string
that is evaluated to a regexp or a regexp.

	my @aliases = $miab->find_forward_to_aliases('alias_pattern', qr/example.com/);

=cut


sub find_forward_to_aliases {
	my ($self, $alias_pattern, $domain_pattern) = @_;

	return $self->_find_aliases_generic('forwards_to', $alias_pattern, $domain_pattern);
}


=head3 find_permitted_sender_aliases

Returns a list of alias records matching its permitted_sender record
to the given alias_pattern and domain_pattern. The pattern can be a string
that is evaluated to a regexp or a regexp.

	my @aliases = $miab->find_permitted_sender_aliases('alias_pattern', qr/example.com/);

=cut


sub find_permitted_sender_aliases {
	my ($self, $alias_pattern, $domain_pattern) = @_;

	return $self->_find_aliases_generic('permitted_senders', $alias_pattern, $domain_pattern);
}


=head3 find_aliases

Returns a list of alias records matching its address record the given
alias_pattern and domain_pattern. The pattern can be a string that is
evaluated to a regexp or a regexp.

	my @aliases = $miab->find_aliases('alias_pattern', qr/example.com/);

=cut


sub find_aliases {
	my ($self, $alias_pattern, $domain_pattern) = @_;

	return $self->_find_aliases_generic('address', $alias_pattern, $domain_pattern);
}


=head3 create_alias

Creates a new alias address.

	$miab->create_alias({
		address => 'bart.simpson@springfield.com',
		forwards_to => ['lisa.simpson@springfield.com','Maggie.simpson@springfield.com'],
		permitted_senders => ['Homer.simpson@springfield.com','Marge.simpson@springfield.com'],
	});

=cut


sub create_alias{
	my ($self, $param) = @_;
	my $empty = q{};
	my $point = q{,};

	if (defined $param->{forwards_to} && ref $param->{forwards_to} ne 'ARRAY'){
		$param->{forwards_to} = [$param->{forwards_to}];
	}
	if (defined $param->{permitted_senders} && ref $param->{permitted_senders} ne 'ARRAY'){
		$param->{permitted_senders} = [$param->{permitted_senders}];
	}

	my $forward_address_for_request = defined $param->{forwards_to}
		? join ($point, @{$param->{forwards_to}})
		: $empty;
	my $permitted_senders_for_request = defined $param->{permitted_senders}
		? join ($point, @{$param->{permitted_senders}})
		: $empty;

	# One alias parameter must exist
	if(!length($forward_address_for_request.$permitted_senders_for_request)){
		croak 'forwards_to or permitted_sender are required';
	}

	my $result = $self->post($self->alias_add_uri,
				{
					address => $param->{address},
					forwards_to => $forward_address_for_request,
					permitted_senders => $permitted_senders_for_request,
				},
				headers => { 'Content-Type' => 'application/x-www-form-urlencoded' },
	);
	return $result;
}


=head3 remove_alias

Permanently deletes an alias address.

  $miab->remove_alias({
		address => bart.simpson@springfield.com
	});

=cut

sub remove_alias{
	my ($self, $param) = @_;
	my $result = $self->post($self->alias_remove_uri,
				{
					address => $param->{address},
				},
				headers => { 'Content-Type' => 'application/x-www-form-urlencoded' }
	);

	return $result;
}


sub _find_aliases_generic {
	my ($self, $param_name, $alias_pattern, $domain_pattern) = @_;
	my @result;

	# force patterns to be a regex
	if (!is_regexp($alias_pattern)) {
		$alias_pattern = qr/$alias_pattern/mxs;
	}
	if ($domain_pattern && !is_regexp($domain_pattern)) {
		$domain_pattern = qr/$domain_pattern/mxs;
	}

	# get all aliases
	my $aliases = $self->get_aliases();

	# filter
	foreach (@{$aliases}) {
		if (!$domain_pattern || $_->{'domain'} =~ $domain_pattern)
		{
			# either $domain_pattern is undefined (param not given)
			# or the current domain matched the given $domain_pattern

			foreach (@{$_->{'aliases'}}) {
				my $value = $_->{$param_name};

				# filter list
				push( @result,
					grep {
						$_ && $_ =~ $alias_pattern
					} ($value && 'ARRAY' eq ref $value)
						? @{$value}
						: ( $value )
				);
			}
		}
	}
	return @result;
}

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-miab at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-MIAB>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::MIAB


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-MIAB>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-MIAB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-MIAB>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-MIAB/>

=back


=head1 AUTHORS

Alexander Scneider C<alexander.schneider@minati.de>, Mario Minati
C<mario.minati@minati.de>.

Currently maintained by Alexander Scneider C<alexander.schneider@minati.de>


=head1 LICENSE AND COPYRIGHT

Copyright 2018 Alexander Scneider C<alexander.schneider@minati.de>, Mario Minati
C<mario.minati@minati.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of WebService::MIAB
