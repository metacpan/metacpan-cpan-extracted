use strict;
use warnings;

use Test::More q//;

use Util::H2O::More qw/baptise h2o/;

my $self = {
    somewhere => q{over},
    the       => q{rainbow},
};

my $qux = h2o -isa => q{Herp::Derp}, -class => q{Herp::Derp::_1}, $self;

is ref $qux, q{Herp::Derp::_1}, q{exported call to `h2o` works from Util::H2O::More.};

done_testing;
