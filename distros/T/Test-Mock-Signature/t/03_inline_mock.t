use strict;
use warnings;

use Test::More;
use FindBin qw($Bin);
use File::Spec;

use lib File::Spec->catdir($Bin, 'lib');

use CONO::Real;
use Test::Mock::Signature;

my $real = CONO::Real->new;
my $mock = Test::Mock::Signature->new('CONO::Real');

subtest 'mock signature with empty params' => sub {
    is($real->test, 42, 'call test before mock');

    my $sig = $mock->method('test');
    $sig->callback( sub { return 'test 42' } );

    is($real->test, 'test 42', 'call test after mock');

    done_testing;
};

subtest 'mock signature with exact param' => sub  {
    is($real->proxy(42), 42, 'proxy return same value');

    my $sig = $mock->method(proxy => 42);
    $sig->callback( sub { return 'not 42' } );

    is($real->proxy('test'), 'test', 'default proxy behaviour');
    is($real->proxy(42), 'not 42', 'overrided proxy behaviour');

    $mock->method(proxy => 'test')->callback(sub { 'success' });
    is($real->proxy('test'), 'success', 'second override');

    $mock->clear(proxy => 42);
    is($real->proxy(42), 42, 'proxy after clear');
    is($real->proxy('test'), 'success', 'proxy(test) alive');

    $mock->clear('proxy');
    is($real->proxy('test'), 'test', 'proxy(test) is back to normal');

    done_testing;
};

subtest 'destroy mock object' => sub {
    undef $mock;

    is($real->test, 42, 'test method default behavior');

    done_testing;
};

done_testing;
