#!perl

use strict;
use warnings;

use Test::More;

use_ok($_) for (qw( Weasel::FindExpanders::Dojo
  Weasel::Widgets::Dojo::Select Weasel::Widgets::Dojo::Option
  Weasel::Widgets::Dojo ));

done_testing;

