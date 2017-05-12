use strict;
use warnings;

use Test::More;
use Text::UnicodeTable::Simple;

my $t = Text::UnicodeTable::Simple->new();

my $alignment;
$alignment = $t->_decide_alignment('123');
is($alignment, Text::UnicodeTable::Simple::ALIGN_RIGHT, "number alignment");

$alignment = $t->_decide_alignment('  abc  ');
is($alignment, Text::UnicodeTable::Simple::ALIGN_LEFT, "not number alignment");

my @a = (1, 3, 5);
my @b = (2, 1, 8);
my @c = Text::UnicodeTable::Simple::_select_max(\@a, \@b);

is_deeply(\@c, [2, 3, 8]);

done_testing;
