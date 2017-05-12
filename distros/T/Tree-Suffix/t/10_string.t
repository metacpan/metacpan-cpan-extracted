use strict;
use warnings;
use Test::More tests => 8;
use Tree::Suffix;

my $tree = Tree::Suffix->new(qw(actgttact gactagcga gacacacta));
is($tree->string(1), 'gactagcga', 'entire string');
is($tree->string(2, 2), 'cacacta', 'substring w/ start pos');
is($tree->string(2, 2, 5), 'caca', 'substring w/ start and end pos');
is($tree->string(5), '', 'bad index');
is($tree->string(1, -2, -5), '', 'bad start/end positions');
is($tree->string(1, -2), 'gactagcga', 'bad start position');
is($tree->string(1, 1, 23), 'actagcga', 'bad end position');
is($tree->string(1, 9), '', 'override <eos>');
