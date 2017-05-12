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
use Unicode::Diacritic::Strip ':all';
my $empty = '';
eval {
    strip_diacritics ($empty);
};
ok (! $@, "does not crash with empty input");
if ($@) {
note ("Failed: $@");
}
done_testing ();
