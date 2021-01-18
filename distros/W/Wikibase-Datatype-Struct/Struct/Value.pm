package Wikibase::Datatype::Struct::Value;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Value;
use Wikibase::Datatype::Struct::Value::Globecoordinate;
use Wikibase::Datatype::Struct::Value::Item;
use Wikibase::Datatype::Struct::Value::Monolingual;
use Wikibase::Datatype::Struct::Value::Property;
use Wikibase::Datatype::Struct::Value::Quantity;
use Wikibase::Datatype::Struct::Value::String;
use Wikibase::Datatype::Struct::Value::Time;

Readonly::Array our @EXPORT_OK => qw(obj2struct struct2obj);

our $VERSION = 0.06;

sub obj2struct {
	my ($obj, $base_uri) = @_;

	if (! defined $obj) {
		err "Object doesn't exist.";
	}
	if (! $obj->isa('Wikibase::Datatype::Value')) {
		err "Object isn't 'Wikibase::Datatype::Value'.";
	}

	my $struct_hr;
	my $type = $obj->type;
	if ($type eq 'globecoordinate') {
		$struct_hr = Wikibase::Datatype::Struct::Value::Globecoordinate::obj2struct($obj, $base_uri);
	} elsif ($type eq 'item') {
		$struct_hr = Wikibase::Datatype::Struct::Value::Item::obj2struct($obj);
	} elsif ($type eq 'monolingualtext') {
		$struct_hr = Wikibase::Datatype::Struct::Value::Monolingual::obj2struct($obj);
	} elsif ($type eq 'property') {
		$struct_hr = Wikibase::Datatype::Struct::Value::Property::obj2struct($obj);
	} elsif ($type eq 'quantity') {
		$struct_hr = Wikibase::Datatype::Struct::Value::Quantity::obj2struct($obj, $base_uri);
	} elsif ($type eq 'string') {
		$struct_hr = Wikibase::Datatype::Struct::Value::String::obj2struct($obj);
	} elsif ($type eq 'time') {
		$struct_hr = Wikibase::Datatype::Struct::Value::Time::obj2struct($obj, $base_uri);
	} else {
		err "Type '$type' is unsupported.";
	}

	return $struct_hr;
}

sub struct2obj {
	my $struct_hr = shift;

	if (! exists $struct_hr->{'type'}) {
		err "Type doesn't exist.";
	}

	my $obj;
	if ($struct_hr->{'type'} eq 'globecoordinate') {
		$obj = Wikibase::Datatype::Struct::Value::Globecoordinate::struct2obj($struct_hr);
	} elsif ($struct_hr->{'type'} eq 'monolingualtext') {
		$obj = Wikibase::Datatype::Struct::Value::Monolingual::struct2obj($struct_hr);
	} elsif ($struct_hr->{'type'} eq 'quantity') {
		$obj = Wikibase::Datatype::Struct::Value::Quantity::struct2obj($struct_hr);
	} elsif ($struct_hr->{'type'} eq 'string') {
		$obj = Wikibase::Datatype::Struct::Value::String::struct2obj($struct_hr);
	} elsif ($struct_hr->{'type'} eq 'time') {
		$obj = Wikibase::Datatype::Struct::Value::Time::struct2obj($struct_hr);
	} elsif ($struct_hr->{'type'} eq 'wikibase-entityid') {
		if ($struct_hr->{'value'}->{'entity-type'} eq 'item') {
			$obj = Wikibase::Datatype::Struct::Value::Item::struct2obj($struct_hr);
		} elsif ($struct_hr->{'value'}->{'entity-type'} eq 'property') {
			$obj = Wikibase::Datatype::Struct::Value::Property::struct2obj($struct_hr);
		} else {
			err "Entity type '$struct_hr->{'value'}->{'entity-type'}' is unsupported.";
		}
	} else {
		err "Type '$struct_hr->{'type'}' is unsupported.";
	}

	return $obj;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Struct::Value - Wikibase value structure serialization.

=head1 SYNOPSIS

 use Wikibase::Datatype::Struct::Value qw(obj2struct struct2obj);

 my $struct_hr = obj2struct($obj, $base_uri);
 my $obj = struct2obj($struct_hr);

=head1 DESCRIPTION

This conversion is between objects defined in Wikibase::Datatype and structures
serialized via JSON to MediaWiki.

=head1 SUBROUTINES

=head2 C<obj2struct>

 my $struct_hr = obj2struct($obj, $base_uri);

Convert Wikibase::Datatype::Value instance to structure.
C<$base_uri> is base URI of Wikibase system (e.g. http://test.wikidata.org/entity/).

Returns reference to hash with structure.

=head2 C<struct2obj>

 my $obj = struct2obj($struct_hr);

Convert structure of value to object.

Returns Wikibase::Datatype::Value instance.

=head1 ERRORS

 obj2struct():
         Object doesn't exist.
         Object isn't 'Wikibase::Datatype::Value'.
         Type '%s' is unsupported.

 struct2obj():
         Entity type '%s' is unsupported.
         Type doesn't exist.
         Type '%s' is unsupported.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Data::Printer;
 use Wikibase::Datatype::Value::Time;
 use Wikibase::Datatype::Struct::Value qw(obj2struct);

 # Object.
 my $obj = Wikibase::Datatype::Value::Time->new(
         'precision' => 10,
         'value' => '+2020-09-01T00:00:00Z',
 );

 # Get structure.
 my $struct_hr = obj2struct($obj, 'http://test.wikidata.org/entity/');

 # Dump to output.
 p $struct_hr;

 # Output:
 # \ {
 #     type    "time",
 #     value   {
 #         after           0,
 #         before          0,
 #         calendarmodel   "http://test.wikidata.org/entity/Q1985727",
 #         precision       10,
 #         time            "+2020-09-01T00:00:00Z",
 #         timezone        0
 #     }
 # }

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Wikibase::Datatype::Struct::Value qw(struct2obj);

 # Time structure.
 my $struct_hr = {
         'type' => 'time',
         'value' => {
                 'after' => 0,
                 'before' => 0,
                 'calendarmodel' => 'http://test.wikidata.org/entity/Q1985727',
                 'precision' => 10,
                 'time' => '+2020-09-01T00:00:00Z',
                 'timezone' => 0,
         },
 };

 # Get object.
 my $obj = struct2obj($struct_hr);

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
L<Exporter>,
L<Readonly>,
L<Wikibase::Datatype::Value>,
L<Wikibase::Datatype::Struct::Value::Globecoordinate>,
L<Wikibase::Datatype::Struct::Value::Item>,
L<Wikibase::Datatype::Struct::Value::Monolingual>,
L<Wikibase::Datatype::Struct::Value::Property>,
L<Wikibase::Datatype::Struct::Value::Quantity>,
L<Wikibase::Datatype::Struct::Value::String>,
L<Wikibase::Datatype::Struct::Value::Time>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Struct>

Wikibase structure serialization.

=item L<Wikibase::Datatype::Value::Globecoordinate>

Wikibase globe coordinate value datatype.

=item L<Wikibase::Datatype::Value::Item>

Wikibase item value datatype.

=item L<Wikibase::Datatype::Value::Monolingual>

Wikibase monolingual value datatype.

=item L<Wikibase::Datatype::Value::Property>

Wikibase property value datatype.

=item L<Wikibase::Datatype::Value::Quantity>

Wikibase quantity value datatype.

=item L<Wikibase::Datatype::Value::String>

Wikibase string value datatype.

=item L<Wikibase::Datatype::Value::Time>

Wikibase time value datatype.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype-Struct>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2020-2021

BSD 2-Clause License

=head1 VERSION

0.06

=cut
