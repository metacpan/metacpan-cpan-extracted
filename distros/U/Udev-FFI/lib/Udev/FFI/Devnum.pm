package Udev::FFI::Devnum;

use strict;
use warnings;

our (@ISA, @EXPORT_OK, %EXPORT_TAGS);

require Exporter;
@ISA = qw(Exporter);

@EXPORT_OK = qw(major minor mkdev);

%EXPORT_TAGS = (
    'all' => \@EXPORT_OK
);



sub major($) {
    $_[0]>>8; 
}


sub minor($) {
    $_[0]&0xff;
}


sub mkdev($$) {
    $_[0]<<8 | $_[1];
}



1;