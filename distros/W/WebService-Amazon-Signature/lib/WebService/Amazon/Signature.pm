package WebService::Amazon::Signature;
# ABSTRACT: support for various ways to sign AWS requests
use strict;
use warnings;

our $VERSION = '0.002';

=head1 NAME

WebService::Amazon::Signature - handle signatures for Amazon webservices

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 my $req = 'GET / HTTP/1.1 ...';
 my $amz = WebService::Amazon::Signature->new(
  version    => 4,
  algorithm  => 'AWS4-HMAC-SHA256',
  scope      => '20110909/us-east-1/host/aws4_request',
  access_key => 'AKIDEXAMPLE',
  secret_key => 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY',
  host_port  => 'localhost:8000',
 );
 $amz->parse_request($req)
 my $signed_req = $amz->signed_request($req);

=head1 DESCRIPTION

Provides methods for signing requests and verifying responses for Amazon webservices,
as described in L<http://docs.aws.amazon.com/general/latest/gr/signing_aws_api_requests.html>.

Note that most of this is subject to change over the next few versions.

=cut

use WebService::Amazon::Signature::v4;

=head1 METHODS

=head2 new

Instantiate a signing object.

Will extract the C<version> named parameter, if it exists, and use that
to select the appropriate subclass for instantiation. Other parameters
are as defined by the subclass.

=over 4

=item * L<WebService::Amazon::Signature::v2/new>

=item * L<WebService::Amazon::Signature::v4/new>

=back

=cut

sub new {
	my $class = shift;
	my %args = @_;
	my $version = delete $args{version} || 4;
	my $pkg = 'WebService::Amazon::Signature::v' . $version;
	if(my $code = $pkg->can('new')) {
		$class = $pkg if $class eq __PACKAGE__;
		return $code->($class, %args)
	}
	die "No support for version $version";
}

1;

__END__

=head1 SEE ALSO

=over 4

=item * L<Net::Amazon::AWSSign> - handles the v2 signing process but not v4

=item * L<Net::Amazon::Signature> - also seems to be v2

=item * L<Net::Amazon::Signature::V4> - supports the v4 protocol (and passes the
AWS test suite cleanly), simpler interface than this one and easier to use if
you only want to sign the request and don't need access to any of the intermediate
steps.

=back

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2012-2013. Licensed under the same terms as Perl itself.
