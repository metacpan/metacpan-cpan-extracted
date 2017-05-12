use strict;
use warnings;
use Test::More tests => 1;
use Text::Hunspell::FFI;

my $spell = Text::Hunspell::FFI->new(qw(./t/test.aff ./t/test.dic));
isa_ok $spell, 'Text::Hunspell::FFI';
