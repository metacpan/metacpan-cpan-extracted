package ex::caution;
use strict;
use warnings;
our $VERSION = '0.01';

sub import {
        strict->import;
        warnings->import;
}

sub unimport {
        strict->unimport;
        warnings->unimport;
}

1;


1;
__END__

=head1 NAME

ex::caution - Perl pragma for enabling or disabling strictures and warnings simultaneously 

=head1 SYNOPSIS

  use ex::caution;
  no ex:caution;

=head1 DESCRIPTION

ex:caution allows you to enable or disable warnings B<and> strictures simultaneously with 
one command. Unlike either strict or warnings it does not support arguments. It is all or 
nothing.

    use ex::caution;

is exactly equivalent to 

    use strict;
    use warnings;

and 

    no ex::caution;

is exactly equivalent to

    no strict;
    no warnings;

=head2 EXPORT

Enables warnings and stricts in the lexical scope in which it is used.

=head1 NOTE

This module is currently in the 'ex' namespace as this is the approved way 
to release experimental pragmata. If approved it will be renamed to simply 'caution';

=head1 BUGS

Its probably a bug that we support 

    no caution;

but, well, not supporting it wouldn't be the Perl way.

=head1 SEE ALSO

L<strict>, L<warnings>

=head1 AUTHOR

Original idea and packaging by Yves Orton, E<lt>demerphq@E<gt>. 
The amazingly simple implementation was posted by Aaron Crane to
the Perl5Porters mailing list in response to a mail by yves.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Yves Orton and Aaron Crane

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
