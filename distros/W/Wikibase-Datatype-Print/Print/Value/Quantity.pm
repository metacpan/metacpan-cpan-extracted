package Wikibase::Datatype::Print::Value::Quantity;

use base qw(Exporter);
use strict;
use warnings;

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

	if (! $obj->isa('Wikibase::Datatype::Value::Quantity')) {
		err "Object isn't 'Wikibase::Datatype::Value::Quantity'.";
	}

	if (exists $opts_hr->{'cb'} && ! $opts_hr->{'cb'}->isa('Wikibase::Cache::Backend')) {
		err "Option 'cb' must be a instance of Wikibase::Cache::Backend.";
	}

	# Unit.
	my $unit;
	if ($obj->unit) {
		if (exists $opts_hr->{'print_name'} && $opts_hr->{'print_name'} && exists $opts_hr->{'cb'}) {
			$unit = $opts_hr->{'cb'}->get('label', $obj->unit) || $obj->unit;
		} else {
			$unit = $obj->unit;
		}
	}

	# Output.
	my $ret = $obj->value;
	if ($unit) {
		$ret .= ' ('.$unit.')';
	}

	return $ret;
}

1;

__END__
