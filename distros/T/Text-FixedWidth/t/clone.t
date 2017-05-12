use strict;
use warnings;
use Test::More tests => 42;
use Text::FixedWidth;

ok(my $fw = Text::FixedWidth->new());

ok $fw->set_attributes(qw[
    fname undef %10s
    mi    undef %1s
    lname undef %-10s
    points 0 %04d
]), 'set_attributes()';

is $fw->get_fname, undef, 'get_fname()';
is $fw->get_mi, undef, 'get_mi()';
is $fw->get_lname, undef, 'get_lname()';
is $fw->get_points, 0, 'get_points()';

can_ok $fw, 'clone';

my $fw_copy;

ok $fw_copy = $fw->clone, 'clone()';
ok $fw_copy != $fw, 'cloned objects reference different address';

ok $fw_copy->set_fname('Foo'), 'cloned set_fname()';
is $fw_copy->get_fname, 'Foo', 'cloned get_fname';

is $fw->get_fname, undef, 'original get_fname() is untainted';

my $_g = sub {
    my $str = <DATA>;
    return undef unless defined($str);
    return $fw->parse(clone => 1, string => $str );
};

while( my $row = $_g->() ) {
    ok defined($row) && $row != $fw, "row parse clone() number $.";
    is $fw->get_fname, undef, "row parse get_fname() untainted number $.";
    like $row->get_fname, qr/Jay|Chuck/, "row parse get_fname() number $.";
}


__DATA__
       JayWHannah    0003
     ChuckWNorris    0017
       JayWHannah    0003
     ChuckWNorris    0017
       JayWHannah    0003
     ChuckWNorris    0017
       JayWHannah    0003
     ChuckWNorris    0017
       JayWHannah    0003
     ChuckWNorris    0017
