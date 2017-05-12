use strict;
use Test::More qw(no_plan);
use Test::Exception;

use UltraDNS;

do 't/util.pl';

my ($hp,$s,$u,$p) = test_connect_args();

my $udns = UltraDNS->connect($hp, $s, $u, $p);

# test do() error handling
my @rr4 = $udns->do();
is @rr4, 0;

dies_ok { $udns->do(1) };
like $@, qr/called with 1 arguments but 0 actions are queued/;

dies_ok { my $tmp = $udns->do($udns->EnableAutoSerialUpdate, $udns->DisableAutoSerialUpdate) };
like $@, qr/called in scalar context but with more than one argument/;

dies_ok { UltraDNS->do(1) };
like $@, qr/without an UltraDNS object reference/;

dies_ok { UltraDNS->SomeUnKnownMethodOrOther(1) };
like $@, qr/Can't call .* UltraDNS object reference/;

dies_ok { $udns->SomeUnKnownMethodOrOther(1) };
like $@, qr/Can't call unknown method/;


# test tracing and connect attr
do {
    my @warns;
    local $ENV{ULTRADNS_TRACE} = 1;
    local $SIG{__WARN__} = sub {
        die @_ unless "@_" =~ m/^UltraDNS:/;
        push @warns, @_;
    };

    $udns = UltraDNS->connect($hp, $s, $u, $p, {
        version => '3.0',
        trace => 0, # 0=fallback to ULTRADNS_TRACE env
        ssl_trace => 0,
    });

    ok $udns;
    is $udns->trace, $ENV{ULTRADNS_TRACE};
    ok @warns;
}
