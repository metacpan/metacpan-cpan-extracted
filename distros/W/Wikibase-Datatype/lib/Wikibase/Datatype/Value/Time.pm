package Wikibase::Datatype::Value::Time;

use strict;
use warnings;

use Mo qw(build default is);
use Wikibase::Datatype::Utils qw(check_datetime check_entity);

our $VERSION = 0.38;

extends 'Wikibase::Datatype::Value';

has after => (
	is => 'ro',
	default => 0,
);

has before => (
	is => 'ro',
	default => 0,
);

has calendarmodel => (
	is => 'ro',
);

has precision => (
	is => 'ro',
	default => 11,
);

has timezone => (
	is => 'ro',
	default => 0,
);

sub type {
	return 'time';
}

sub BUILD {
	my $self = shift;

	if (! defined $self->{'calendarmodel'}) {
		$self->{'calendarmodel'} = 'Q1985727';
	}

	check_entity($self, 'calendarmodel');

	check_datetime($self, 'value');

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Value::Time - Wikibase time value datatype.

=head1 SYNOPSIS

 use Wikibase::Datatype::Value::Time;

 my $obj = Wikibase::Datatype::Value::Time->new(%params);
 my $after = $obj->after;
 my $before = $obj->before;
 my $calendarmodel = $obj->calendarmodel;
 my $precision = $obj->precision;
 my $timezone = $obj->timezone;
 my $type = $obj->type;
 my $value = $obj->value;

=head1 DESCRIPTION

This datatype is item class for representation of time.

=head1 METHODS

=head2 C<new>

 my $obj = Wikibase::Datatype::Value::Time->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<after>

After.
Default value is 0.

=item * C<before>

Before.
Default value is 0.

=item * C<calendarmodel>

Calendar model.
Default value is 'Q1985727' (proleptic Gregorian
calendar).

=item * C<precision>

Time precision.
Default value is 11.

=item * C<timezone>

Time zone.
Default value is 0.

=item * C<value>

Time value.
Parameter is required.

=back

=head2 C<after>

 my $after = $obj->after;

Get after.

Returns number.

=head2 C<before>

 my $before = $obj->before;

Get before.

Returns number.

=head2 C<calendarmodel>

 my $calendarmodel = $obj->calendarmodel;

Get calendar model. Unit is entity (e.g. /^Q\d+$/).

Returns string.

=head2 C<precision>

 my $precision = $obj->precision;

Get precision.

Returns number.

=head2 C<timezone>

 my $timezone = $obj->timezone;

Get time zone.

Returns number.

=head2 C<type>

 my $type = $obj->type;

Get type. This is constant 'time'.

Returns string.

=head2 C<value>

 my $value = $obj->value;

Get value.

Returns string.

=head1 ERRORS

 new():
         From Wikibase::Datatype::Utils::check_datetime():
                 Parameter '%s' has bad date time.
                         Value: %s
                 Parameter '%s' has bad date time day value.
                         Value: %s
                 Parameter '%s' has bad date time hour value.
                         Value: %s
                 Parameter '%s' has bad date time minute value.
                         Value: %s
                 Parameter '%s' has bad date time month value.
                         Value: %s
                 Parameter '%s' has bad date time second value.
                         Value: %s
         From Wikibase::Datatype::Utils::check_entity():
                 Parameter 'calendarmodel' must begin with 'Q' and number after it.
         From Wikibase::Datatype::Value::new():
                 Parameter 'value' is required.

=head1 EXAMPLE

=for comment filename=create_and_print_value_time.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Value::Time;

 # Object.
 my $obj = Wikibase::Datatype::Value::Time->new(
         'precision' => 10,
         'value' => '+2020-09-01T00:00:00Z',
 );

 # Get calendar model.
 my $calendarmodel = $obj->calendarmodel;

 # Get precision.
 my $precision = $obj->precision;

 # Get type.
 my $type = $obj->type;

 # Get value.
 my $value = $obj->value;

 # Print out.
 print "Calendar model: $calendarmodel\n";
 print "Precision: $precision\n";
 print "Type: $type\n";
 print "Value: $value\n";

 # Output:
 # Calendar model: Q1985727
 # Precision: 10
 # Type: time
 # Value: +2020-09-01T00:00:00Z

=head1 DEPENDENCIES

L<Error::Pure>,
L<Mo>,
L<Wikibase::Datatype::Utils>,
L<Wikibase::Datatype::Value>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Value>

Wikibase datatypes.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.38

=cut
