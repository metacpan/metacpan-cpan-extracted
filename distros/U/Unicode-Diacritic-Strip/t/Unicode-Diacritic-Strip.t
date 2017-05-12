use warnings;
use strict;
use Test::More;
binmode STDOUT, ":utf8";
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

BEGIN { use_ok('Unicode::Diacritic::Strip') };
use Unicode::Diacritic::Strip 'strip_diacritics';
use utf8;
my $in = 'àÀâÂäçéÉèÈêÊëîïôùÙûüÜがぎぐげご';
my $out = 'aAaAaceEeEeEeiiouUuuUかきくけこ';
my $stripped = strip_diacritics ($in);
ok ($stripped eq $out, "Strip $in = $out");
done_testing ();
