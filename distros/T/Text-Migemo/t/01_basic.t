use strict;
use warnings;

use Test::More tests => 4;
use Text::Migemo qw(:all);

my $migemo;
eval { $migemo = Text::Migemo->new('t/dict/migemo-dict') };

isa_ok($migemo, 'Text::Migemo', 'isa');

isnt($migemo->is_enable, 0, 'enable');

is(sprintf('%s', @$), '', 'load');

my $result = $migemo->query('kokusai');
like($result, qr/国際連合難民高等弁務官事務所/, 'query');
