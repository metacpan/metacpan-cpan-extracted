use strict;
use warnings;

use Test::More;
use Test::Exception;

use Text::Difference;

my $diff = undef;

lives_ok { $diff = Text::Difference->new } "instantiated ok";

ok( ref $diff eq 'Text::Difference', "it's a Text::Difference object" );


done_testing();
