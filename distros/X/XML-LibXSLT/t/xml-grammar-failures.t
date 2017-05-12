#!/usr/bin/perl

use strict;
use warnings;

# Failures with doing this were reported against several XML::Grammar::*
# modules on various systems, and we want to catch them as soon as we can.
#
# See for example:
# http://www.cpantesters.org/cpan/report/b0e211b6-8b4d-11e3-9847-e214e1bfc7aa

use File::Spec;

use Test::More tests => 1;

use XML::LibXSLT;
use XML::LibXML;

{
    my $xslt = XML::LibXSLT->new();

    my $input_fn = File::Spec->catfile(
        File::Spec->curdir(), "t", "data", "perl-begin-page.xml-grammar-vered.xml",
    );

    my $xslt_fn = File::Spec->catfile(
        File::Spec->curdir(), "t", "data", "vered-xml-to-docbook.xslt",
    );

    my $source = XML::LibXML->load_xml(location => $input_fn);
    my $style_doc = XML::LibXML->load_xml(location=>$xslt_fn, no_cdata=>1);

    my $stylesheet = $xslt->parse_stylesheet($style_doc);

    my $results = $stylesheet->transform($source);

    # TEST
    like (scalar($stylesheet->output_as_bytes($results)),
        qr/<db:listitem/,
        "Rudimentary XSLT test just to make sure we reached here.",
    );
}
