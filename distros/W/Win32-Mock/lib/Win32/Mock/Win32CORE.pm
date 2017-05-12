package # hide from PAUSE
        Win32;
use strict;
use warnings;

sub AUTOLOAD {
    no strict "vars";

    # save the value of these variables
    my @save = (0+$!, 0+$^E);

    # if what is asked is a Win32 function, load the real module
    if (index($AUTOLOAD, "Win32::") >= 0) {
        require Win32;
        Win32->import;
    }

    # restore the values
    ($!, $^E) = @save;

    # jump to the actual function
    goto &$AUTOLOAD
}

1

__END__

=head1 NAME

Win32 - Mocked Win32CORE

=head1 SYNOPSIS

    use Win32::Mock;
    use Win32CORE;

=head1 DESCRIPTION

This module is a mock/emulation of C<Win32CORE>. 
See the documentation of the real module for more details. 

=head1 SEE ALSO

L<Win32CORE>

L<Win32::Mock>

=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni E<lt>sebastien@aperghis.netE<gt>

=head1 COPYRIGHT & LICENSE

Copyright 2007, 2008 SE<eacute>bastien Aperghis-Tramoni, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
