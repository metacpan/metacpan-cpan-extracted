#!perl -T

use Test::More tests => 4;
use WWW::VieDeMerde;

my $vdm = WWW::VieDeMerde->new();
ok(defined $vdm, "WWW::VieDeMerde->new() returns something");
ok($vdm->isa('WWW::VieDeMerde'), "WWW::VieDeMerde->new() returns the right class");

my $fml = WWW::VieDeMerde->new(lang => 'en');
ok(defined $fml, "WWW::VieDeMerde->new(lang => 'en') returns something");
ok($fml->isa('WWW::VieDeMerde'), "WWW::VieDeMerde->new(lang => 'en') returns the right class");

