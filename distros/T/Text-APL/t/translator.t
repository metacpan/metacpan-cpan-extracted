use strict;
use warnings;

use Test::More;

use Text::APL::Translator;

my $translator;

$translator = Text::APL::Translator->new;
is $translator->translate([{type => 'expr', value => '$foo', as_is => 1}]),
  q/__print(do {$foo});/;

$translator = Text::APL::Translator->new;
is $translator->translate([{type => 'expr', value => '$foo'}]),
  q/__print_escaped(do {$foo});/;

$translator = Text::APL::Translator->new;
is $translator->translate([{type => 'exec', value => 'foo()'}]), q{foo();};

$translator = Text::APL::Translator->new;
is $translator->translate([{type => 'text', value => 'hello'}]),
  q/__print(q{hello});/;

done_testing;
