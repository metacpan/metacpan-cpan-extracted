package cPanel::APIClient;

use strict;
use warnings;

our $VERSION = '0.08';

=encoding utf-8

=head1 NAME

cPanel::APIClient - L<cPanel|http://cpanel.com> APIs, à la TIMTOWTDI!

=head1 SYNOPSIS

Create a L<cPanel::APIClient::Service::cpanel> object
to call cPanel APIs:

    my $cpanel = cPanel::APIClient->create(
        service => 'cpanel',
        transport => [ 'CLISync' ],
    );

    my $resp = $cpanel->call_uapi( 'Email', 'list_pops' );

    my $pops_ar = $resp->get_data();

Create a L<cPanel::APIClient::Service::whm> object
to call WHM APIs:

    my $whm = cPanel::APIClient->create(
        service => 'whm',
        transport => [ 'CLISync' ],
    );

    my $resp = $whm->call_api1( 'listaccts' );

    my $accts_ar = $resp->get_data();

=head1 DESCRIPTION

cPanel & WHM exposes a number of ways to access its APIs: different transport
mechanisms, different authentication schemes, etc. This library provides
client logic with sufficient abstractions to accommodate most supported
access mechanisms via a unified interface.

This library intends to supersede L<cPanel::PublicAPI> as the preferred way
to access cPanel & WHM’s APIs from Perl. It can also serve as a model for
similar client libraries in other languages.

=head1 FEATURES

=over

=item * Fully object-oriented.

=item * Can use blocking or non-blocking I/O. Non-blocking I/O implementation
works with almost any modern Perl event loop interface.

=item * Uses minimal dependencies: no L<Moose> &c.

=item * Extensively tested.

=item * Can run in pure Perl.

=back

=head1 CHARACTER ENCODING

cPanel & WHM’s API is character-set-agnostic. All text that you give to this
library should thus be encoded to binary, and all strings that you’ll receive
back will be binary.

This means that if you character-decode your inputs—as L<perlunitut>
recommends—then you’ll need to encode your strings back to bytes before
giving them to this module.

Use of UTF-8 encoding is B<strongly> recommended!

=head1 FUNCTIONS

=head2 $client = cPanel::APIClient->create( %OPTS )

A factory function that creates a “client” object that your code can
use to call the APIs.

%OPTS are:

=over

=item * C<service> - Required. The service that exposes the API(s) to call.
This controls the class of the returned object. Recognized values are:

=over

=item * C<cpanel> - Function will return a L<cPanel::APIClient::Service::cpanel>
instance.

=item * C<whm> - Function will return a L<cPanel::APIClient::Service::whm>
instance.

=back

=item * C<transport> - Required. An array reference that describes the
transport mechanism to use. The first member of this array names the mechanism;
remaining arguments are key-value pairs of attributes to give to the
mechanism class’s constructor.

Currently supported mechanisms are:

=over

=item * L<cPanel::APIClient::Transport::HTTPSync> (C<HTTPSync>) -
Synchronous HTTP requests.

=item * L<cPanel::APIClient::Transport::CLISync> (C<CLISync>) -
Synchronous local requests via cPanel & WHM’s command-line API tools.

=item * L<cPanel::APIClient::Transport::NetCurlPromiser> (C<NetCurlPromiser>) -
Asynchronous HTTP requests via
L<Net::Curl::Promiser>, which can use any event loop interface.
As of this writing it supports L<IO::Async>, L<AnyEvent>, and L<Mojolicious>
out-of-the-box.

=item * L<cPanel::APIClient::Transport::MojoUserAgent> (C<MojoUserAgent>) -
Asynchronous HTTP requests via L<Mojo::UserAgent> (pure Perl).

=back

Which of the above to use will depend on your needs. If your application
is local to the cPanel & WHM server you might find it easiest to use
C<CLISync>. For HTTP C<NetCurlPromiser> offers the best flexibility
and (probably) speed, whereas C<MojoUserAgent> and C<HTTPSync> can run in
pure Perl (assuming you have L<Net::SSLeay>).

There currently is no documentation for how to create a 3rd-party transport
mechanism (e.g., if you want to use a different HTTP library). Submissions
via pull request will be evaluated on a case-by-case basis.

=item * C<credentials> - Some transports require this; others don’t.
The recognized schemes are:

=over

=item * C<username> & C<api_token> - Authenticate with an API token

=item * C<username> & C<password> - Authenticate with a password

=item * C<username>, C<password>, & C<tfa_token> - Authenticate with a
password and two-factor authentication (2FA) token.

=item * C<username> only - Implicit authentication, only usable for local
transports.

=back

=back

Depending on the C<service> given, this function returns an instance of
either L<cPanel::APIClient::Service::cpanel> or
L<cPanel::APIClient::Service::whm>.

=cut

my @_REQUIRED = ( 'service', 'transport' );

sub create {

    # We don’t need the class, but we mandate arrow syntax rather
    # than static because it seems more consistent with Perl programmers’
    # expectations of what it looks like to call a function whose purpose
    # is to create an object.
    shift;

    my (%opts) = @_;

    my @missing = grep { !defined $opts{$_} } @_REQUIRED;
    die "Missing: @missing" if @missing;

    my $creds = delete $opts{'credentials'};

    my ( $svc, $transport ) = delete @opts{@_REQUIRED};

    if ( my @extra = sort keys %opts ) {
        die "Extra: @extra";
    }

    my $full_ns = "cPanel::APIClient::Service::$svc";
    _require($full_ns);

    my $authn = $creds && _parse_creds($creds);

    $transport = _parse_transport( $transport, $authn, $svc );

    return $full_ns->new( $transport, $authn );
}

sub _parse_transport {
    my ( $transport, $authn, $service_name ) = @_;

    if ( 'ARRAY' ne ref $transport ) {
        die "“transport” should be an ARRAY reference, not $transport!";
    }

    my ( $module, @args ) = (
        @$transport,
        service_name => $service_name,
    );

    $module = "cPanel::APIClient::Transport::$module";
    _require($module);

    if ( $module->NEEDS_CREDENTIALS() && !$authn ) {
        die "Transporter “$transport” requires credentials!";
    }

    return $module->new( $authn, @args );
}

sub _require {
    my ($full_ns) = @_;

    die if !eval "require $full_ns; 1";
}

sub _parse_creds {
    my ($creds_hr) = @_;

    my %creds_copy = %$creds_hr;

    my $username = delete $creds_copy{'username'};

    if ( !defined $username ) {
        die "Credentials need “username”!";
    }

    my ( @extras, $class );

    if ( exists $creds_copy{'api_token'} ) {
        @extras = ('api_token');
        $class  = 'cPanel::APIClient::Authn::Token';
    }
    elsif ( exists $creds_copy{'password'} ) {
        @extras = ('password');

        if ( exists $creds_copy{'tfa_token'} ) {
            push @extras, 'tfa_token';
            $class = 'cPanel::APIClient::Authn::Password2FA';
        }
        else {
            $class = 'cPanel::APIClient::Authn::Password';
        }
    }
    else {
        $class = 'cPanel::APIClient::Authn::Username';
    }

    for my $key (@extras) {
        my $val = delete $creds_copy{$key};
        if ( !defined $val ) {
            die "Undefined “$key” is invalid!";
        }
    }

    die "Bad “credentials”!" if %creds_copy;

    _require($class);

    return $class->new( $username, @{$creds_hr}{@extras} );
}

=head1 LICENSE

Copyright 2020 cPanel, L. L. C. All rights reserved. L<http://cpanel.net>

This is free software; you can redistribute it and/or modify it under the
same terms as Perl itself. See L<perlartistic>.

=cut

1;
