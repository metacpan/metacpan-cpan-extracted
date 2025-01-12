package Udev::FFI::Devnum;

use strict;
use warnings;

use base qw(Exporter);

our @EXPORT_OK = qw(major minor makedev);

our %EXPORT_TAGS = (
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
