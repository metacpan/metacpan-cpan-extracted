use strict;
use warnings;
use Test::More;
use Text::FixedWidth;

my $fw = Text::FixedWidth->new();

# Let's try a mathematical writer:
ok $fw->set_attribute(
   name    => 'points',
   writer  => sub { $_[1] / 2 },
   format  => '%-6s',
),                                              'set_attribute() points w/ writer';
is $fw->get_points,    undef,                   'get_points()';
ok $fw->set_points(3),                          'set_points()';
is $fw->get_points,    1.5,                     'get_points()';
is $fw->getf_points,   '1.5   ',                'getf_points()';

# Let's try a string writer:
ok $fw->set_attribute(
   name    => 'name',
   writer  => sub { my $val = $_[1]; $val =~ s/,.*//; $val },
   format  => '%-6s',
),                                              'set_attribute() name w/ writer';
is $fw->get_name,    undef,                     'get_name()';
ok $fw->set_name('foo,bar'),                    'set_name()';
is $fw->get_name,    'foo',                     'get_name()';
is $fw->getf_name,   'foo   ',                  'getf_name()';

done_testing();

