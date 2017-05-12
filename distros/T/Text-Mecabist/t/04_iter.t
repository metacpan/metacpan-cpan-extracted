use strict;
use warnings;
use utf8;
use Test::More;

use Text::Mecabist;

my $parser = Text::Mecabist->new();

my $doc = $parser->parse('こんにちは');
is($doc->count, 2);
ok(!$doc->nodes->[0]->prev);
ok(!$doc->nodes->[0]->has_prev);
ok($doc->nodes->[0]->has_next);
ok($doc->nodes->[0]->next);

ok($doc->nodes->[1]->prev);
ok($doc->nodes->[1]->has_prev);
ok(!$doc->nodes->[1]->has_next);
ok(!$doc->nodes->[1]->next);

done_testing();
