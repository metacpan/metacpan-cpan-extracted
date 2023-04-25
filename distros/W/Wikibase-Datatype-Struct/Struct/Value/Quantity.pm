package Wikibase::Datatype::Struct::Value::Quantity;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use URI;
use Wikibase::Datatype::Value::Quantity;

Readonly::Array our @EXPORT_OK => qw(obj2struct struct2obj);

our $VERSION = 0.11;

sub obj2struct {
	my ($obj, $base_uri) = @_;

	if (! defined $obj) {
		err "Object doesn't exist.";
	}
	if (! $obj->isa('Wikibase::Datatype::Value::Quantity')) {
		err "Object isn't 'Wikibase::Datatype::Value::Quantity'.";
	}
	if (! defined $base_uri) {
		err 'Base URI is required.';
	}

	my $amount = $obj->value;
	$amount = _add_plus($amount);
	my $unit;
	if (defined $obj->unit) {
		$unit = $base_uri.$obj->unit;
	} else {
		$unit = '1';
	}
	my $struct_hr = {
		'value' => {
			'amount' => $amount,
			defined $obj->lower_bound ? (
				'lowerBound' => _add_plus($obj->lower_bound),
			) : (),
			'unit' => $unit,
			defined $obj->upper_bound ? (
				'upperBound' => _add_plus($obj->upper_bound),
			) : (),
		},
		'type' => 'quantity',
	};

	return $struct_hr;
}

sub struct2obj {
	my $struct_hr = shift;

	if (! exists $struct_hr->{'type'}
		|| $struct_hr->{'type'} ne 'quantity') {

		err "Structure isn't for 'quantity' datatype.";
	}

	my $amount = $struct_hr->{'value'}->{'amount'};
	$amount = _remove_plus($amount);
	my $unit = $struct_hr->{'value'}->{'unit'};
	if ($unit eq 1) {
		$unit = undef;
	} else {
		my $u = URI->new($unit);
		my @path_segments = $u->path_segments;
		$unit = $path_segments[-1];
	}
	my $obj = Wikibase::Datatype::Value::Quantity->new(
		$struct_hr->{'value'}->{'lowerBound'} ? (
			'lower_bound' => _remove_plus($struct_hr->{'value'}->{'lowerBound'}),
		) : (),
		'unit' => $unit,
		$struct_hr->{'value'}->{'upperBound'} ? (
			'upper_bound' => _remove_plus($struct_hr->{'value'}->{'upperBound'}),
		) : (),
		'value' => $amount,
	);

	return $obj;
}

sub _add_plus {
	my $value = shift;

	if ($value =~ m/^\d+$/) {
		$value = '+'.$value;
	}

	return $value;
}

sub _remove_plus {
	my $value = shift;

	if ($value =~ m/^\+(\d+)$/ms) {
		$value = $1;
	}

	return $value;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Struct::Value::Quantity - Wikibase quantity value structure serialization.

=head1 SYNOPSIS

 use Wikibase::Datatype::Struct::Value::Quantity qw(obj2struct struct2obj);

 my $struct_hr = obj2struct($obj, $base_uri);
 my $obj = struct2obj($struct_hr);

=head1 DESCRIPTION

This conversion is between objects defined in Wikibase::Datatype and structures
serialized via JSON to MediaWiki.

=head1 SUBROUTINES

=head2 C<obj2struct>

 my $struct_hr = obj2struct($obj, $base_uri);

Convert Wikibase::Datatype::Value::Quantity instance to structure.
C<$base_uri> is base URI of Wikibase system (e.g. http://test.wikidata.org/entity/).

Returns reference to hash with structure.

=head2 C<struct2obj>

 my $obj = struct2obj($struct_hr);

Convert structure of quantity to object.

Returns Wikibase::Datatype::Value::Quantity instance.

=head1 ERRORS

 obj2struct():
         Base URI is required.
         Object doesn't exist.
         Object isn't 'Wikibase::Datatype::Value::Quantity'.

 struct2obj():
         Structure isn't for 'quantity' datatype.

=head1 EXAMPLE1

=for comment filename=obj2struct_value_quantity.pl

 use strict;
 use warnings;

 use Data::Printer;
 use Wikibase::Datatype::Value::Quantity;
 use Wikibase::Datatype::Struct::Value::Quantity qw(obj2struct);

 # Object.
 my $obj = Wikibase::Datatype::Value::Quantity->new(
         'unit' => 'Q190900',
         'value' => 10,
 );

 # Get structure.
 my $struct_hr = obj2struct($obj, 'http://test.wikidata.org/entity/');

 # Dump to output.
 p $struct_hr;

 # Output:
 # \ {
 #     type    "quantity",
 #     value   {
 #         amount   "+10",
 #         unit     "http://test.wikidata.org/entity/Q190900"
 #     }
 # }

=head1 EXAMPLE2

=for comment filename=struct2obj_value_quantity.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Struct::Value::Quantity qw(struct2obj);

 # Quantity structure.
 my $struct_hr = {
         'type' => 'quantity',
         'value' => {
                 'amount' => '+10',
                 'unit' => 'http://test.wikidata.org/entity/Q190900',
         },
 };

 # Get object.
 my $obj = struct2obj($struct_hr);

 # Get type.
 my $type = $obj->type;

 # Get unit.
 my $unit = $obj->unit;

 # Get value.
 my $value = $obj->value;

 # Print out.
 print "Type: $type\n";
 if (defined $unit) {
         print "Unit: $unit\n";
 }
 print "Value: $value\n";

 # Output:
 # Type: quantity
 # Unit: Q190900
 # Value: 10

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<URI>,
L<Wikibase::Datatype::Value::Property>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Struct>

Wikibase structure serialization.

=item L<Wikibase::Datatype::Value::Quantity>

Wikibase quantity value datatype.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype-Struct>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.11

=cut
