use strict;
use warnings;
use utf8;

use Test::More;

use WebService::Pokemon;

my ($pokemon, $got);

$pokemon = WebService::Pokemon->new;
$got = $pokemon->pokemon(id => 1);

my $content = $got->{content};
cmp_ok(scalar keys %$content, '>', 0, 'expect fields found');

done_testing;
