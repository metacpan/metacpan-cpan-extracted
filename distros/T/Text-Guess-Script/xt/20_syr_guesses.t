#!perl
use 5.008;

use strict;
use warnings;
use utf8;

use Data::Dumper;

use lib qw(../lib/);

use Test::More;

my $class = 'Text::Guess::Script';

use_ok($class);

my $text =<<TEXT;


ܫܠܡܐ ܠܟ ܡܢ ܘܝܩܝܦܕܝܐ ܕܠܫܢܐ ܣܘܪܝܝ


TEXT

my $text2 =<<TEXT;

ܫܠܡܐ

TEXT

is(Text::Guess::Script->guess($text),'Syrc','is Syrc');
is(Text::Guess::Script->guess($text2),'Syrc','is Syrc');

my $guesses = Text::Guess::Script->_guesses($text);
print Dumper($guesses), "\n";

done_testing;
