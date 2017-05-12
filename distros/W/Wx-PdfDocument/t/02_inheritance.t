#!/usr/bin/perl -w
BEGIN { $ENV{WXPERL_OPTIONS} = 'NO_MAC_SETFRONTPROCESS'; }
use strict;
use Wx::PdfDocument;
use lib './t';

use Test::More 'no_plan';
use Tests_Helper qw( :inheritance );

test_inheritance( qw(
    PdfLayerGroup
    PdfOcg
    PdfColour
    PdfInfo
    PdfLineStyle
    PdfShape
    PdfLayer
    PdfLayerMembership
    PdfDC
    PdfFont
    PdfFontDescription
    PdfDocument
    PdfPageSetupDialog
    PdfPrintDialog
    PdfPrinter
) );

# Local variables: #
# mode: cperl #
# End: #
