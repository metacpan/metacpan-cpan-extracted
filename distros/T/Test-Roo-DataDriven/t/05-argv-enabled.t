package Example::Class;

use Test::Roo;

use lib 't/lib';

with qw/ Example Test::Roo::DataDriven /;

has extra_key => (
    is       => 'ro',
    required => 1,
);

test 'extra_key' => sub {
    my ($self) = @_;
    is $self->extra_key, 1, 'extra_key';
};

1;

package main;

use Test::Most;

# Note that the test script never sees the "::" argument.

local @ARGV = qw( t/data/001-sample-data.dat );

Example::Class->run_data_tests(
    argv    => 1,
    files   => [qw{ t/data }],
    recurse => 1,
    filter  => sub {
        my ( $case, $file ) = @_;
        $case->{data_file} ||= $file;
        $case;
    },
);

done_testing(1);
