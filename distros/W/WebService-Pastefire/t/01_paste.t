use strict;
use warnings;
use Test::More;
use Test::Exception;
use WebService::Pastefire;

throws_ok { WebService::Pastefire->new() }
    qr/^please specify email & password.*/, 'die if without email & password';

my $pf = new_ok 'WebService::Pastefire' => [
    username => 'someuser',
    password => 'somepass',
];

my $str = 'abcde';
SKIP: {
    skip " - This test doesn't run without \$ENV{TEST_PASTEFIRE}", 1
        unless $ENV{TEST_PASTEFIRE};
    ok $pf->paste($str), 'successfully pasted';
}

done_testing;
