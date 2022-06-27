package libreplace;

our $VERSION = '0.01';

use 5.006;
use strict;
use warnings;

sub import {
	@INC = split ':', $ENV{PERL5LIB};
}

__END__

=head1 NAME

libreplace - Clobber your lib with PERL5LIB

=head1 SYNOPSIS

The environmental variable C<PERL5LIB> appends to C<@INC>, by using
L<libreplace> it will replace (clobber) C<@INC> instead.

You can alternatively think of this kinda like C<use lib>, except with
clobbering behavior that takes its arguments from C<PERL5INC>.
    
		PERL5LIB="foo:bar:baz" perl -Mlibreplace ./script.pl

=head1 AUTHOR

Evan Carroll, C<< <me at evancarroll.com> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc libreplace


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Evan Carroll.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of libreplace
