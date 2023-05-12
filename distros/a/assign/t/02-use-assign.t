use assign::Test;

use assign::0;

my $aref1 = [111, 222];
my $href1 = {bar => 222, foo => 111};

my [$a1, $b1] = $aref1;
is $a1 + $b1, 333, "It works";

my [$a2, $b2, $c2] = $aref1;
is $a2, 111, "\$a2 == 111";
is $b2, 222, "\$b2 == 222";
ok not(defined($c2)), "\$c2 is not defined";

my [$a3, $b3, $c3] = [111, 222];
is $a3, 111, "\$a3 == 111";
is $b3, 222, "\$b3 == 222";
ok not(defined($c3)), "\$c3 is not defined";

our [$a4, $b4, $c4] = [111, 222];
is $main::a4, 111, "\$main::a4 == 111";
is $main::b4, 222, "\$main::b4 == 222";
ok not(defined($main::c4)), "\$main::c4 is not defined";

our ($a5, $b5, $c5) = (1, 2, 3);
{
    local [$a5, $b5, $c5] = [111, 222];
    is $main::a5, 111, "\$main::a5 == 111";
    is $main::b5, 222, "\$main::b5 == 222";
    ok not(defined($main::c5)), "\$main::c5 is not defined";
}
is $main::a5, 1, "\$main::a5 == 1";
is $main::b5, 2, "\$main::b5 == 2";
is $main::c5, 3, "\$main::c5 == 3";

my $a6; our $b6; my $c6;
[ $a6, $b6, $c6 ] = $aref1;
is $a6, 111, "\$a6 == 111";
is $b6, 222, "\$b6 == 222";
ok not(defined($c6)), "\$c6 is not defined";

my {$foo, $bar, $baz} = $href1;
is $foo, 111, "\$foo == 111";
is $bar, 222, "\$bar == 222";
ok not(defined($baz)), "\$baz is not defined";
