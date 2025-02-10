use Test::More;
use utf8;
use strict;
use warnings;

use Text::Transliterator;


my @strings       = ("once upon a time",  "there was a beautiful princess");
my @translated    = ("onze upon x time",  "there wxs x yexutiful prinzess");
my @nb_translated = (                 2,                                 5);

my $tr = Text::Transliterator->new("abc", "xyz");
my @copy = @strings;
my @nums = $tr->(@copy);
is_deeply(\@copy, \@translated,    "string API");
is_deeply(\@nums, \@nb_translated, "nb of translations");

@copy        = @strings;
my $last_num = $tr->(@copy);
is($last_num, $nb_translated[-1], "result in scalar context");

$tr = Text::Transliterator->new("abc", "xyz", "r");
my @new_strings = $tr->(@strings);
is_deeply(\@new_strings, \@translated, "'r' modifier");

$tr = Text::Transliterator->new({a => 'x', b => 'y', c => 'z'});
@copy = @strings;
$tr->(@copy);
is_deeply(\@copy, \@translated, "hashref API");


done_testing;
