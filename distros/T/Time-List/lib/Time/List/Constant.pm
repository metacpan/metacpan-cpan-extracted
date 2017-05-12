package Time::List::Constant;

use strict;
use warnings;

use Data::Util qw/install_subroutine/;

sub import {
    my ($self, @kinds) = @_;
    my $caller = (caller)[0];
    install_subroutine( $caller,  
        DAY => sub{1},
        MONTH => sub{2},
        WEEK => sub{3},
        HOUR => sub{4},
        ARRAY => sub{1},
        HASH => sub{2},
        ROWS => sub{3},
    );
}

1;

__END__

=head1 NAME

Time::List::Constant 

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

<<Shinichiro Sato>> E<lt><<s2otsa59@gmail.com>>E<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013, <<Shinichiro Sato>>. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
