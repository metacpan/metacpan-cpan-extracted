package Win32::Hardlink;

use 5.005;
use strict;
use vars qw($VERSION @ISA);

BEGIN {
    $VERSION = '0.11';

    local $@;
    eval {
        require XSLoader;
        XSLoader::load(__PACKAGE__, $VERSION);
        1;
    } or do {
        require DynaLoader;
        push @ISA, 'DynaLoader';
        __PACKAGE__->bootstrap($VERSION);
    };
}

sub import {
    *CORE::GLOBAL::link = __PACKAGE__->can('link');
    return *CORE::GLOBAL::link; # Avoid "once" warning
}

1;

__END__

=head1 NAME

Win32::Hardlink - Hardlink support on Windows

=head1 VERSION

This document describes version 0.11 of Win32::Hardlink, released
October 14, 2007.

=head1 SYNOPSIS

    use Win32::Hardlink;
    link( 'from' => 'to' );

=head1 DESCRIPTION

This module implements the built-in C<link> function for Microsoft Windows.
Currently, it only works on NTFS filesystems.

=head1 SEE ALSO

L<Win32::Symlink>

=head1 AUTHORS

Audrey Tang E<lt>cpan@audreyt.orgE<gt>

=head1 COPYRIGHT

Copyright 2004, 2005, 2006, 2007 by Audrey Tang E<lt>cpan@audreyt.orgE<gt>.

This software is released under the MIT license cited below.

=head2 The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=cut
