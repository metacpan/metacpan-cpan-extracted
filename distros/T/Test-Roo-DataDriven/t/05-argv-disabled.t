package Example::Class;

use Test::Roo;

use lib 't/lib';

with qw/ Example Test::Roo::DataDriven /;

1;

package main;

use Test::Most;

# Note that the test script never sees the "::" argument.

local @ARGV = qw( t/data/001-sample-data.dat );

Example::Class->run_data_tests(
    argv    => 0,
    files   => [qw{ t/data }],
    recurse => 1,
    filter  => sub {
        my ( $case, $file ) = @_;
        $case->{data_file} //= $file;
        $case;
    },
);

done_testing(5);
