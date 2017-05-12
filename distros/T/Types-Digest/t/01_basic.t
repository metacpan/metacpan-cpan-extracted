use strict;
use warnings;

use Test::More tests => 6;
use Test::TypeTiny;
use Test::Exception;

use Types::Digest qw(Md5 Sha1 Sha224 Sha256 Sha384 Sha512);

test_digest(Md5, 32);
test_digest(Sha1, 40);
test_digest(Sha224, 56);
test_digest(Sha256, 64);
test_digest(Sha384, 96);
test_digest(Sha512, 128);


sub test_digest {
    my ($type, $len) = @_;

    subtest $type->name => sub {
        should_pass('0'x$len, $type);
        should_pass('a'x$len, $type);
        should_pass('A'x$len, $type);
        should_fail('z'x$len, $type);
    
        throws_ok {
            $type->('a');
        } qr/Must be $len/, 'exception';

        done_testing(5);
    };
}
