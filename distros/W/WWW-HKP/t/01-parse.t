#!perl -T

use Test::More;

plan tests => 4;

require_ok('WWW::HKP');

my $hkp = new WWW::HKP;

subtest 'filter_ok=0,ok=00' => sub {
    my $struct = {
        DEADBEEF => {
            algo    => 12,
            keylen  => 34,
            created => 56,
            expires => 78,
            expired => 1,
            revoked => 1,
            deleted => 1,
            ok      => 0,
            uids    => [
                {
                    uid     => '  ',
                    created => 123,
                    expires => 456,
                    revoked => 1,
                    deleted => 1,
                    expired => 1,
                    ok      => 0
                }
            ]
        }
    };

    is_deeply( $hkp->_parse_mr( <<EOD, 0 ), $struct, 'filter_ok=0' );
info:1:1
pub:DEADBEEF:12:34:56:78:der
uid:%20%20:123:456:der
EOD
    done_testing;
};

subtest 'filter_ok=1,ok=10' => sub {
    my $struct = {
        DEADBEEF => {
            algo    => 12345,
            keylen  => 67890,
            created => 1,
            expires => 2147483647,
            expired => 0,
            revoked => 0,
            deleted => 0,
            ok      => 1,
            uids    => []
        }
    };

    is_deeply( $hkp->_parse_mr( <<EOD, 1 ), $struct, 'filter_ok=1' );
info:1:1
pub:DEADBEEF:12345:67890:1:2147483647:
uid:%20%20:123:456:der
EOD
    done_testing;
};

subtest 'filter_ok=1,ok=110' => sub {
    my $struct = {
        DEADBEEF => {
            algo    => 12345,
            keylen  => 67890,
            created => 1,
            expires => 2147483647,
            expired => 0,
            revoked => 0,
            deleted => 0,
            ok      => 1,
            uids    => [
                {
                    uid     => 'foo',
                    created => 1,
                    expires => 2147483647,
                    expired => 0,
                    revoked => 0,
                    deleted => 0,
                    ok      => 1
                }
            ]
        }
    };

    is_deeply( $hkp->_parse_mr( <<EOD, 1 ), $struct, 'filter_ok=1' );
info:1:1
pub:DEADBEEF:12345:67890:1:2147483647:
uid:foo:1:2147483647:
uid:bar:0:0:der
EOD
    done_testing;
};

