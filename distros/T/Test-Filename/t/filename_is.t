use strict;
BEGIN{ if (not $] < 5.006) { require warnings; warnings->import } }

select(STDERR); $|=1;
select(STDOUT); $|=1;

use File::Spec::Functions qw/canonpath/;

#--------------------------------------------------------------------------#
# setup
#--------------------------------------------------------------------------#

use Test::Tester 'no_plan';
use Test::Filename;

my $expected_file = 't/00_load.t';
my $got_file = canonpath( $expected_file );
my $wrong_file = canonpath('t/wrongfile.t');

#--------------------------------------------------------------------------#
# filename_is
#--------------------------------------------------------------------------#

check_test(
    sub {
        filename_is( $got_file, $expected_file, "foo" );
    },
    {
        ok => 1,
        name => "foo",
        diag => q{},
    },
    "filename_is - ok"
);

check_test(
    sub {
        filename_is( $wrong_file, $expected_file, "foo" );
    },
    {
        ok => 0,
        name => "foo",
    },
    "filename_is - nok"
);

#--------------------------------------------------------------------------#
# filename_isnt
#--------------------------------------------------------------------------#

check_test(
    sub {
        filename_isnt( $wrong_file, $expected_file, "foo" );
    },
    {
        ok => 1,
        name => "foo",
        diag => q{},
    },
    "filename_isnt - ok"
);

check_test(
    sub {
        filename_isnt( $got_file, $expected_file, "foo" );
    },
    {
        ok => 0,
        name => "foo",
    },
    "filename_isnt - nok"
);

