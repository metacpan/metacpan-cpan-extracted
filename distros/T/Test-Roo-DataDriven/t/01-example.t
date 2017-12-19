package Example::Class;

use Test::Roo;

use lib 't/lib';

with qw/ Example Test::Roo::DataDriven /;

1;

package main;

use Test::Most;

Example::Class->run_data_tests(
    files   => [qw{ t/data }],
    recurse => 1,
    filter  => sub {
        my ($case, $file) = @_;
        $case->{data_file} //= $file;
        $case;
    },
);

done_testing;
