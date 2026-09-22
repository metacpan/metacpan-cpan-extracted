use strict;
use warnings;
use Test::More;
use WWW::Hetzner::Cloud;

my $c = WWW::Hetzner::Cloud->new(token => 't');
my @slept;
$c->sleeper(sub { push @slept, $_[0] });
$c->sleeper->(3);
is_deeply(\@slept, [3], 'injected sleeper is called with the interval');

done_testing;
