use strict;
use utf8;
use Test::More;
use Class::Load qw/load_class/;

use Text::Markup::Any;

for my $mod (keys %Text::Markup::Any::MODULES) {
    SKIP: {
        local $@;
        eval {load_class($mod); 1;} or skip "$mod not installed", 1;

        my $tma = Text::Markup::Any->new($mod);
        like $tma->markup('atarashii'), qr!atarashii!, $mod;
    }
}

done_testing;
