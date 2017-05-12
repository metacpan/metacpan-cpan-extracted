# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Globals;

=pod

=head1 NAME

Wombat::Globals - global constants

=head1 SYNOPSIS

=head1 DESCRIPTION

This package contains constants that are global to Wombat.

=head1 CONSTANTS

=over

=item DEBUG

A flag determining whether messages of level 'DEBUG' are logged or not.

=cut

use constant DEBUG => 1;

=pod

=item FORM_TYPE_URLENCODED

The content type used for HTTP form data

=cut

use constant FORM_TYPE_URLENCODED => 'application/x-www-form-urlencoded';

=pod

=item SERVER_INFO

The server name and version

=cut

use constant SERVER_INFO => join '/', 'Wombat', $Wombat::VERSION;

=pod

=item SESSION_COOKIE_NAME

The name of the cookie used to transmit the session id between the
client and the server

=cut

use constant SESSION_COOKIE_NAME => 'PSESSIONID';

=pod

=item SESSION_PARAMETER_NAME

The name of the parameter used to transmit the session id between the
client and the server

=cut

use constant SESSION_PARAMETER_NAME => 'psessionid';

=pod

=back

=cut

1;
__END__

=pod

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut

