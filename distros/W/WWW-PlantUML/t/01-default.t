#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

use WWW::PlantUML;

$ENV{PLANTUML_BASE_URL} = qq{http://www.plantuml.com/plantuml};

my $puml = WWW::PlantUML->new;
my $url  = $puml->fetch_url(
    qq{
   Alice -> Bob : hello
}, 'png'
);

#diag $url;

ok(
    $url eq
'http://www.plantuml.com/plantuml/png/~169NZKb1GSCp9J4vLqBLJSCfFKh1Io4ZDoSdd0W1EMmQV',
    'fetched default url and default format'
);
