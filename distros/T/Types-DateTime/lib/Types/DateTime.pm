use 5.008;
use strict;
use warnings;

package Types::DateTime;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use DateTime;
use DateTime::Duration;
use DateTime::Locale;
use DateTime::TimeZone;

use Module::Runtime qw( use_module );

use Type::Library -base, -declare => qw(
	DateTime Duration TimeZone Locale Now
	DateTimeWithZone DateTimeUTC
);
use Types::Standard qw( Num Str HashRef InstanceOf );
use Type::Utils;

# This stuff for compat with MooseX::Types::DateTime

class_type(DateTime, { class => 'DateTime' });
class_type(Duration, { class => 'DateTime::Duration' });
class_type(TimeZone, { class => 'DateTime::TimeZone' });
declare Locale,
	as InstanceOf['DateTime::Locale::root','DateTime::Locale::FromData'];
enum(Now, ['now']);

coerce DateTime,
	from Num,     q{ 'DateTime'->from_epoch(epoch => $_) },
	from HashRef, q{ exists($_->{epoch}) ? 'DateTime'->from_epoch(%$_) : 'DateTime'->new(%{$_}) },
	from Now,     q{ 'DateTime'->now },
	from InstanceOf['DateTime::Tiny'], q{ $_->DateTime };

coerce Duration,
	from Num,     q{ 'DateTime::Duration'->new(seconds => $_) },
	from HashRef, q{ 'DateTime::Duration'->new(%{$_}) };

coerce TimeZone,
	from Str,     q{ 'DateTime::TimeZone'->new(name => $_) };

coerce Locale,
	from InstanceOf['Locale::Maketext'], q{ 'DateTime::Locale'->load($_->language_tag) },
	from Str,     q{ 'DateTime::Locale'->load($_) };

# Time zone stuff

declare DateTimeWithZone,
	as         DateTime,
	coercion   => 1,  # inherit coercions
	where      {          not($_ ->time_zone->is_floating)   },
	inline_as  { (undef, "not($_\->time_zone->is_floating)") },
	constraint_generator => sub {
		my $zone = TimeZone->assert_coerce(shift);
		sub { $_[0]->time_zone eq $zone };
	},
	coercion_generator => sub {
		my $parent = shift;
		my $child  = shift;
		my $zone   = TimeZone->assert_coerce(shift);
		
		my $c = 'Type::Coercion'->new(type_constraint => $child);
		$c->add_type_coercions(
			$parent->coercibles, sub {
				my $dt = DateTime->coerce($_);
				return $_ unless DateTime->check($dt);
				$dt->set_time_zone($zone);
				return $dt;
			},
		);
		$c;
	};

declare DateTimeUTC, as DateTimeWithZone['UTC'], coercion => 1;

# Stringy coercions. No sugar for this stuff ;-)

__PACKAGE__->meta->add_coercion({
	name               => 'Format',
	type_constraint    => DateTime,
	coercion_generator => sub {
		my ($self, $target, $format) = @_;
		$format = use_module("DateTime::Format::$format")->new
			unless ref($format);
		
		my $timezone;
		if ($target->is_a_type_of(DateTimeWithZone))
		{
			my ($paramd_type) = grep {
				$_->is_parameterized and $_->parent==DateTimeWithZone
			} ($target, $target->parents);
			$timezone = TimeZone->assert_coerce($paramd_type->type_parameter)
				if $paramd_type;
		}
		
		return (
			Str,
			sub {
				my $dt = eval { $format->parse_datetime($_) };
				return $_ unless $dt;
				$dt->set_time_zone($timezone) if $timezone;
				$dt;
			},
		);
	},
});

__PACKAGE__->meta->add_coercion({
	name               => 'Strftime',
	type_constraint    => Str,
	coercion_generator => sub {
		my ($self, $target, $format) = @_;
		my $format_quoted = B::perlstring($format);
		return (
			DateTime->coercibles,
			qq{\$_->strftime($format_quoted)},
		);
	},
});

__PACKAGE__->meta->add_coercion({
	name               => 'ToISO8601',
	type_constraint    => Str,
	type_coercion_map  => [
		DateTime->coercibles,
		q{$_->iso8601},
	],
});

1;

__END__

=pod

=encoding utf-8

=for stopwords datetime timezone

=head1 NAME

Types::DateTime - type constraints and coercions for datetime objects

=head1 SYNOPSIS

   package FroobleGala;
   
   use Moose;
   use Types::DateTime -all;
   
   has start_date => (
      is      => 'ro',
      isa     => DateTimeUTC->plus_coercions( Format['ISO8601'] ),
      coerce  => 1,
   );

=head1 DESCRIPTION

L<Types::DateTime> is a type constraint library suitable for use with
L<Moo>/L<Moose> attributes, L<Kavorka> sub signatures, and so forth.

=head2 Types

This module provides some type constraints broadly compatible with
those provided by L<MooseX::Types::DateTime>, plus a couple of extra
type constraints.

=over

=item C<DateTime>

A class type for L<DateTime>. Coercions from:

=over

=item from C<Num>

Uses L<DateTime/from_epoch>. Floating values will be used for sub-second
precision, see L<DateTime> for details.

=item from C<HashRef>

Calls L<DateTime/new> or L<DateTime/from_epoch> as appropriate, passing
the hash as arguments.

=item from C<Now>

Uses L<DateTime/now>.

=item from C<< InstanceOf['DateTime::Tiny'] >>

Inflated using L<DateTime::Tiny/DateTime>.

=back

=item C<Duration>

A class type for L<DateTime::Duration>. Coercions from:

=over

=item from C<Num>

Uses L<DateTime::Duration/new> and passes the number as the C<seconds>
argument.

=item from C<HashRef>

Calls L<DateTime::Duration/new> with the hash entries as arguments.

=back

=item C<Locale>

A class type for L<DateTime::Locale>. Coercions from:

=over

=item from C<Str>

The string is treated as a language tag (e.g. C<en> or C<he_IL>) and
given to L<DateTime::Locale/load>.

=item from C<< InstanceOf['Locale::Maketext'] >>

The C<Locale::Maketext/language_tag> attribute will be used with
L<DateTime::Locale/load>.

=back

=item C<TimeZone>

A class type for L<DateTime::TimeZone>. Coercions from:

=over

=item from C<Str>

Treated as a time zone name or offset. See L<DateTime::TimeZone/USAGE>
for more details on the allowed values.

Delegates to L<DateTime::TimeZone/new> with the string as the C<name>
argument.

=back

=item C<Now>

Type constraint with only one allowed value, the string "now".

This is exported for compatibility with L<MooseX::Types::DateTime>, which
exports such a constraint, even though it is not documented.

=item C<DateTimeWithZone>

A subtype of C<DateTime> for objects with a defined (non-floating) time
zone.

This type constraint inherits its coercions from C<DateTime>.

=item C<< DateTimeWithZone[`a] >>

The C<DateTimeWithZone> type constraint may be parameterized with a
L<DateTime::TimeZone> object, or a string that can be coerced into one.

   has start_date => (
      is      => 'ro',
      isa     => DateTimeWithZone['Europe/London'],
      coerce  => 1,
   );

This type constraint inherits its coercions from C<DateTime>, and will
additionally call L<DateTime/set_time_zone> to shift objects into the
correct timezone.

=item C<DateTimeUTC>

Shortcut for C<< DateTimeWithZone["UTC"] >>.

=back

=head2 Named Coercions

It is hoped that Type::Tiny will help avoid the proliferation of
modules like L<MooseX::Types::DateTimeX>,
L<MooseX::Types::DateTime::ButMaintained>, and
L<MooseX::Types::DateTime::MoreCoercions>. It makes it very easy to add
coercions to a type constraint at the point of use:

   has start_date => (
      is      => 'ro',
      isa     => DateTime->plus_coercions(
         InstanceOf['MyApp::DT'] => sub { $_->to_DateTime }
      ),
      coerce  => 1,
   );

Even easier, this module exports some named coercions.

=over

=item C<< Format[`a] >>

May be passed an object providing a C<parse_datetime> method, or a
class name from the C<< DateTime::Format:: >> namespace (upon which
C<new> will be called).

For example:

   DateTime->plus_coercions( Format['ISO8601'] )

Or:

   DateTimeUTC->plus_coercions(
      Format[
         DateTime::Format::Natural->new(lang => 'en')
      ]
   )

=item C<< Strftime[`a] >>

A pattern for serializing a DateTime object into a string using
L<DateTime/strftime>.

   Str->plus_coercions( Strftime['%a %e %b %Y'] );

=item C<ToISO8601>

A coercion for serializing a DateTime object into a string using
L<DateTime/iso8601>.

   Str->plus_coercions( ToISO8601 );

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Types-DateTime>.

=head1 SEE ALSO

L<MooseX::Types::DateTime>,
L<Type::Tiny::Manual>,
L<DateTime>,
L<DateTime::Duration>,
L<DateTime::Locale>,
L<DateTime::TimeZone>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

