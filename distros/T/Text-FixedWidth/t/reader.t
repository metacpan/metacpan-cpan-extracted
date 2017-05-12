use strict;
use warnings;
use Test::More;
use Text::FixedWidth;

my $fw = Text::FixedWidth->new();

# Let's try a mathematical reader:
ok $fw->set_attribute(
   name    => 'points',
   reader  => sub { $_[0]->get_points + 1 },
   length  => 1,
),                                              'set_attribute() points w/ reader';
is $fw->get_points,    undef,                   'get_points()';
ok $fw->set_points(3),                          'set_points()';
is $fw->get_points,    3,                       'get_points()';
is $fw->getf_points,   4,                       'getf_points()';


# Now let's try a money format that doesn't want a period:
ok $fw->set_attribute(
   name    => 'points2',
   # Use %07.0f not %07d or you may suffer off-by-a-penny rounding errors.
   # Thanks mauke in irc.perl.org #perl-help
   reader  => sub { sprintf("%07.0f", $_[0]->get_points2 * 100) },
   length  => 7,
),                                              'set_attribute() points2 w/ reader';
is $fw->get_points2,    undef,                  'get_points2()';
ok $fw->set_points2(69.99),                     'set_points2()';
is $fw->get_points2,    69.99,                  'get_points2()';
is $fw->getf_points2,   '0006999',              'getf_points2()';

done_testing();

