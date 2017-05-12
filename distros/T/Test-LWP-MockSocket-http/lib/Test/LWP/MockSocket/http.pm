package Test::LWP::MockSocket::http;
#Hack into LWP's socket methods
use strict;
use warnings;
use base qw(Exporter);
use LWP::Protocol::http;
use HTTP::Request;
no warnings 'redefine';

use constant {
    HT_MOCKSOCK_PERSIST => 1,
    HT_MOCKSOCK_QUICKIE => 2
};

our @EXPORT = qw(
    $LWP_Response $LWP_SocketArgs
    mocksock_mode mocksock_response
);

our $VERSION = 0.05;
our ($LWP_Response, $LWP_SocketArgs);

my $MODE = HT_MOCKSOCK_PERSIST;

*LWP::Protocol::http::socket_class = sub {
    '_LWP::FakeSocket';
};

sub mocksock_mode {
    my $mode = shift;
    return $MODE unless defined $mode;
    $MODE = $MODE;
}

sub mocksock_response {
    my $response = shift;
    return $LWP_Response unless defined $response;
    $LWP_Response = $response;
}


################################################################################
### Private                                                                  ###
################################################################################
my $RESPONSE_BUF;
my $REQDATA; #I don't always use the same conventions for mutables, especially in
#such horrible hacks like this

my $SEND_REQUEST_DONE = 0;
my $RESPBYTES_SENT = 0;

sub _add_reqdata {
    my (undef, $buf) = @_;
    $REQDATA .= $buf;
}

sub _initialize {
    $REQDATA            = "";
    
    #The following needs to be true in order for can_read to not fail
    #before the initial sysread.
    $RESPONSE_BUF       = "DUMMY";
    
    $SEND_REQUEST_DONE  = 0;
    $RESPBYTES_SENT     = 0;
}

sub _ensure_response_mode {
    return unless !$SEND_REQUEST_DONE;
    my $reftype = ref $LWP_Response;
    if($reftype eq 'CODE') {
        my $req = HTTP::Request->parse($REQDATA);
        $RESPONSE_BUF = $LWP_Response->($REQDATA, $req, $LWP_SocketArgs);
    } elsif ($reftype eq 'ARRAY') {
        $RESPONSE_BUF = shift @{$LWP_Response};
    } else {
        $RESPONSE_BUF = $LWP_Response;
    }
    $SEND_REQUEST_DONE = 1;
}

sub _get_response_data {
    my (undef, $buf,$length) = @_;
    _ensure_response_mode();
    my $remaining_length = length($RESPONSE_BUF);
    $length = $remaining_length if $length > $remaining_length;
    my $blob = substr($RESPONSE_BUF, $RESPBYTES_SENT, $length);
    if(!$blob) {
        #No data left. Maybe ConnCache is checking to see if we're still alive.
        #If we set this to -1, can_read will return false, and it will force the
        #creation of a new socket.
        $RESPBYTES_SENT = -1;
        return 0;
    }
    $_[1] = $blob;
    $RESPBYTES_SENT += $length;
    return length($blob);
}

package _LWP::FakeSocket;
use IO::String;
use base qw(IO::String);
use strict;
use warnings;
no warnings 'redefine';
Test::LWP::MockSocket::http->import();

my $mock = 'Test::LWP::MockSocket::http';

my $n_passed = 0;
our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    my ($fn_name) = (split(/::/, $AUTOLOAD))[-1];
    my $meth = Net::HTTP::Methods->can($fn_name);
    if(!$meth) {
        return;
    }
    return $meth->($self, @_);
}

sub new {
    $mock->_initialize();
    my ($cls,%opts) = @_;
    $LWP_SocketArgs = \%opts;
    my $self = IO::String->new();
    bless $self, __PACKAGE__;
    return $self;
}

sub can_read {
    $RESPONSE_BUF;
}

sub configure {
    my $self = $_[0];
    #log_err("Configure Called!");
    return $self;
}

sub syswrite {
    #We do some hackery here..
    my ($self,$buf,$length) = @_;
    $length ||= length($buf);
    $mock->_add_reqdata($buf);
    return $length;
}

sub sysread {
    return $mock->_get_response_data($_[1], $_[2]);
}

0xb00b135;

=head1 NAME

Test::LWP::MockSocket::http - Inject arbitrary data as socket data for LWP::UserAgent

=head1 SYNOPSIS

    use Test::LWP::MockSocket::http;
    use LWP::UserAgent;
    #   $LWP_Response is exported by this module
    $LWP_Response = "HTTP/1.0 200 OK\r\n\r\nSome Response Text";
    my $ua = LWP::UserAgent->new();
    $ua->proxy("http", "http://1.2.3.4:56");
    my $http_response = $ua->get("http://www.foo.com/bar.html");
    
    $http_response->code;       #200
    $http_response->content;    # "Some response text"
    $LWP_SocketArgs->{PeerAddr} # '1.2.3.4'

=head1 DESCRIPTION

This module, when loaded, mangles some functions in L<LWP::Protocol::http>
which will emulate a real socket. LWP is used as normally as much as possible.

Effort has been made to maintain the exact behavior of L<Net::HTTP> and L<LWP::Protocol::http>.

Two variables are exported, C<$LWP_Response> which should contain raw HTTP 'data',
and $LWP_SocketArgs which contains a hashref passed to the socket's C<new> constructor.
This is helpful for debugging complex LWP::UserAgent subclasses (or wrappers) which
modify possible connection settings.

=head2 EXPORTED SYMBOLS

Following the inspiration of L<Test::Mock::LWP>, two package variables will nicely
invade your namespace; they are C<$LWP_Response> which contains a 'response thingy'
(see below) and C<$LWP_SocketArgs> which contains a hashref of options that LWP
thought it would pass to L<IO::Socket::INET> or L<IO::Socket::SSL>.

In addition, you can use C<mocksock_response> as an accessor to the C<$LWP_Response>,
if you absolutely must.

=head2 RESPONSE VARIABLE

It was mentioned that C<$LWP_Response> is a 'thingy', and this is because it can
be three things:

=over

=item Scalar

This is the simplest way to use this module, and it will simply copy the contents
of the scalar verbatim into LWP's read buffers.

=item Array Reference

This functions like the Scalar model, except that it will cycle through each of the
elements in the array for each request, exhausting them - I don't know what happens
if you overrun the array - and your test code really shouldn't be doing anything that
causes it anyway.

=item Code Reference

This is the most entertaining of the three. The handler is called with three
arguments. The first is the raw request data as received from LWP's serialization
methods. The second is an L<HTTP::Request> object which is pretty much just there
for your convenience (this is a test module, the more information, the better, and
performance is not a big issue), and the last is the socket options found in
C<$LWP_SocketArgs>, again, for convenience.

=back

=head1 CAVEATS/BUGS

Probably many. This relies on mainly undocumented behavior and features of LWP
and is likely to break. In particular, the module test tries to ensure
that the mock socket works together with L<LWP::ConnCache>.

Depending on how LWP handles POST requests and other, perhaps more exotic requests,
this module might break. Then again, if you find a need to use this module in the
first place, you probably Know What You Are Doing(TM).

=head2 RATIONALE

I wrote this for testing code which used LWP and its
subclasses heavily, but still desired the full functionality of LWP::UserAgent
(if you look closely enough, you will see that the same L<HTTP::Request> object which
is passed to LWP is not the actual one sent on the wire, and the L<HTTP::Response>
object returned by LWP methods is not the same one received on the wire).

=head1 ACKNOWLEDGEMENTS

Thanks to mst for helping me with the difficult task of selecting the module name

=head1 AUTHOR AND COPYRIGHT

Copyright 2011 M. Nunberg

You may use and distribute this software under the terms of the GNU General Public
License Version 2 or higher.
