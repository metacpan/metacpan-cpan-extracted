=pod

=encoding utf-8

=head1 PURPOSE

Test that C<< Format[`a] >> works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern -requires => { 'DateTime::Format::ISO8601' => '0.06' };
use Types::DateTime -all;

object_ok(
	sub { DateTime->plus_fallback_coercions(Format['ISO8601']) },
	'$type',
	isa   => ['Type::Tiny'],
	can   => ['coerce'],
	more  => sub
	{
		my $type = shift;
		
		is_deeply(
			$type->coerce(['x', 'y', 'z']),
			['x', 'y', 'z'],
			'cannot coerce from arrayref',
		);
		
		object_ok(
			sub { $type->coerce('now') },
			'$dt_from_now',
			isa  => 'DateTime',
			more => sub {
				my $self = shift;
				my $diff = 'DateTime'->now() - $self;
				cmp_ok($diff->in_units('seconds'), '<', 60, 'looks recent');
			},
		);
		
		object_ok(
			sub { $type->coerce('2001-02-03T04:05:06') },
			'$dt_from_iso',
			isa  => 'DateTime',
			more => sub {
				my $self = shift;
				is($self->year, 2001, 'year');
				is($self->month, 2, 'month');
				is($self->day, 3, 'day');
				is($self->hour, 4, 'hour');
				is($self->minute, 5, 'minute');
				is($self->second, 6, 'second');
				object_ok(
					$self->time_zone,
					'$time_zone',
					isa  => 'DateTime::TimeZone',
					more => sub {
						my $time_zone = shift;
						ok($time_zone->is_floating, 'floating');
					},
				);
			},
		);
		
		object_ok(
			sub { $type->coerce('2001-02-03T04:05:06+08:00') },
			'$dt_from_iso_tz',
			isa  => 'DateTime',
			more => sub {
				my $self = shift;
				is($self->year, 2001, 'year');
				is($self->month, 2, 'month');
				is($self->day, 3, 'day');
				is($self->hour, 4, 'hour');
				is($self->minute, 5, 'minute');
				is($self->second, 6, 'second');
				object_ok(
					$self->time_zone,
					'$time_zone',
					isa  => 'DateTime::TimeZone',
					more => sub {
						my $time_zone = shift;
						is($time_zone->name, '+0800', 'name');
						is($time_zone->offset_for_datetime($self), 8*3600, 'offset_for_datetime');
					},
				);
			},
		);
	},
);

object_ok(
	sub { DateTimeUTC->plus_fallback_coercions(Format['ISO8601']) },
	'$utc_type',
	isa   => ['Type::Tiny'],
	can   => ['coerce'],
	more  => sub
	{
		my $utc_type = shift;
		
		is_deeply(
			$utc_type->coerce(['x', 'y', 'z']),
			['x', 'y', 'z'],
			'cannot coerce from arrayref',
		);
		
		object_ok(
			sub { $utc_type->coerce('now') },
			'$dt_from_now',
			isa  => 'DateTime',
			more => sub {
				my $self = shift;
				my $diff = 'DateTime'->now() - $self;
				cmp_ok($diff->in_units('seconds'), '<', 60, 'looks recent');
			},
		);
		
		object_ok(
			sub { $utc_type->coerce('2001-02-03T04:05:06') },
			'$dt_from_iso',
			isa  => 'DateTime',
			more => sub {
				my $self = shift;
				is($self->year, 2001, 'year');
				is($self->month, 2, 'month');
				is($self->day, 3, 'day');
				is($self->hour, 4, 'hour');
				is($self->minute, 5, 'minute');
				is($self->second, 6, 'second');
				object_ok(
					$self->time_zone,
					'$time_zone',
					isa  => 'DateTime::TimeZone',
					more => sub {
						my $time_zone = shift;
						is($time_zone->name, 'UTC', 'name');
						is($time_zone->offset_for_datetime($self), 0, 'offset_for_datetime');
					},
				);
			},
		);
		
		object_ok(
			sub { $utc_type->coerce('2001-02-03T04:05:06+08:00') },
			'$dt_from_iso_tz',
			isa  => 'DateTime',
			more => sub {
				my $self = shift;
				is($self->year, 2001, 'year');
				is($self->month, 2, 'month');
				is($self->day, 2, 'day');
				is($self->hour, 20, 'hour');
				is($self->minute, 5, 'minute');
				is($self->second, 6, 'second');
				object_ok(
					$self->time_zone,
					'$time_zone',
					isa  => 'DateTime::TimeZone',
					more => sub {
						my $time_zone = shift;
						is($time_zone->name, 'UTC', 'name');
						is($time_zone->offset_for_datetime($self), 0, 'offset_for_datetime');
					},
				);
			},
		);
	},
);

done_testing;
