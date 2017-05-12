#!/usr/bin/perl -w

use strict;
use Test::More tests => 4;
BEGIN { $ENV{WXPERL_OPTIONS} = 'NO_MAC_SETFRONTPROCESS'; }
BEGIN { use_ok 'Wx::PdfDocument' }

use Wx qw( wxPDF_FONTSTYLE_ITALIC );
my $x = wxPDF_FONTSTYLE_ITALIC;

ok( $x, "Exported constant" );

eval "use Wx qw( wxNO_SUCH_CONSTANT )";
ok( $@, "Error exporting missing constant: $@" );

eval "Wx::wxNO_SUCH_CONSTANT()";
ok( $@, "Error autoloading missing constant: $@" );

# Local variables: #
# mode: cperl #
# End: #
