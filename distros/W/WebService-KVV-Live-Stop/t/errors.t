use Test::More;
use Test::Exception;
use utf8;

BEGIN {
    use_ok 'WebService::KVV::Live::Stop';
}

throws_ok { WebService::KVV::Live::Stop->new('Tabluha')->departures } qr/^Error/;

done_testing;




