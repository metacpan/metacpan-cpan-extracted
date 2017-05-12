use strict;
use warnings;

use Test;

my(@colours,@fruits,@both);

BEGIN {
    @colours=qw(blue green magenta red violet yellow);
    @fruits=qw(apple banana bilberry plum raspberry);
    @both=qw(orange);

    plan(tests => (@colours+@fruits+@both)*4);
}

use Text::DAWG;

my $fruits=Text::DAWG::->new([@fruits,@both]);
my $colours=Text::DAWG::->new([@colours,@both]);

sub iterate
{
    foreach my $colour (@colours) {
	ok($colours->match($colour));
	ok(!$fruits->match($colour));
    }

    foreach my $fruit (@fruits) {
	ok($fruits->match($fruit));
	ok(!$colours->match($fruit));
    }

    foreach my $both (@both) {
	ok($colours->match($both));
	ok($fruits->match($both));
    }
}

iterate();

open(my $fh,">",\my $fruitbuffer)
    or die "open: $!";
$fruits->store($fh);
close($fh);

open($fh,">",\my $colourbuffer)
    or die "open: $!";
$colours->store($fh);
close($fh);

open($fh,"<",\$fruitbuffer)
    or die "open: $!";
$fruits=Text::DAWG::->load($fh);
close($fh);

open($fh,"<",\$colourbuffer)
    or die "open: $!";
$colours=Text::DAWG::->load($fh);
close($fh);

iterate();

