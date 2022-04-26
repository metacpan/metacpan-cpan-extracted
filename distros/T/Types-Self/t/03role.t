=pod

=encoding utf-8

=head1 PURPOSE

Test that Types::Self works with classes.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

subtest 'Testing `Self`' => sub {
	package Local::MyRole1;
	use Types::Self;
	use Role::Tiny;
	my $type = Self;

	package main;

	is(
		$type->display_name,
		'ConsumerOf["Local::MyRole1"]',
		'Type named correctly',
	);
};

done_testing;
