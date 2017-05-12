package VUser::Google::ProvisioningAPI;
use warnings;
use strict;

# Copyright (C) 2007 Randy Smith, perlstalker at vuser dot org
# Copyright (C) 2006 by Johan Reinalda, johan at reinalda dot net

use vars qw($VERSION);

our $VERSION = '0.25';

use Carp;

sub new
{
    my ($obj, $domain, $admin, $passwd, $api_version) = @_;
    my $class = ref($obj) || $obj;

    # If the API version is not specified assume 1.0 to remain compatible
    # with VUser::Google::ProvisioningAPI 0.11
    if (not defined $api_version or $api_version eq '1.0') {
        require VUser::Google::ProvisioningAPI::V1_0;
        return VUser::Google::ProvisioningAPI::V1_0->new($domain, $admin, $passwd);
    } elsif ($api_version eq '2.0') {
        require VUser::Google::ProvisioningAPI::V2_0;
        return VUser::Google::ProvisioningAPI::V2_0->new($domain, $admin, $passwd);
    } else {
        croak "Unknown API version: $api_version";
    }
}

#print out debugging to STDERR if debug is set
sub dprint
{
	my $self = shift();
	my($text) = shift if (@_);
	if( $self->{debug} and defined ($text) ) {
		print STDERR $text . "\n";
	}
}

1;

__END__

=head1 NAME

VUser::Google::ProvisioningAPI - Perl module that implements the Google Apps for Your Domain Provisioning API

=head1 SYNOPSIS

  use VUser::Google::ProvisioningAPI;
  my $google = new VUser::Google::ProvisioningAPI($domain,$admin,$password, $api_version);

  $google->CreateAccount($userName, $firstName, $lastName, $password);
  $google->RetrieveAccount($userName);

=head1 REQUIREMENTS

VUser::Google::ProvisioningAPI requires the following modules to be installed:

=over

=item

C<LWP::UserAgent>

=item

C<HTTP::Request>

=item

C<Encode>

=item

C<XML::Simple>

=back

=head1 DESCRIPTION

B<VUser::Google::ProvisioningAPI::* is depricated in favor of VUser::Google::ApiProtocol and VUser::Google::Provisioning.>

VUser::Google::ProvisioningAPI provides a simple interface to the Google Apps for Your Domain Provisioning API.
It uses the C<LWP::UserAgent> module for the HTTP transport, and the C<HTTP::Request> module for the HTTP request and response.

=head1 CONSTRUCTOR

new ( $domain, $admin, $adminpassword [,$api_version] )

This is the constructor for a new VUser::Google::ProvisioningAPI object.
$domain is the domain name registered with Google Apps For Your Domain,
$admin is an account in the above domain that has the right to manage that domain,
$adminpassword is the password for that account and $api_version is the
version of the Google Provisioning API you wish to use. At this time, only
'1.0' and '2.0' are supported.

Note that the constructor will NOT attempt to perform the 'ClientLogin' call to the Google Provisioning API.
Authentication happens automatically when the first API call is performed. The token will be remembered for the duration of the object, and will be automatically refreshed as needed.
If you want to verify that you can get a valid token before performing any operations, follow the constructor with a call to IsAuthenticated() as such:

        print "Authentication OK\n" unless not $google->IsAuthenticated();

=head1 METHODS

The methods provided by the object will vary based on the version of the API.
Please see the perldocs for specific version you are using. For example,
C<perldoc VUser::Google::ProvisioningAPI::1.0>.

=head1 EXPORT

None by default.

=head1 SEE ALSO

For support, see the Google Group at
http://groups.google.com/group/apps-for-your-domain-apis

L<VUser::Google::ProvisioningAPI::1.0>

L<VUser::Google::ProvisioningAPI::2.0>

=head1 BUGS

Please report bugs or feature requests at
http://code.google.com/p/vuser/issues/list.

=head1 AUTHORS

Johan Reinalda, johan at reinalda dot net

Randy Smith, perlstalker at vuser dot net

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Johan Reinalda, johan at reinalda dot net

Copyright (C) 2007 Randy Smith, perlstalker and vuser dot org

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

If you make useful modification, kindly consider emailing then to me for inclusion in a future version of this module.

=cut
