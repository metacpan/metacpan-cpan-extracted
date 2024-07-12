use v5.20;

use utf8;
use warnings;

use Test2::V0;

use Text::Schmutz;

subtest "default options" => sub {

  my $s = Text::Schmutz->new;

  is $s->prob => 0.1, "prob";
  ok $s->use_small, "use_small enabled by defualt";
  ok !$s->use_large, "not use_large";
  ok !$s->strike_out, "not strike_out";

  my $text = "Hello World";
  isnt $s->mangle($text, 1.0), $text, "mangle";

};


done_testing;
