#!perl
use warnings;
use strict;

package Test::OpenID::Server;
use Net::OpenID::Server;
use base qw/Test::HTTP::Server::Simple HTTP::Server::Simple::CGI/;

our $VERSION = '0.03';

=head1 NAME

Test::OpenID::Server - setup a simulated OpenID server

=head1 SYNOPSIS

Test::OpenID::Server will provide a server to test your OpenID client
against.  To use it, do something like this:

   use Test::More tests => 1;
   use Test::OpenID::Server;
   my $server   = Test::OpenID::Server->new;
   my $url_root = $server->started_ok("server started ok");

Now you can run your OpenID tests against the URL in C<$url_root>.  Identities
are any URL in the form of C<$url_root . "/foo">.  There is one special
identity: C</unknown>.  This identity will causes the OpenID server
to return a non-identity page (which will mean the OpenID client won't find an
identity).  Every other identity will return a successful authentication.

=head1 METHODS

=head2 new

Create a new test OpenID server

=cut

sub new {
    my $class = shift;
    my $port  = shift;

    $port = int(rand(5000) + 10000) if not defined $port;
    
    my $self = $class->SUPER::new( $port );
    return $self;
}

=head2 started_ok

Test whether the server started, and if it did, return the URL it's
at.

=cut

#=head2 add_identity NAME
#
#Adds an OpenID identity to the server and returns the identity's URL.
#
#=cut
#
#sub add_identity {
#    my $self = shift;
#    my $id   = shift;
#    
#    if ( not $self->_is_identity( $id ) ) {
#        $self->{_identities}{$id} = {};
#    }
#    return $self->_identity_url( $id );
#}

#=head2 delete_identity NAME
#
#Removes an OpenID identity from the server.
#
#=cut
#
#sub delete_identity {
#    my $self = shift;
#    my $id   = shift;
#    delete $self->{_identities}{$id};
#}

sub _is_identity {
    my $self = shift;
    my $id   = shift;
    return lc $id ne 'unknown' ? $id : undef;
}

sub _identity_url {
    my $self = shift;
    my $id   = shift;
    return "http://$ENV{HTTP_HOST}/$id";
}

#=head2 modify_trust NAME, URL, BOOLEAN
#
#Sets whether or not URL is trusted by NAME.
#
#=cut
#
#sub modify_trust {
#    my $self = shift;
#    my ( $id, $url, $trusted ) = @_;
#    $self->{_identities}{$id}{$url} = $trusted;
#}

=head1 INTERAL METHODS

These methods implement the HTTP server (see L<HTTP::Server::Simple>).
You shouldn't call them.

=head2 handle_request

=cut

sub handle_request {
    my $self = shift;
    my $cgi = shift;

    if ( $ENV{'PATH_INFO'} eq '/openid.server' ) {
        # We're dealing with the OpenID server endpoint
        
        my $nos = Net::OpenID::Server->new(
            args          => $cgi,
            get_user      => \&_get_user,
            is_identity   => sub { $self->_is_identity( $_[1] ) },
            is_trusted    => sub { return 1 },
            server_secret => 'squeamish_ossifrage',
            setup_url     => "http://example.com/non-existant",
        );
        my ($type, $data) = $nos->handle_page( redirect_for_setup => 1 );
        if ($type eq "redirect") {
            print "HTTP/1.0 301 REDIRECT\r\n";    # probably OK by now
            print "Location: $data\r\n\r\n";
        } else {
            print "HTTP/1.0 200 OK\r\n";    # probably OK by now
            print "Content-Type: $type\r\n\r\n$data";
        }
    }
    else {
        # We're dealing with an normal page request
        print "HTTP/1.0 200 OK\r\n";
        print "Content-Type: text/html\r\n\r\n";
        
        my ($id) = $ENV{'PATH_INFO'} =~ m{/(.*)$};

        if ( $self->_is_identity( $id ) ) {
            print <<"            END";
<html>
  <head>
    <link rel="openid.server" href="http://$ENV{'HTTP_HOST'}/openid.server" />
  </head>
  <body>
    <p>OpenID identity page for $id.</p>
  </body>
</html>
            END
        }
        else {
            print <<"            END";
<html>
  <body>
    <p>"$id" is not an identity we recognize.</p>
  </body>
</html>
            END
        }
    }
}

sub _get_user {
    return "user";
}

=head1 AUTHORS

=head1 COPYRIGHT

Copyright (c) 2007 Best Practical Solutions, LLC.

=head1 LICENSE

You may distribute this module under the same terms as Perl 5.8 itself.

=cut

1;
