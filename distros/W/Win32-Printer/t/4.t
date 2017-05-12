#------------------------------------------------------------------------------#
# Win32::Printer (EBbl) test script                                            #
# Copyright (C) 2003 Edgars Binans                                             #
#------------------------------------------------------------------------------#

use strict;
use warnings;
use Test::More;

use Win32::Printer;

if (Win32::Printer::_Get3PLibs() & 0x00000004) {
  plan tests => 1;
} else {
  plan skip_all => "EBbl is not built in!";
}

#------------------------------------------------------------------------------#

my $dc = new Win32::Printer( file => "t/tmp/test.ps" );

ok ( defined($dc->EBbl('This is EBbl barcode library test!', 0, 0, EB_EMF|EB_128SMART)), 'EBbl()' );

$dc->Close();

#------------------------------------------------------------------------------#

unlink <t/tmp/*.*>;
