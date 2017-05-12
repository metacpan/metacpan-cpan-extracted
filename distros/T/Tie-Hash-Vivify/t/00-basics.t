use strict;
use warnings;

use Test::More;
END { done_testing(); }

BEGIN { use_ok('Tie::Hash::Vivify') }

my $defaulter = 0;
my $vivi = Tie::Hash::Vivify->new(sub { "default" . $defaulter++ });

is(ref $vivi, 'HASH', "It looks like a regular hashref...");
is($vivi->{foo}, 'default0', 'but it defaults!');
$vivi->{bar} = "my data";
is($vivi->{bar}, 'my data', 'I can put my stuff in it...');
is($vivi->{baz}, 'default1', "and the defaulter doesn't get called!");
is($vivi->{foo}, 'default0', 'Defaults stick around.');
ok(exists $vivi->{foo}, 'Things that exist exist() ...');
ok(!exists $vivi->{nopers}, "and things that don't don't exist().");

# now make a copy as a normal hash
my %notvivi = ();
$notvivi{foo} = 'default0';
$notvivi{bar} = "my data";
$notvivi{baz} = "default1";
SKIP: {
    skip "scalar() mysteriously broken on Ye Olde Perle", 1,
        unless($] > 5.008001);
    is(scalar(%{$vivi}), scalar(%notvivi), "scalar() works, as if anyone's likely to ever bother");
}

%{$vivi} = ();
is_deeply([keys %{$vivi}], [], "can clear the hash");
is($vivi->{foo}, 'default2', "it's still magic!");
delete($vivi->{foo});
is_deeply([keys %{$vivi}], [], "can delete keys");

# vim: ft=perl :
