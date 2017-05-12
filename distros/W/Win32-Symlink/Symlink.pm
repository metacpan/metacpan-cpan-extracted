package Win32::Symlink;

use strict;
use 5.005;
use vars qw($VERSION @ISA);
use DynaLoader;

@ISA = qw(DynaLoader);
$VERSION = '0.06';

__PACKAGE__->bootstrap($VERSION);

sub import {
    *CORE::GLOBAL::symlink = __PACKAGE__->can('symlink');
    *CORE::GLOBAL::readlink = __PACKAGE__->can('readlink');
}

1;

__END__

=head1 NAME

Win32::Symlink - Symlink support on Windows

=head1 VERSION

This document describes version 0.06 of Win32::Symlink, released
April 13, 2015.

=head1 SYNOPSIS

    use Win32::Symlink;

    # Assuming D: is a NTFS volume...
    mkdir 'D:\from';
    symlink( 'D:\from' => 'D:\to' );
    print readlink( 'D:\to' ); # 'D:\from'
    rmdir 'D:\from', 'D\to';

=head1 DESCRIPTION

This module implements the built-in C<symlink> and C<readlink> functions for
Microsoft Windows.  Currently, it only works on NTFS filesystems.

=head1 SEE ALSO

L<Win32::Hardlink>

=head1 AUTHORS

Audrey Tang E<lt>cpan@audreyt.orgE<gt>

=head1 CC0 1.0 Universal

To the extent possible under law, 唐鳳 has waived all copyright and related
or neighboring rights to Win32-Symlink.

This work is published from Taiwan.

L<http://creativecommons.org/publicdomain/zero/1.0>

=cut
