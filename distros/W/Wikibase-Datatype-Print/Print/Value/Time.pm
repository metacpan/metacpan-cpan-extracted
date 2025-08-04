package Wikibase::Datatype::Print::Value::Time;

use base qw(Exporter);
use strict;
use warnings;

use DateTime;
use English;
use Error::Pure qw(err);
use Readonly;

Readonly::Array our @EXPORT_OK => qw(print);

our $VERSION = 0.19;

sub print {
	my ($obj, $opts_hr) = @_;

	# Default options.
	if (! defined $opts_hr) {
		$opts_hr = {};
	}
	if (! exists $opts_hr->{'print_name'}) {
		$opts_hr->{'print_name'} = 1;
	}

	if (! $obj->isa('Wikibase::Datatype::Value::Time')) {
		err "Object isn't 'Wikibase::Datatype::Value::Time'.";
	}

	if (exists $opts_hr->{'cb'} && ! $opts_hr->{'cb'}->isa('Wikibase::Cache')) {
		err "Option 'cb' must be a instance of Wikibase::Cache.";
	}

	# Calendar.
	my $calendar;
	if ($opts_hr->{'print_name'} && exists $opts_hr->{'cb'}) {
		$calendar = $opts_hr->{'cb'}->get('label', $obj->calendarmodel) || $obj->calendarmodel;
	} else {
		$calendar = $obj->calendarmodel;
	}

	# Convert to DateTime.
	my $dt = _parse_date($obj->value);

	my $printed_date;

	# Day.
	if ($obj->precision == 11) {
		$printed_date = $dt->strftime("%e %B %Y");
		$printed_date =~ s/^\s+//ms;

	# Month.
	} elsif ($obj->precision == 10) {
		$printed_date = $dt->strftime("%B %Y");

	# Year.
	} elsif ($obj->precision == 9) {
		$printed_date = $dt->strftime("%Y");
		if ($obj->before || $obj->after) {
			my $before = $obj->before ? $dt->year - $obj->before : $dt->year;
			my $after = $obj->after ? $dt->year + $obj->after : $dt->year;
			$printed_date .= " ($before-$after)";
		}

	# Decade.
	} elsif ($obj->precision == 8) {
		$printed_date = (int($dt->strftime('%Y') / 10) * 10).'s';

	# TODO Better precision print?
	# 0 - billion years, 1 - hundred million years, ..., 6 - millenia, 7 - century
	} elsif ($obj->precision <= 7 && $obj->precision >= 0) {
		$printed_date = $dt->strftime("%Y");
	} else {
		err "Unsupported precision '".$obj->precision."'.";
	}

	return $printed_date.' ('.$calendar.')';
}

sub _parse_date {
	my $date = shift;

	my ($year, $month, $day) = ($date =~ m/^([\+\-]\d+)\-(\d{2})\-(\d{2})T\d{2}:\d{2}:\d{2}Z$/ms);
	my $dt = DateTime->new(
		'year' => int($year),
		$month != 0 ? ('month' => $month) : (),
		$day != 0 ? ('day' => $day) : (),
	);

	return $dt;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Print::Value::Time - Wikibase time value pretty print helpers.

=head1 SYNOPSIS

 use Wikibase::Datatype::Print::Value::Time qw(print);

 my $pretty_print_string = print($obj, $opts_hr);
 my @pretty_print_lines = print($obj, $opts_hr);

=head1 SUBROUTINES

=head2 C<print>

 my $pretty_print_string = print($obj, $opts_hr);
 my @pretty_print_lines = print($obj, $opts_hr);

Construct pretty print output for L<Wikibase::Datatype::Value::Time>
object.

Returns string in scalar context.
Returns list of lines in array context.

=head1 ERRORS

 print():
         Cannot parse datetime value.
                 Input string: %s
         Object isn't 'Wikibase::Datatype::Value::Time'.
         Option 'cb' must be a instance of Wikibase::Cache.
         Unsupported precision '%s'.

=head1 EXAMPLE1

=for comment filename=create_and_print_value_time.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Print::Value::Time;
 use Wikibase::Datatype::Value::Time;

 # Object.
 my $obj = Wikibase::Datatype::Value::Time->new(
         'precision' => 11,
         'value' => '+2020-09-01T00:00:00Z',
 );

 # Print.
 print Wikibase::Datatype::Print::Value::Time::print($obj)."\n";

 # Output:
 # 1 September 2020 (Q1985727)

=head1 EXAMPLE2

=for comment filename=create_and_print_value_time_translated.pl

 use strict;
 use warnings;

 use Wikibase::Cache;
 use Wikibase::Cache::Backend::Basic;
 use Wikibase::Datatype::Print::Value::Time;
 use Wikibase::Datatype::Value::Time;

 # Object.
 my $obj = Wikibase::Datatype::Value::Time->new(
         'precision' => 11,
         'value' => '+2020-09-01T00:00:00Z',
 );

 # Cache object.
 my $cache = Wikibase::Cache->new(
         'backend' => 'Basic',
 );

 # Print.
 print Wikibase::Datatype::Print::Value::Time::print($obj, {
         'cb' => $cache,
 })."\n";

 # Output:
 # 1 September 2020 (proleptic Gregorian calendar)

=head1 DEPENDENCIES

L<DateTime>,
L<English>,
L<Error::Pure>,
L<Exporter>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Value::Time>

Wikibase time value datatype.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype-Print>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.19

=cut
