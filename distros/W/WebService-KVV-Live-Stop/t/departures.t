use Test::More;
use utf8;

BEGIN {
    use_ok 'WebService::KVV::Live::Stop';
}

my $stop = WebService::KVV::Live::Stop->new('Siemensallee');
for ($stop->departures) {
    $has_siemensallee = 1, last if $_->{destination} =~ /^Siemensallee/;
}
ok $has_siemensallee , 'Siemensallee passes through Siemensallee exists';

done_testing
