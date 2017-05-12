use strict;
use warnings;
use Test::More tests => 4;

BEGIN { use_ok('Text::Snippet') };

can_ok('Text::Snippet', 'parse');

my $snippet = Text::Snippet->parse("Just Checking!");
is($snippet->to_string, "Just Checking!", "to_string");
is(scalar(@{ $snippet->tab_stops }), 1, 'one implicit tab stop')
