=pod

=encoding utf-8

=head1 PURPOSE

Test that Test::Modern's exports.

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
use Test::Modern ();
use Data::Dumper;

sub exports_ok ($$$)
{
	my $class     = shift;
	my @args      = @{ +shift };
	my @expected  = @{ +shift };
	
	my %into;
	$class->import({ into => \%into }, @args);
	
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	local $Data::Dumper::Terse  = 1;
	local $Data::Dumper::Indent = 0;
	
	is_deeply(
		[ sort keys %into ],
		[ sort @expected ],
		sprintf("use Test::Modern %s", join q[, ], Dumper(@args)),
	);
}

my @defaults = qw/
	$TODO
	ok is isnt like unlike is_deeply cmp_ok new_ok isa_ok can_ok
	pass fail
	diag note explain
	subtest
	skip todo_skip plan done_testing BAIL_OUT
	exception
	warnings warning
	public_ok import_ok class_api_ok
	does_ok object_ok namespaces_clean
	is_string is_string_nows like_string unlike_string
	contains_string lacks_string
	cmp_deeply TD
/;

exports_ok(
	'Test::Modern' => [],
	\@defaults,
);

exports_ok(
	'Test::Modern' => [ -moose ],
	[qw/ $TODO does_ok /],
);

exports_ok(
	'Test::Modern' => [qw/ -moose pass diag use_ok /],
	[qw/ $TODO does_ok pass diag use_ok /],
);

exports_ok(
	'Test::Modern' => [ -requires => { strict => undef } ],
	\@defaults,
);

exports_ok(
	'Test::Modern' => [ -requires => { strict => undef }, -moose ],
	[qw/ $TODO does_ok /],
);

exports_ok(
	'Test::Modern' => [ -requires => { strict => undef }, 'diag' ],
	[qw/ $TODO diag /],
);

done_testing;

