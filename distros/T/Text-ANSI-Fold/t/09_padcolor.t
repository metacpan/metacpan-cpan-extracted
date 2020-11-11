use strict;
use warnings;
use Test::More 0.98;
use utf8;
use open IO => 'utf8', ':std';
use Data::Dumper;

use Text::ANSI::Fold qw(:constants);

my $fold = Text::ANSI::Fold->new();

sub fold  { $fold->fold(@_) }
sub left  { (fold @_)[0] }

{
    $_ = "\e[31m" . "\e[K" . "1" . "\e[m";
    is(left($_, width => 10, padding => 1),
       "\e[31m" . "\e[K" . "1"     . "\e[m" .
       "\e[31m"          . " " x 9 . "\e[m",
       "padding with erase line");
}

{
    $_ = "\e[31m" . "1" . "\e[m";
    is(left($_, width => 10, padding => 1),
       "\e[31m" . "1" . "\e[m" .
       " " x 9,
       "padding without line");
}

done_testing;
