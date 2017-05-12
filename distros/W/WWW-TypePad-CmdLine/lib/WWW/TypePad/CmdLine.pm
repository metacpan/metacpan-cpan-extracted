package WWW::TypePad::CmdLine;

use strict;
use 5.008_001;
our $VERSION = '0.02';

use Config::Tiny;
use File::HomeDir;
use File::Spec;
use Getopt::Long qw( :config pass_through );
use WWW::TypePad;

our $Config = File::Spec->catfile(
    File::HomeDir->my_data, '.www-typepad-info'
);
our $ConfigObj;

GetOptions( 'config=s' => \$Config );

sub config_file {
    my $class = shift;
    return $Config;
}

sub config {
    my $class = shift;
    return $ConfigObj ||= Config::Tiny->read( $class->config_file );
}

sub initialize {
    my $class = shift;
    my( %p ) = @_;

    my $tp;

    my $config = $class->config;
    if ( !defined $config && $p{requires_auth} ) {
        $tp = WWW::TypePad->new(
            ( $ENV{TP_HOST} ? ( host => $ENV{TP_HOST} ) : () ),
            consumer_key    => $ENV{TP_CONSUMER_KEY},
            consumer_secret => $ENV{TP_CONSUMER_SECRET},
        );

        die "TP_CONSUMER_KEY and TP_CONSUMER_SECRET required in ENV"
            unless $tp->consumer_key && $tp->consumer_secret;

        $class->new_config( $tp );
    } elsif ( $p{requires_auth} ) {
        $tp = WWW::TypePad->new(
            ( $config->{app}{host} ? ( host => $config->{app}{host} ) : () ),
            consumer_key        => $config->{app}{consumer_key},
            consumer_secret     => $config->{app}{consumer_secret},
            access_token        => $config->{auth}{access_token},
            access_token_secret => $config->{auth}{access_token_secret},
        );
    } else {
        $tp = WWW::TypePad->new;
    }

    return $tp;
}

sub new_config {
    my $class = shift;
    my( $tp ) = @_;

    $ConfigObj = Config::Tiny->new;

    print <<MSG;

Welcome to WWW::TypePad! Before we get started, we'll need to link our
local configuration to your TypePad account.

First, you'll need to authorize this application in your web browser.

MSG

    my $auth_uri = $tp->oauth->get_authorization_url(
        callback => 'oob',
    );

    if ( -x '/usr/bin/open' ) {
        print <<MSG;
We're opening this URL in your web browser:

$auth_uri
MSG
        system 'open', $auth_uri;
    } else {
        print <<MSG;
Open this URL in your web browser:

$auth_uri
MSG
    }

    print <<MSG;

When you've allowed access to this application, you'll get a verifier
code that we'll need to complete the handshake.

MSG

    print "Enter the verifier code: ";
    chomp( my $verifier = <STDIN> );
    
    my( $access_token, $access_token_secret ) =
        $tp->oauth->request_access_token( verifier => $verifier );
    $tp->access_token( $access_token );
    $tp->access_token_secret( $access_token_secret );
    
    my $obj = $tp->users->get( '@self' );
    die 'Request for @self gave us empty result'
        unless $obj;

    print <<MSG;

Great! We've identified you as "$obj->{displayName}".

We're going to save your configuration in the following file, in case you'd
like to access or change it in the future:

    $Config

MSG

    $ConfigObj->{app} = {
        ( $tp->host ne 'api.typepad.com' ? ( host => $tp->host ) : () ),
        consumer_key    => $tp->consumer_key,
        consumer_secret => $tp->consumer_secret,
    };

    $ConfigObj->{auth} = {
        access_token        => $access_token,
        access_token_secret => $access_token_secret,
    };

    $ConfigObj->write( $class->config_file );
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::TypePad::CmdLine - Helper library for writing WWW::TypePad apps

=head1 SYNOPSIS

    use WWW::TypePad::CmdLine;
    
    # Returns a WWW::TypePad instance, initialized with the necessary
    # consumer key/secret and access token/secret.
    my $tp = WWW::TypePad::CmdLine->initialize( requires_auth => 1 );

    # Then, you can do something like this:
    my $user = $tp->users->get( '@self' );

=head1 DESCRIPTION

I<WWW::TypePad::CmdLine> is a helper library for writing command-line
applications that use I<WWW::TypePad>. It handles the one-time OAuth
authentication flow, config file setup, and storage of access tokens.

Tokens and configuration are stored between runs of your application in
a config file. By default, that config file will be located at:

    File::Spec->catfile( File::HomeDir->my_data, '.www-typepad-info' )

I<File::HomeDir-E<gt>my_data> is an OS-aware data directory. On OS X, for
example, it's F<~/Library/Application Support>.

I<WWW::TypePad::CmdLine> automatically adds a C<--config> command-line
option for your application, so that it's easy to support different locations
for configuration files.

On the first execution of a script using I<WWW::TypePad::CmdLine>, you'll
need to set the C<TP_CONSUMER_KEY> and C<TP_CONSUMER_SECRET> environment
variables to the consumer key and secret for your TypePad application,
respectively. You can also set C<TP_HOST> to a host other than
C<api.typepad.com>. Once the configuration file is saved after the first
call to I<initialize>, future runs of your script won't require these
environment variables.

=head1 USAGE

=head2 WWW::TypePad::CmdLine->initialize( %param )

Initializes and returns a new I<WWW::TypePad> object, initialized with all
of the necessary information to start using it for authenticated requests
(see C<requires_auth>).

The configuration and tokens are stored between runs of your application in
a config file (see above). If the config file doesn't exist, and your
application requires authentication (see C<requires_auth>), I<initialize>
will send the user through the OAuth authentication flow.

When control returns to your application from calling I<initialize>, you'll
have a I<WWW::TypePad> object initialized with everything you need to make
authenticated (or non-authenticated) requests.

I<%param> can contain:

=over 4

=item * requires_auth

Controls whether or not your application requires an authenticated user
in order to function. This controls whether, in the absence of a configuration
file, I<initialize> will send the user through the OAuth authentication flow.

=back

=head1 AUTHOR

Benjamin Trott E<lt>ben@sixapart.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<WWW::TypePad>

=cut
