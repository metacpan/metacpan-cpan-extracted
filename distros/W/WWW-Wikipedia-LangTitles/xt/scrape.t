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
use WWW::Wikipedia::LangTitles 'get_wiki_titles';
my $out = get_wiki_titles ('Helium');
is ($out->{ja}, 'ヘリウム', "Got Japanese title for helium");
my $outja = get_wiki_titles ('ヘリウム', lang => 'ja');
is ($outja->{en}, 'Helium', "Got English title with lang => ja and helium in ja");

done_testing ();
