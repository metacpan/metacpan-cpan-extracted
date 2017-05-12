package WeakRef::Auto;

use 5.008_001;
use strict;

our $VERSION = '0.02';

use Exporter qw(import);
our @EXPORT = qw(autoweaken);

sub autoweaken(\$);

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

1;
__END__

=head1 NAME

WeakRef::Auto -  Automatically makes references weaken

=head1 VERSION

This document describes WeakRef::Auto version 0.02.

=head1 SYNOPSIS

	use WeakRef::Auto;

	autoweaken my $ref; # $ref is always weaken

	$ref = \$var; # $ref is weak

	sub MyNode::new{
		# ...
		autoweaken $self->{parent}; # parent is always weaken
		return $self;
	}

=head1 DESCRIPTION

This module provides C<autoweaken()>, which keeps references weaken.

=head1 FUNCTIONS

=head2 autoweaken($var)

Turns I<$var> into auto-weaken variables, and keeps the values weak
references. If I<$var> already has a reference, it is weaken on the spot.

I<$var> can be an element of hashes or arrays.

=head1 NOTES

=over 4

=item *

Because the prototype of C<autoweaken()> is C<"\$"> (i.e. C<autoweakn($var)>
actually means C<&autoweaken(\$var)>), you'd better load this module in
compile-time, using C<use WeakRef::Auto> directive.

=back

=head1 BUGS AND LIMITATIONS

C<autoweaken()> does not work with tied variables, because autoweaken-ness is
attached to the variable, not to the value referred by the variable, and tied
variables interact with their objects by values, not variables, as the following
shows:

  my $impl = tie my %hash, 'Tie::StdHash';
  autoweaken $hash{foo};
  # $hash{foo} seems autoweaken. Really?
  # Actually, $hash{foo} is linked to $impl->{foo} through FETCH()/STORE() methods,
  # but there is no way to detect the relationship.

Patches are welcome.

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 SEE ALSO

L<Scalar::Util> for a description of weak references.

=head1 AUTHOR

Goro Fuji E<lt>gfuji(at)cpan.orgE<gt>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008, Goro Fuji E<lt>gfuji(at)cpan.orgE<gt>.
Some rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
