package ExternalCatty;
use strict;
use warnings;
use Catalyst;
use Catalyst::ScriptRunner;
use IO::Socket::INET;

__PACKAGE__->config( name => 'ExternalCatty' );
__PACKAGE__->setup;

sub MAX_PORT_TRIES() { 5 }

# The Cat HTTP server background option is useless here :-(
# Thus we have to provide our own background method.
sub background {
    my $self  = shift;
    my $port  = shift;
    $port = $self->assert_or_find_available_port($port);
    my $child = fork;
    die "Can't fork Cat HTTP server: $!" unless defined $child;
    return($child, $port) if $child;

    if ( $^O !~ /MSWin32/ ) {
        require POSIX;
        POSIX::setsid() or die "Can't start a new session: $!";
    }
    local @ARGV = ('-p', $port);
    Catalyst::ScriptRunner->run(__PACKAGE__, 'Server');
}

sub assert_or_find_available_port {
    my($self, $port) = @_;
    for my $i (1..MAX_PORT_TRIES) {
        IO::Socket::INET->new(
            LocalAddr => 'localhost',
            LocalPort => $port,
            Proto     => 'tcp'
        ) and return $port;
        $port += int(rand 100) + 1;
    }
    die q{Can't find an open port to run external server on after }
        . MAX_PORT_TRIES . q{tries};
}

1;

