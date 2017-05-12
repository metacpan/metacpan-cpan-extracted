=pod

=encoding utf-8

=head1 PURPOSE

Test that C<< Strftime[`a] >> and C<< ToISO8601 >> work.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern -requires => { 'Types::Standard' => '0.041' };
use Types::Standard qw(  Str );
use Types::DateTime qw( -all );

my $dt = object_ok(
	sub { DateTimeUTC->coerce(1_000_000_000) },
	'$dt',
	isa  => 'DateTime',
	more => sub {
		my $dt = shift;
		is($dt->year, 2001);
		is($dt->month, 9);
		is($dt->day, 9);
	},
);

object_ok(
	sub { Str->plus_coercions(Strftime['%a %e %b %Y']) },
	'$type',
	isa  => 'Type::Tiny',
	can  => [qw/ check coerce /],
	more => sub {
		my $type = shift;
		is($type->coerce($dt), 'Sun  9 Sep 2001');
	},
);

object_ok(
	sub { Str->plus_coercions(ToISO8601) },
	'$type',
	isa  => 'Type::Tiny',
	can  => [qw/ check coerce /],
	more => sub {
		my $type = shift;
		is($type->coerce($dt), '2001-09-09T01:46:40');
	},
);

done_testing;
