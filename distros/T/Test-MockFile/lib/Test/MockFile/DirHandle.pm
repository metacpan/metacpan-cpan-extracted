# Copyright (c) 2018, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

package Test::MockFile::DirHandle;

use strict;
use warnings;

#our @ISA = qw(IO::Handle);

sub new {
    my ( $class, $dir, $files_in_readdir ) = @_;

    return bless {
        files_in_readdir => $files_in_readdir,
        'dir'            => $dir,
        'tell'           => 0,
    }, $class;
}

1;
