use strict;
use warnings;
use utf8;
use Test::More;
use Text::TestBase;
use Data::Dumper;

my $hunk = <<'...';
=== hogehoge
--- input
xxx
--- expected
yyy

=== XXX
...

my @blocks = Text::TestBase->new()->parse($hunk);
subtest 'block1' => sub {
    my $block = $blocks[0];
    is($block->name, 'hogehoge');
    is($block->get_lineno, 1);
};

subtest 'block2' => sub {
    my $block = $blocks[1];
    is($block->name, 'XXX');
    is($block->get_lineno, 7);
};
# note Dumper($block);

done_testing;
