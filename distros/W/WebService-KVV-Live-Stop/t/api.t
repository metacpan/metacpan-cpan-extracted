use Test::More;
use utf8;

BEGIN {
    use_ok 'WebService::KVV::Live::Stop';
}

my $stop = WebService::KVV::Live::Stop->new('Karlsruhe Hbf Vorplatz');

ok $stop->departures > 0;

done_testing;


