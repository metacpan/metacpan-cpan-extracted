=pod

=encoding utf-8

=head1 PURPOSE

Test combinations of C<ReadOnly> and C<Locked>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use 5.008;
use strict;
use warnings;
use Test::More 0.96;
use Test::TypeTiny;
use Test::Fatal;
use Try::Tiny;

use Types::Standard -types;
use Types::ReadOnly -types;

my $ArrayOfLH = ArrayRef[ Locked[HashRef] ];

should_pass([], $ArrayOfLH);
should_fail([ {foo => 1} ], $ArrayOfLH);

ok( $ArrayOfLH->has_coercion, "$ArrayOfLH has coercion" );

my $arr = $ArrayOfLH->coerce([ {foo => 1} ]);

should_pass($arr, $ArrayOfLH, "... which coerces value to something that passes");
is_deeply(
	$arr,
	[ {foo => 1} ],
	"... and is a reasonable representation of the input",
);

my $input = [
	{ n => 1 },
	{ n => 2 },
	{},
	{ n => 4 },
];

my $Complex = (ReadOnly[ ArrayRef[ Locked[ Dict[ n => Optional[Int] ] ] ] ])->create_child_type(
	name      => 'Complex',
	coercion  => 1,
);
my $output = $Complex->coerce($input);
should_fail($input, $Complex);
should_pass($output, $Complex);

done_testing;
