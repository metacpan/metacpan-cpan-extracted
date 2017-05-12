=pod

=encoding utf-8

=head1 PURPOSE

Check that C<< match($a, $coderef) >> works.

(This has been causing "Attempt to free unreferenced scalar" panics.)

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

use match::simple::XS;

sub does_match {
	my ($a, $b, $name) = @_;
	ok(
		match::simple::XS::match($a, $b),
		$name,
	);
}

sub doesnt_match {
	my ($a, $b, $name) = @_;
	ok(
		!match::simple::XS::match($a, $b),
		$name,
	);
}

match::simple::XS::match(1, sub { 1 }) for 0..99_999;

does_match($_, sub { 1 }, "$_ matches sub that always returns 1") for 0..19;
does_match($_, sub { "xyz" }, "$_ matches sub that always returns 'xyz'") for 0..19;
does_match($_, sub { [] }, "$_ matches sub that always returns []") for 0..19;
doesnt_match($_, sub { 0 }, "$_ does not match sub that always returns 0") for 0..19;
doesnt_match($_, sub { +undef }, "$_ does not match sub that always returns undef") for 0..19;

done_testing;

