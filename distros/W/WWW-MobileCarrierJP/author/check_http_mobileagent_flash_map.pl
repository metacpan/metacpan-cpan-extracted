#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use File::Spec;
use HTTP::MobileAgent::Flash::DoCoMoFlashMap qw/$FLASH_MAP/;

use lib File::Spec->catfile($FindBin::Bin, '..', 'lib');
use WWW::MobileCarrierJP::DoCoMo::Flash;

my $dat = WWW::MobileCarrierJP::DoCoMo::Flash->scrape;

for my $version (@$dat) {
    for my $model (@{$version->{models}}) {
        unless (exists $FLASH_MAP->{$model->{model}}) {
            warn "orz: $model->{model}";
        }
    }
}
