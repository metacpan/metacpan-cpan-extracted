# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Authenticator::BasicAuthenticator;

=pod

=head1 NAME

Wombat::Authenticator::BasicAuthenticator - HTTP Basic authenticator

=head1 SYNOPSIS

=head1 DESCRIPTION

Implementation of HTTP Basic authentication as specified in RFC 2617.

=cut

use base qw(Wombat::Authenticator::AuthenticatorBase);
use fields qw();
use strict;
use warnings;

use MIME::Base64 ();
use Servlet::Http::HttpServletResponse ();

use constant METHOD_BASIC => 'BASIC';

=pod

=head1 PUBLIC METHODS

=over

=item authenticate($request, $response, $config)

Authenticate the user making this request, based on the specified
login configuration. Return true if any specified constraint has been
satisfied, or false if we have created a response already.

B<Parameters:>

=over

=item $request

the B<Wombat::HttpRequest> being processed

=item $response

the B<Wombat::HttpResponse> being created

=item $constraint

the B<Wombat::Deploy::LoginConfig> describing the authentication
procedure

=back

B<Throws:>

=over

=item B<Servlet::Util::IOException>

if an input or output error occurs

=back

=cut

sub authenticate {
    my $self = shift;
    my $request = shift;
    my $response = shift;
    my $config = shift;

    my $freq = $request->getRequest();
    my $fres = $request->getResponse();

    my $principal = $freq->getUserPrincipal();
    return 1 if $principal;

    my $authorization = $request->getAuthorization();
    if ($authorization) {
        $principal = $self->findPrincipal($authorization,
                                          $self->getContainer()->getRealm());
        if ($principal) {
            $self->register($request, $response, $principal, METHOD_BASIC);
            return 1;
        }
    }

    my $realmName = $config->getRealmName() ||
        join ':', $freq->getServerName(), $freq->getServerPort();
    $fres->setHeader('WWW-Authenticate', qq(Basic realm="$realmName"));

    my $code = Servlet::Http::HttpServletResponse::SC_UNAUTHORIZED;
    $fres->setStatus($code);

    return undef;
}

=pod

=item getName()

Return a short name for this Authenticator implementation.

=cut

sub getName {
    return 'Basic Authenticator';
}

=pod

=back

=cut

# private methods

sub findPrincipal {
    my $self = shift;
    my $authorization = shift;
    my $realm = shift;

    return undef unless $authorization;
    return undef unless $authorization =~ s|^Basic ||;

    my $unencoded = MIME::Base64::decode_base64($authorization);
    my ($username, $password) = split /:/, $unencoded;

    return $realm->authenticate($username, $password);
}

1;
__END__

=pod

=head1 SEE ALSO

L<Servlet::Util::Exception>,
L<Wombat::Authenticator::AuthenticatorBase>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
