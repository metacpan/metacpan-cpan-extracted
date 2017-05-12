use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";

use Unicode::Diacritic::Strip 'fast_strip';

my $gibberish = fast_strip ('Àëþìèíèé è ïëàñòèê');
is ($gibberish, 'Aethieiee e ieanoee');

my $lodz = 'Łódź';
my $slodz = fast_strip ($lodz);
is ($slodz, 'Lodz');

done_testing ();
