use strict;
use warnings;
use Test::More;

plan skip_all => 'developer only! Set CBF_DEVEL environment variable to activate'
    unless exists $ENV{CBF_DEVEL};

plan tests => 11;
use WWW::CBF;

my $ranking = WWW::CBF->new();


ok 
   my $lider = $ranking->pos(1),
   'got leader status'
;

foreach my $k ( qw(clube pontos jogos vitorias derrotas empates gp gc sg ap ) ) {
    ok exists $lider->{$k}, "$k exists as $lider->{$k}";
}

