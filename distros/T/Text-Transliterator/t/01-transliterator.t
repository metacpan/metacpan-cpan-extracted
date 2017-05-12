use Test::More;
use strict;
use warnings;

use Text::Transliterator;

my $n_tests = 2;

plan tests => $n_tests;

my @strings = ("once upon a time",
               "there was a beautiful princess");

my @translated = ("onze upon x time", 
                  "there wxs x yexutiful prinzess");

my $tr = Text::Transliterator->new("abc", "xyz");

my @copy = @strings;
$tr->(@copy);
is_deeply(\@copy, \@translated, "string API");


$tr = Text::Transliterator->new({a => 'x', b => 'y', c => 'z'});
@copy = @strings;
$tr->(@copy);
is_deeply(\@copy, \@translated, "hashref API");


