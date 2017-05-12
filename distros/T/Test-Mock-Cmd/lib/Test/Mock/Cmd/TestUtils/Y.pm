package Test::Mock::Cmd::TestUtils::Y;

use strict;
use warnings;

sub i_call_system {
    system(@_);
}

sub i_call_exec {
    exec(@_);
}

sub i_call_readpipe {
    readpipe( $_[0] );
}

sub i_call_qx {
    qx(/bin/echo QX);
}

sub i_call_backticks {
    `/bin/echo BT`;
}

1;

__END__

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2011 cPanel, Inc. C<< <copyright@cpanel.net>> >>. All rights reserved.

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself, either Perl version 5.10.1 or, at your option, 
any later version of Perl 5 you may have available.
