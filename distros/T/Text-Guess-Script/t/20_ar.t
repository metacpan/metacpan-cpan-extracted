#!perl
use 5.008;

use strict;
use warnings;
use utf8;

use lib qw(../lib/);

use Test::More;

my $class = 'Text::Guess::Script';

use_ok($class);

my $text =<<TEXT;

الديباجة

TEXT

is(Text::Guess::Script->guess($text),'Arab','is Arab');

done_testing;
