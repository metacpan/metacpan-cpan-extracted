package match::simple::XS;

use 5.012;
use strict;
use warnings;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

require mro;
require Carp;
require XSLoader;
XSLoader::load( 'match::simple::XS', $VERSION );

sub _regexp { scalar( $_[0] =~ $_[1] ) }

sub _overloaded_smartmatch {
	my ( $obj ) = @_;

	my @mro = @{ mro::get_linear_isa( ref $obj ) };
	for my $class ( @mro ) {
		my $name = "$class\::(~~";
		my $overload = do {
			no strict 'refs';
			exists( &$name ) ? \&$name : undef;
		};
		return $overload if $overload;
	}
	
	return;
}

1;
__END__

=head1 NAME

match::simple::XS - XS backend for match::simple

=head1 SYNOPSIS

  use match::simple;

=head1 DESCRIPTION

The user-facing module is L<match::simple>.

Nothing to see here; move along.

=head1 SEE ALSO

L<match::simple>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 THANKS

Thanks to alh, bulk88, rafl, leont, and ilmari on the I<< #xs >> IRC
channel for helping me translate a bunch ideas from Perl to XS.

The XS source code for L<Scalar::Util> was also very useful.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

