use strict;
use warnings;

# FIXME yup, these aren't real tests, really.

{ package TestRole::One;      use Moose::Role; }
{ package TestRole::Two;      use Moose::Role; }

{
    package TestRole;
    use Moose::Role;

    with 'TestRole::One';

    has foo => (is => 'ro');

    has baz => (traits => ['TestRole::Two'], is => 'ro');

    sub method1 { }

    requires 'blargh';

    has bar => (

        traits  => ['Array'],
        isa     => 'ArrayRef',
        is      => 'ro',
        lazy    => 1,
        builder => '_build_bar',

        handles => {

            has_bar  => 'count',
            num_bars => 'count',
        }
    );
}

use Test::Builder::Tester; # tests => 1;
use Test::More;
use Test::Moose::More;

use TAP::SimpleOutput 'counters';

validate_role 'TestRole' => (
    -compose         => 1,

    attributes => [

        bar => {

            -does => ['Array'],
            -isa  => ['Moose::Meta::Attribute'],
            is    => 'ro',
            lazy  => 1,
        },
    ],

    does             => [ 'TestRole::One'               ],
    does_not         => [ 'TestRole::Two'               ],
    methods          => [ qw{ method1 }                 ],
    required_methods => [ qw{ blargh }                  ],
);

done_testing;
__END__
