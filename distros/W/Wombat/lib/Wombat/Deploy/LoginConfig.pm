# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Deploy::LoginConfig;

=pod

=head1 NAME

Wombat::Deploy::LoginConfig - login-config deployment descriptor element
class

=head1 SYNOPSIS

=head1 DESCRIPTION

Representation of a login configuration object for a web application,
as specified in a I<login-config> element in the deployment
descriptor.

=cut

use fields qw(authMethod errorPage loginPage realmName);
use strict;
use warnings;

use URI::Escape ();

=pod

=head1 CONSTRUCTOR

=over

=item new()

Construct and return a B<Wombat::Deploy::LoginConfig> instance,
initializing fields appropriately.

=back

B<Parameters:>

=over

=item $authMethod

the authentication method

=item $realmName

the realm name

=item $loginPage

the URI of the login page

=item $errorPage

the URI of the error page

=back

=cut

sub new {
    my $self = shift;
    my $authMethod = shift;
    my $realmName = shift;
    my $loginPage = shift;
    my $errorPage = shift;

    $self = fields::new($self) unless ref $self;

    $self->{authMethod} = $authMethod;
    $self->{errorPage} = $errorPage;
    $self->{loginPage} = $loginPage;
    $self->{realmName} = $realmName;

    return $self;
}

=pod

=head1 ACCESSOR METHODS

=over

=item getAuthMethod()

Return the authentication method to use for application login.

=cut

sub getAuthMethod {
    my $self = shift;

    return $self->{authMethod};
}

=pod

=item setAuthMethod($authMethod)

Set the authentication method to use for application login. Must be
one of I<BASIC>, I<DIGEST>, I<FORM>, or I<CLIENT-CERT>.

B<Parameters:>

=over

=item $authMethod

the authentication method

=back

=cut

sub setAuthMethod {
    my $self = shift;
    my $authMethod = shift;

    $self->{authMethod} = $authMethod;

    return 1;
}

=pod

=item getErrorPage()

Return the URI of the error page for form login.

=cut

sub getErrorPage {
    my $self = shift;

    return $self->{errorPage};
}

=pod

=item setErrorPage($errorPage)

Set the URI of the error page for form login. The URI must be
specified relative to the context (ie beginning with a '/').

B<Parameters:>

=over

=item $errorPage

the error page URI

=back

=cut

sub setErrorPage {
    my $self = shift;
    my $errorPage = shift;

    $self->{errorPage} = URI::Escape::uri_unescape($errorPage);

    return 1;
}

=pod

=item getLoginPage()

Return the URI of the login page for form login.

=cut

sub getLoginPage {
    my $self = shift;

    return $self->{loginPage};
}

=pod

=item setLoginPage($loginPage)

Set the URI of the login page for form login. The URI must be
specified relative to the context (ie beginning with a '/').

B<Parameters:>

=over

=item $loginPage

the login page URI

=back

=cut

sub setLoginPage {
    my $self = shift;
    my $loginPage = shift;

    $self->{loginPage} = URI::Escape::uri_unescape($loginPage);

    return 1;
}

=pod

=item getRealmName()

Return the name of the realm in which users will be authenticated.

=cut

sub getRealmName {
    my $self = shift;

    return $self->{realmName};
}

=pod

=item setRealmName($realmName)

Set the name of the realm in which users will be authenticated.

B<Parameters:>

=over

=item $realmName

the name of the realm

=back

=cut

sub setRealmName {
    my $self = shift;
    my $realmName = shift;

    $self->{realmName} = $realmName;

    return 1;
}

=pod

=cut

1;
__END__

=pod

=back

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
