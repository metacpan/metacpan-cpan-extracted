use strict;
use warnings;
use utf8;

use Test::More;

use WebService::Pokemon;

my $pokemon;

$pokemon = WebService::Pokemon->new;
is(ref $pokemon, 'WebService::Pokemon', 'expect object instantiate through new');

done_testing;
