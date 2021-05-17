use 5.020;
require POSIX;
use Net::SSLeay ();
use UniEvent::HTTP;
use BSD::Resource;

$SIG{PIPE} = 'IGNORE';

our ($foo, @foo);
warn $$;

my $srv = UniEvent::HTTP::Server->new;
$srv->configure({locations => [{host => '*', port => 6669, backlog => 666, reuse_port => 0}]});
$srv->run;

my @c;

$srv->route_callback(sub {
    my ($req, undef) = @_;
    $c[0]++;
    $req->receive_callback(sub {
        my $req = shift;
        $c[1]++;
        #$req->respond(new UE::HTTP::ServerResponse());
    });
});

my $t = UE::Timer->new;
$t->callback(sub {
   say "@c ".BSD::Resource::getrusage()->{"maxrss"};
});
$t->start(1);

UE::Loop->default->run;
