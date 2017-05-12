use strict;
use warnings;
use Test::More;
use Text::FixedWidth;

my $fw = Text::FixedWidth->new();

ok $fw->set_attributes(qw[ fname undef %10s ]), 'set_attributes() fname';
ok $fw->set_attributes(qw[ mi    undef %10s ]), 'set_attributes() mi';
ok $fw->set_attribute(
   name    => 'lname',
   default => undef,
   format  => '%10s',
),                                              'set_attribute() lname';
is $fw->getf_fname, '          ',               'getf_fname()';
is $fw->getf_mi,    '          ',               'getf_mi()';
is $fw->getf_lname, '          ',               'getf_lname()';

ok $fw->set_attribute(
   name    => 'text1',
   default => undef,
   format  => '%10s',
),                                              'set_attribute() text1';
is $fw->getf_text1, '          ',               'getf_text1()';

done_testing();

