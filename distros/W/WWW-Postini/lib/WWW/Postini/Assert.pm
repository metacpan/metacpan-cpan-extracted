package WWW::Postini::Assert;

use strict;
use warnings;

use WWW::Postini::Exception::AssertionFailure;
use Exporter;

use vars qw( @ISA @EXPORT $VERSION );

@ISA = qw( Exporter );
@EXPORT = qw( assert );
$VERSION = '0.01';

sub assert {
	
	my $value = shift;
	my $description = shift if defined $_[0];
	
	unless (defined $value && $value) {
	
		my $description = sprintf 'Assertion%sfailed',
			defined $description && length $description ? " '$description' " : ' '
		;
		throw WWW::Postini::Exception::AssertionFailure($description);
	
	}
	
	1;
	
}

1;

__END__

=head1 NAME

WWW::Postini::Assert - Simple testing, with exception throwing

=head1 SYNOPSIS

  use WWW::Postini::Assert;

  assert(1 == 1, 'One equals one'); # pass
  assert(2 == 1, 'Two equals one'); # fail

=head1 DESCRIPTION

The purpose of this module is to provide a very simple testing mechanism with
the ability to throw exception objects on failure.

=head1 EXPORTS

The function C<assert()> is automatically exported into the current namespace.

=head1 FUNCTIONS

=over 4

=item assert($value)

=item assert($value,$description)

Tests for a defined non-zero C<$value> parameter and throws an exception of
class
L<WWW::Postini::Exception::AssertionFailure|WWW::Postini::Exception::AssertionFailure>
on failure.  If C<$description> is provided, it is added to the resulting
exception description.

=back

=head1 SEE ALSO

L<WWW::Postini>, L<WWW::Postini::Exception::AssertionFailure>

=head1 AUTHOR

Peter Guzis, E<lt>pguzis@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Peter Guzis

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

Postini, the Postini logo, Postini Perimeter Manager and preEMPT are trademarks,
registered trademarks or service marks of Postini, Inc. All other trademarks
are the property of their respective owners.

=cut