use Test::More;
use Test::Exception;
use utf8;

BEGIN {
    use_ok 'WebService::KVV::Live::Stop';
}

throws_ok { WebService::KVV::Live::Stop->new('Tabluha')->departures } qr/^Error/;

#my $stop = WebService::KVV::Live::Stop->new('Siemensallee');

done_testing;




