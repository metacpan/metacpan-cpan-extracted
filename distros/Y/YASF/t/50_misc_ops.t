#!/usr/bin/perl

# Basic tests on misc operators not covered by other suites.

use 5.008;
use strict;
use warnings;

use Test::More;

use YASF;

my $master_data = {
    a => 'a',
    b => 'b',
    c => 'c',
};

plan tests => 27;

my $aaa = YASF->new('{a}{a}{a}', bindings => $master_data);
my $baa = YASF->new('{b}{a}{a}', bindings => $master_data);
my $bbb = YASF->new('{b}{b}{b}', bindings => $master_data);
my $ccc = YASF->new('{c}{c}{c}', bindings => $master_data);
my $aba = YASF->new('{a}{b}{a}', bindings => $master_data);
my $aca = YASF->new('{a}{c}{a}', bindings => $master_data);

# ne
ok($aaa ne 'a',  'ne - obj on lhs');
ok('a' ne $aaa,  'ne - obj on rhs');
ok($aaa ne $bbb, 'ne - both obj');

# lt
ok($aaa lt 'aab', 'lt - obj on lhs');
ok('aaa' lt $baa, 'lt - obj on rhs');
ok($aaa lt $baa,  'lt - both obj');

# gt
ok($bbb gt 'aab', 'gt - obj on lhs');
ok('bbb' gt $baa, 'gt - obj on rhs');
ok($baa gt $aaa,  'gt - both obj');

# le
ok($aaa le 'aaa', 'le - obj le str (1)');
ok($aaa le 'aab', 'le - obj le str (2)');
ok('aaa' le $aaa, 'le - str le obj (1)');
ok('aaa' le $baa, 'le - str le obj (2)');
ok($aaa le $aaa,  'le - obj le obj (1)');
ok($aaa le $baa,  'le - obj le obj (2)');

# ge
ok($bbb ge 'bbb', 'ge - obj ge str (1)');
ok($bbb ge 'aab', 'ge - obj ge str (2)');
ok('aaa' ge $aaa, 'ge - str ge obj (1)');
ok('bbb' ge $baa, 'ge - str ge obj (2)');
ok($aaa ge $aaa,  'ge - obj ge obj (1)');
ok($baa ge $aaa,  'ge - obj ge obj (2)');

# .
ok($aaa . 'b' eq 'aaab',    '. - obj on lhs');
ok('b' . $aaa eq 'baaa',    '. - obj on rhs');
ok($aaa . $bbb eq 'aaabbb', '. - both obj');

# .=
my $str = 'str';
$str .= $aaa;
ok($str eq 'straaa', '.= - obj on rhs');
eval { $aaa .= $str; };
like($@, qr/cannot be on the left of [.]=/i, '.= - obj on lhs');
eval { $bbb .= $ccc; };
like($@, qr/cannot be on the left of [.]=/i, '.= - both obj');

exit;
