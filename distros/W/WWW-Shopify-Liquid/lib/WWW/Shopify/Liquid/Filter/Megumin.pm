#!/usr/bin/perl
use strict;
use warnings;

# WAGA NA WA MEGUMIN!!
package WWW::Shopify::Liquid::Filter::Megumin;
use base 'WWW::Shopify::Liquid::Filter';
sub max_arguments { return 0; }

sub operate { return "EXPL" . join("", ("O" x 1000)) . "SION!"; }


1;