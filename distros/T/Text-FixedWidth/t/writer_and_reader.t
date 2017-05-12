use strict;
use warnings;
use Test::More;
use Text::FixedWidth;

my $fw = Text::FixedWidth->new();

ok $fw->set_attribute(
   name    => 'points',
   writer  => sub { $_[1] - 1 },
   reader  => sub { sprintf("%-7s", $_[0]->get_points . '!') },
   length  => 7,
),                                              'set_attribute() points w/ writer and reader';
is $fw->get_points,    undef,                   'get_points()';
ok $fw->set_points(3),                          'set_points(3)';
is $fw->get_points,    2,                       'get_points()';
is $fw->getf_points,   '2!     ',               'getf_points()';

done_testing();

