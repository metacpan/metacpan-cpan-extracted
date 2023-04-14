package Wikibase::Datatype::Print::Value::Time;

use base qw(Exporter);
use strict;
use warnings;

use DateTime::Format::ISO8601;
use Error::Pure qw(err);
use Readonly;

Readonly::Array our @EXPORT_OK => qw(print);

our $VERSION = 0.04;

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

	if (exists $opts_hr->{'cb'} && ! $opts_hr->{'cb'}->isa('Wikibase::Cache::Backend')) {
		err "Option 'cb' must be a instance of Wikibase::Cache::Backend.";
	}

	# Calendar.
	my $calendar;
	if ($opts_hr->{'print_name'} && exists $opts_hr->{'cb'}) {
		$calendar = $opts_hr->{'cb'}->get('label', $obj->calendarmodel) || $obj->calendarmodel;
	} else {
		$calendar = $obj->calendarmodel;
	}

	my $dt = DateTime::Format::ISO8601->parse_datetime((substr $obj->value, 1));

	# TODO Precision
	# TODO other?

	# TODO %d 01 -> 1
	return $dt->strftime("%d %B %Y").' ('.$calendar.')';
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

=head1 SUBROUTINES

=head2 C<print>

 my $pretty_print_string = print($obj, $opts_hr);

Construct pretty print output for L<Wikibase::Datatype::Value::Time>
object.

Returns string.

=head1 ERRORS

 print():
         Object isn't 'Wikibase::Datatype::Value::Time'.
         Option 'cb' must be a instance of Wikibase::Cache::Backend.

=head1 EXAMPLE1

=for comment filename=create_and_print_value_time.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Print::Value::Time;
 use Wikibase::Datatype::Value::Time;

 # Object.
 my $obj = Wikibase::Datatype::Value::Time->new(
         'precision' => 10,
         'value' => '+2020-09-01T00:00:00Z',
 );

 # Print.
 print Wikibase::Datatype::Print::Value::Time::print($obj)."\n";

 # Output:
 # 01 September 2020 (Q1985727)

=head1 EXAMPLE2

=for comment filename=create_and_print_value_time_translated.pl

 use strict;
 use warnings;

 use Wikibase::Cache::Backend::Basic;
 use Wikibase::Datatype::Print::Value::Time;
 use Wikibase::Datatype::Value::Time;

 # Object.
 my $obj = Wikibase::Datatype::Value::Time->new(
         'precision' => 10,
         'value' => '+2020-09-01T00:00:00Z',
 );

 # Cache object.
 my $cache = Wikibase::Cache::Backend::Basic->new;

 # Print.
 print Wikibase::Datatype::Print::Value::Time::print($obj, {
         'cb' => $cache,
 })."\n";

 # Output:
 # 01 September 2020 (proleptic Gregorian calendar)

=head1 DEPENDENCIES

L<DateTime::Format::ISO8601>,
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

© 2020-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.04

=cut
