use strict;
use Test::More;
use_ok ('WebService::GialloZafferano');
use_ok ('WebService::GialloZafferano::Recipe');
use_ok ('WebService::GialloZafferano::Ingredient');
use WebService::GialloZafferano;

my $Ricettario=WebService::GialloZafferano->new();
my @Ricette=$Ricettario->search("Spaghetti con le cozze");
ok(@Ricette>0 ,'search() returned a non-empty array');
my $ricetta= shift @Ricette;
isa_ok($ricetta,'WebService::GialloZafferano::Recipe');
ok($ricetta->title eq "Impepata di cozze" ,'WebService::GialloZafferano::Recipe->title() get the title of the first recipe');
ok($ricetta->url eq "http://ricette.giallozafferano.it/Impepata-di-cozze.html" ,'WebService::GialloZafferano::Recipe->url() get the url of the first recipe');
my @Ingredients=$ricetta->ingredients;
my $ingredient = shift @Ingredients;
isa_ok($ingredient, 'WebService::GialloZafferano::Ingredient');
ok($ingredient->name eq "Cozze", 'WebService::GialloZafferano::Ingredient name()');
ok($ingredient->quantity eq "2 kg", 'WebService::GialloZafferano::Ingredient quantity()');

done_testing;
