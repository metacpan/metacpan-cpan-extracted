use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 16;
use Text::Hunspell;

my $speller = Text::Hunspell->new(qw(./t/morph.aff ./t/morph.dic));
die unless $speller;

my @data = (
  [[qw( drink  eat             )], [ 'drink'        ]],
  [[qw( drink  eats            )], [ 'drinks'       ]],
  [[qw( drink  ate             )], [ 'drank'        ]],
  [[qw( drink  eaten           )], [ 'drunk'        ]],
  [[qw( drink  eatable         )], [ 'drinkable'    ]],
  [[qw( drink  eatables        )], [ 'drinkables'   ]],
  [[qw( drink  phenomena       )], [ 'drinks'       ]],
  [[qw( drinks  eat            )], [ 'drink'        ]],
  [[qw( drinks  eats           )], [ 'drinks'       ]],
  [[qw( drinks  ate            )], [ 'drank'        ]],
  [[qw( drinks  eaten          )], [ 'drunk'        ]],
  [[qw( drinks  eatable        )], [ 'drinkable'    ]],
  [[qw( drinks  eatables       )], [ 'drinkables'   ]],
  [[qw( drinks  phenomena      )], [ 'drinks'       ]],
  [[qw( undrinkable  phenomena )], [ 'undrinkables' ]],
  [[qw( phenomenon  drinks     )], [ 'phenomena'    ]],
);

foreach my $data (@data)
{
  my($input, $output) = @$data;
  is_deeply [$speller->generate(@$input)], $output, "@{$input} => @{$output}";
}
