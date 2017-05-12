#!/usr/bin/env perl
use warnings;
use strict;

package Test::OpenID::Consumer;
use Net::OpenID::Consumer;
use LWP::UserAgent::Paranoid;
use Cache::FileCache;
use base qw/Test::HTTP::Server::Simple HTTP::Server::Simple::CGI/;

our $VERSION = '0.03';

=head1 NAME

Test::OpenID::Consumer - setup a simulated OpenID consumer

=head1 SYNOPSIS

Test::OpenID::Consumer will provide a consumer to test your OpenID server
against.  To use it, do something like this:

   use Test::More tests => 1;
   use Test::OpenID::Consumer;
   my $consumer = Test::OpenID::Consumer->new;
   my $url_root = $consumer->started_ok("server started ok");

   $consumer->verify_ok('http://server/identity/openid');

=cut

use Test::Builder;
my $Tester = Test::Builder->new;

=head1 METHODS

=head2 new

Create a new test OpenID consumer

=cut

sub new {
    my $class = shift;
    my $port  = shift;

    $port = int(rand(5000) + 10000) if not defined $port;
    
    my $self = $class->SUPER::new( $port );

    my $ua = LWP::UserAgent::Paranoid->new;
    $ua->whitelisted_hosts( qw/localhost 127.0.0.1/ );
    $self->ua( $ua );

    return $self;
}

=head2 ua [OBJECT]

Get/set the LWP useragent to use for fetching pages.  Defaults to an instance of
L<LWP::UserAgent::Paranoid> with localhost whitelisted.

=cut

sub ua {
    my $self = shift;
    $self->{'ua'} = shift if @_;
    return $self->{'ua'};
}

=head2 started_ok

Test whether the consumer's server started, and if it did, return the URL
it's at.

=head1 METHODS

=head2 verify_ok URL [TEST_NAME]

Attempts to verify the given OpenID.  At the moment, the verification MUST
NOT require any logging in or setup, but it may be supported in the future.

=cut

sub verify_ok {
    my $self    = shift;
    my $openid  = shift;
    my $text    = shift || 'verified OpenID';

    my ( $failed, $data ) = $self->_verify( $openid );

    if ( $failed ) {
        $Tester->ok( 0, $text );
        $self->_diag( $data );
    }
    else {
        $Tester->ok( 1, $text );
    }
}

=head2 verify_cancelled URL [TEST_NAME]

Like L<verify_ok>, but the test passes if the OpenID verification process is
cancelled (i.e. the user chose not to trust the authenticating site).

=cut

sub verify_cancelled {
    my $self    = shift;
    my $openid  = shift;
    my $text    = shift || 'verification cancelled';

    my ( $failed, $data ) = $self->_verify( $openid );

    if ( $failed ) {
        if ( $failed == 2 && $data->status_line =~ /canceled/i ) {
            $Tester->ok( 1, $text );
        }
        else {
            $Tester->ok( 0, $text );
            $self->_diag( $data );
        }
    }
    else {
        $Tester->ok( 0, $text );
        $Tester->diag( "successfully verified OpenID" );
    }
}

=head2 verify_invalid URL [TEST_NAME]

Like L<verify_ok> but the test passes if the OpenID client is unable to find
a valid OpenID identity at the URL given.

=cut

sub verify_invalid {
    my $self    = shift;
    my $openid  = shift;
    my $text    = shift || 'invalid OpenID';

    my ( $failed, $data ) = $self->_verify( $openid );

    if ( $failed == 1 ) {
        $Tester->ok( 1, $text );
    }
    else {
        $Tester->ok( 0, $text );
        $self->_diag( $data );
    }
}

sub _diag {
    my $self = shift;
    my $data = shift;

    if ( ref $data ) {
        $Tester->diag( "Error:   " . $data->status_line );
        $Tester->diag( "Content: " . $data->content )
            if $data->content;
    }
    else {
        $Tester->diag( $data );
    }
}

sub _verify {
    my $self   = shift;
    my $openid = shift;

    my $baseurl = 'http://'
                  . ($self->host || 'localhost')
                  . ':' . ($self->port || '80');

    my $csr = Net::OpenID::Consumer->new(
        ua    => $self->ua,
        cache => Cache::FileCache->new,
        args  => { },
        consumer_secret => 'secret',
        required_root   => $baseurl
    );

    my $claimed = $csr->claimed_identity( $openid );

    if ( not defined $claimed ) {
        return ( 1, $csr->err );
    }

    $openid = $claimed->claimed_url;

    my $check_url = $claimed->check_url(
        return_to  => "$baseurl/return",
        trust_root => $baseurl,
        delayed_return => 0
    );

    my $res = $self->ua->get( $check_url );

    if ( not $res->is_success ) {
        return ( 2, $res );
    }
    else {
        return ( 0, undef );
    }
}

=head1 INTERAL METHODS

These methods implement the HTTP server (see L<HTTP::Server::Simple>)
that the consumer uses.  You shouldn't call them.

=head2 handle_request

=cut

sub handle_request {
    my $self = shift;
    my $cgi = shift;

    if ( $ENV{'PATH_INFO'} eq '/return' ) {
        # We're dealing with the return path
        
        my $csr = Net::OpenID::Consumer->new(
            ua    => $self->ua,
            cache => Cache::FileCache->new,
            args  => $cgi,
            consumer_secret => 'secret'
        );

        if ( my $setup = $csr->user_setup_url ) {
            print "HTTP/1.0 412 Setup required\r\n";
            print "Content-Type: text/plain\r\n\r\n";
            print "verification required setup: $setup\n";
            return;
        }
        elsif ( $csr->user_cancel ) {
            print "HTTP/1.0 401 Canceled\r\n";
            print "Content-Type: text/plain\r\n\r\n";
            print "verification canceled\n";
            return;
        }

        my $ident = $csr->verified_identity;

        if ( not defined $ident ) {
            print "HTTP/1.0 401 Failed authentication\r\n";
            print "Content-Type: text/plain\r\n\r\n";
            print $csr->err, "\n";
        }
        else {
            print "HTTP/1.0 200 OK\r\n";
            print "Content-Type: text/plain\r\n\r\n";
            print "verification succeeded\n";
        }
    }
    else {
        print "HTTP/1.0 200 OK\r\n";
        print "Content-Type: text/html\r\n\r\n";
        print <<"        END";
<html>
  <body>
    <p>This is an OpenID consumer.  It needs an HTTP server for testing.</p>
  </body>
</html>
        END
    }
}

=head1 AUTHORS

Thomas Sibley <trs@bestpractical.com>

=head1 COPYRIGHT

Copyright (c) 2007, Best Practical Solutions, LLC. All rights reserved.

=head1 LICENSE

You may distribute this module under the same terms as Perl 5.8 itself.

=cut

1;
