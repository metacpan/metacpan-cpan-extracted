# Udev::FFI::Devnum - Copyright (C) 2017-2019 Ilya Pavlov
package Udev::FFI::Devnum;

use strict;
use warnings;

our (@ISA, @EXPORT_OK, %EXPORT_TAGS);

require Exporter;
@ISA = qw(Exporter);

@EXPORT_OK = qw(major minor makedev mkdev);

%EXPORT_TAGS = (
    'all' => \@EXPORT_OK
);



sub major {
    (($_[0]>>32)&0xFFFFF000) | (($_[0]>>8)&0x0FFF);
}


sub minor {
    (($_[0]>>12)&0xFFFFFF00) | ($_[0]&0xFF);
}


sub makedev {
    (($_[0]&0xFFFFF000)<<32) | (($_[0]&0x0FFF)<<8) |
        (($_[1]&0xFFFFFF00)<<12) | ($_[1]&0xFF);
}



sub mkdev { # 2017-12-19
    warn "mkdev is deprecated, use makedev instead\n";
    return makedev(@_);
}



1;



__END__



=head1 NAME

Udev::FFI::Devnum.

=head1 SYNOPSIS

    use Udev::FFI::Devnum qw(:all); #or use Udev::FFI::Devnum qw(major minor makedev)
    
    my $devnum = makedev(8, 1);
    my $major = major($devnum);
    my $minor = minor($devnum);

=head1 DESCRIPTION

This module provides major, minor and  makedev functions.

=head1 FUNCTIONS

=head2 major( DEVNUM )

Return major ID.

=head2 minor( DEVNUM )

Return minor ID.

=head2 makedev( MAJOR, MINOR )

Return device number.

=head1 SEE ALSO

L<Udev::FFI> main Udev::FFI documentation

=cut