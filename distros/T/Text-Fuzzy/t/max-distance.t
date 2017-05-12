# Test the maximum distance functions.

use warnings;
use strict;
use Text::Fuzzy;
use Test::More;

my $tf = Text::Fuzzy->new ('abcdefghijklm');
my $notmatch = 'nopqrstuvwxyz';

my $d = $tf->distance ($notmatch);
cmp_ok ($d, '>=', 10);

# Test switching off the distance completely.

$tf->set_max_distance ();
$d = $tf->distance ($notmatch);
is ($d, length ($notmatch));

my $md = $tf->get_max_distance ();
ok (! defined $md, "max distance is undefined");

# Test whether we found it in the list.

my @list = ($notmatch);
my $found = $tf->nearest (\@list);
is ($found, 0);
is ($tf->last_distance (), length ($notmatch));

my $tfc = Text::Fuzzy->new ('calamari', max => 1);
my @words = qw/Have you ever kissed in the moonlight
	       In the grand and glorious
	       Gay notorious
	       South American Way?/;
my $index = $tfc->nearest (\@words);
is ($index, undef);

done_testing ();
