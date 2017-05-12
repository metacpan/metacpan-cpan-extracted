use 5.008;
use strict;
use warnings;

package Tie::Moose::ReadOnly;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use Moose::Role;
use namespace::autoclean;
use Carp qw(croak);

before [qw( STORE DELETE CLEAR )] => sub { croak "Read-only tied hash" };

1;

__END__

=head1 NAME

Tie::Moose::ReadOnly - make tied hash read-only

=head1 SYNOPSIS

	tie my %bob, "Tie::Moose"->with_traits("ReadOnly"), $bob;

=head1 DESCRIPTION

This trait makes the tied hash read-only, even if the underlying object's
attributes are read-write.

Attempts to store to or delete from the hash will throw an error.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Tie-Moose>.

=head1 SEE ALSO

L<Tie::Moose>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

