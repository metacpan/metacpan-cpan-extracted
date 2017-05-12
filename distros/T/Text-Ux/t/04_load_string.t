use strict;
use warnings;

use Test::More;
use Text::Ux;
use File::Temp;
use File::Spec;

my $ux = new_ok 'Text::Ux';
$ux->build([qw(foo bar baz footprint)]);
$ux->save(\my $dic);
ok $dic;
undef $ux;

my $ux2 = Text::Ux->new;
$ux2->load(\$dic);
is $ux2->size, 4;
my $res = $ux2->prefix_search('foop');
is $res, 'foo';

done_testing;
