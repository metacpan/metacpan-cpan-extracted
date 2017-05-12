#
#
use Test::More tests => 2;
use Test::HTTP::Server;
use POSIX qw(SIGCHLD);

my $server = Test::HTTP::Server->new;

my $cnt;
my $pid = $server->{pid};

$cnt = kill SIGCHLD, $pid;
ok( $cnt, 'server is alive' );

# kill the server
$server = undef;

$cnt = kill SIGCHLD, $pid;
ok( !$cnt, 'server terminated' );
