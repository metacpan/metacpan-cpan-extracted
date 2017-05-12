#!/usr/bin/perl -w 

use strict;
use warnings;

use Test::More tests => 2;

BEGIN{
    use_ok('WWW::Arbeitsagentur');
}

use WWW::Arbeitsagentur qw/extract_refnumber/;

my $refnummer = '                    <h3 class="ueberschriftceins">Details zum Stellenangebot - Fachinformatiker/in - Anwendungsentwicklung SAP (Fachinformatiker/in - Anwendungsentwicklung)<br/>Referenznummer: 10001-333333333333333333-S</h3>';


is( extract_refnumber(\$refnummer), '10001-333333333333333333-S', 'Extract Reference Number');
