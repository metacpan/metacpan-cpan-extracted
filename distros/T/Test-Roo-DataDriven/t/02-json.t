package Example::Class;

use Test::Roo;

use lib 't/lib';

with qw/ Example Test::Roo::DataDriven /;

1;

package main;

use Test::Most;
use JSON::PP qw/ decode_json /;

Example::Class->run_data_tests(
    files   => [qw{ t/data/json }],
    recurse => 1,
    match   => qr/\.json$/,
    parser  => sub { decode_json( $_[0]->slurp_raw ) },
    filter  => sub {
        my ($case, $file) = @_;

        $case->{data_file} //= $file;
        $case->{regex} = qr/$case->{regex}/;
        $case->{epoch} += time;

        $case;
    },
);

done_testing;
