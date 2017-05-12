package WebService::Amazon::IAM;
# ABSTRACT: IAM role implementation
use strict;
use warnings;

our $VERSION = '0.002';

=head1 NAME

WebService::Amazon::IAM - basic Amazon IAM role functionality

=head1 VERSION

version 0.002

=head1 DESCRIPTION

Coming soon.

=cut

use JSON::MaybeXS;
use Time::Moment;

use Log::Any qw($log);

=head1 METHODS

=cut

sub new {
	my ($class, %args) = @_;
	bless {
		# This is the address on the internal network used
		# for all IAM-related functionality.
		base_uri => 'http://169.254.169.254',
		%args
	}, $class
}

=head2 active_roles

Retrieves a list of the active roles in this AWS instance.

Currently only one role is supported per server (!), so this will just
resolve to a single string.

 is($iam->active_roles->get, 'some_role_name');

=cut

sub active_roles {
	my ($self) = @_;
	my $uri = $self->build_uri('/latest/meta-data/iam/security-credentials/');
	$log->debugf("Requesting list of roles from [%s]", "$uri");
	$self->ua->get($uri)
}

=head2 credentials_for_role

Resolves to the credentials for the given role.

 my $creds = $iam->credentials_for_role('some_role');
 say "Access key: " . $creds->{access_key};
 say "Secret key: " . $creds->{secret_key};
 say "Token:      " . $creds->{token};
 say "Will expire at " . strftime '%Y-%m-%d %H:%M:%S', localtime $creds->{expiry};

=cut

sub credentials_for_role {
	my ($self, $role) = @_;
	my $uri = $self->build_uri('/latest/meta-data/iam/security-credentials/' . $role);
	$log->debugf("Requesting credentials from [%s]", "$uri");
	$self->ua->get($uri)->then(sub {
		my $data = $self->json->decode(shift);
		return Future->fail("Invalid return code", iam => $data->{Code}, $data) unless $data->{Code} eq 'Success';
		return Future->fail("Invalid access key type", iam => $data->{Type}, $data) unless $data->{Type} eq 'AWS-HMAC';
		my $expiry = Time::Moment->from_string($data->{Expiration})->epoch;
		Future->wrap({
			access_key => $data->{AccessKeyId},
			secret_key => $data->{SecretAccessKey},
			token      => $data->{Token},
		}, $expiry)
	})
}

sub base_uri { shift->{base_uri} }
sub build_uri { my $self = shift; URI->new(join '', $self->base_uri, @_) }
sub json { shift->{json} ||= JSON::MaybeXS->new }

sub ua { shift->{ua} // die "no user agent provided" }

1;

__END__

=head1 SEE ALSO

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2014. Licensed under the same terms as Perl itself.
