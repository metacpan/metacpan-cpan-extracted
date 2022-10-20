package Wikibase::Datatype::Print::Value::Time;

use base qw(Exporter);
use strict;
use warnings;

use DateTime::Format::ISO8601;
use Error::Pure qw(err);
use Readonly;

Readonly::Array our @EXPORT_OK => qw(print);

our $VERSION = 0.01;

sub print {
	my ($obj, $opts_hr) = @_;

	# Default options.
	if (! defined $opts_hr) {
		$opts_hr = {
			'print_name' => 1,
		};
	}

	if (! $obj->isa('Wikibase::Datatype::Value::Time')) {
		err "Object isn't 'Wikibase::Datatype::Value::Time'.";
	}

	if (exists $opts_hr->{'cb'} && ! $opts_hr->{'cb'}->isa('Wikibase::Cache::Backend')) {
		err "Option 'cb' must be a instance of Wikibase::Cache::Backend.";
	}

	# Calendar.
	my $calendar;
	if (exists $opts_hr->{'print_name'} && $opts_hr->{'print_name'} && exists $opts_hr->{'cb'}) {
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
