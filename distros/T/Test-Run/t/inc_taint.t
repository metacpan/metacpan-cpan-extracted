#!/usr/bin/perl -w

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = ('../lib', 'lib');
    }
    else {
        unshift @INC, 't/lib';
    }
}

use Test::Run::Obj;
use Test::More tests => 1;
use Dev::Null;

push @INC, 'we_added_this_lib';

tie *NULL, 'Dev::Null' or die $!;
select NULL;
my $obj = Test::Run::Obj->new(
    {
    test_files =>
    [
           $ENV{PERL_CORE}
            ? 'lib/sample-tests/inc_taint'
            : 't/sample-tests/inc_taint'
    ],
    }
);

my($failed) = $obj->_run_all_tests();
select STDOUT;

# TEST
ok( $obj->_all_ok($obj->tot()), 'tests with taint on preserve @INC' );
