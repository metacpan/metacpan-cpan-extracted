package Wikibase::Datatype::Struct::Value::Property;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Value::Property;

Readonly::Array our @EXPORT_OK => qw(obj2struct struct2obj);

our $VERSION = 0.11;

sub obj2struct {
	my $obj = shift;

	if (! defined $obj) {
		err "Object doesn't exist.";
	}
	if (! $obj->isa('Wikibase::Datatype::Value::Property')) {
		err "Object isn't 'Wikibase::Datatype::Value::Property'.";
	}

	my $numeric_id = $obj->value;
	$numeric_id =~ s/^P//ms;
	my $struct_hr = {
		'value' => {
			'entity-type' => $obj->type,
			'id' => $obj->value,
			'numeric-id' => $numeric_id,
		},
		'type' => 'wikibase-entityid',
	};

	return $struct_hr;
}

sub struct2obj {
	my $struct_hr = shift;

	if (! exists $struct_hr->{'type'}
		|| ! defined $struct_hr->{'type'}
		|| $struct_hr->{'type'} ne 'wikibase-entityid'
		|| ! exists $struct_hr->{'value'}
		|| ! exists $struct_hr->{'value'}->{'entity-type'}
		|| ! defined $struct_hr->{'value'}->{'entity-type'}
		|| $struct_hr->{'value'}->{'entity-type'} ne 'property') {

		err "Structure isn't for 'property' datatype.";
	}

	my $obj = Wikibase::Datatype::Value::Property->new(
		'value' => $struct_hr->{'value'}->{'id'},
	);

	return $obj;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Struct::Value::Property - Wikibase property value structure serialization.

=head1 SYNOPSIS

 use Wikibase::Datatype::Struct::Value::Property qw(obj2struct struct2obj);

 my $struct_hr = obj2struct($obj);
 my $obj = struct2obj($struct_hr);

=head1 DESCRIPTION

This conversion is between objects defined in Wikibase::Datatype and structures
serialized via JSON to MediaWiki.

=head1 SUBROUTINES

=head2 C<obj2struct>

 my $struct_hr = obj2struct($obj);

Convert Wikibase::Datatype::Value::Property instance to structure.

Returns reference to hash with structure.

=head2 C<struct2obj>

 my $obj = struct2obj($struct_hr);

Convert structure of property to object.

Returns Wikibase::Datatype::Value::Property instance.

=head1 ERRORS

 obj2struct():
         Object doesn't exist.
         Object isn't 'Wikibase::Datatype::Value::Property'.

 struct2obj():
         Structure isn't for 'property' datatype.

=head1 EXAMPLE1

=for comment filename=obj2struct_value_property.pl

 use strict;
 use warnings;

 use Data::Printer;
 use Wikibase::Datatype::Value::Property;
 use Wikibase::Datatype::Struct::Value::Property qw(obj2struct);

 # Object.
 my $obj = Wikibase::Datatype::Value::Property->new(
         'value' => 'P123',
 );

 # Get structure.
 my $struct_hr = obj2struct($obj);

 # Dump to output.
 p $struct_hr;

 # Output:
 # \ {
 #     type    "wikibase-entityid",
 #     value   {
 #         entity-type   "property",
 #         id            "P123",
 #         numeric-id    123
 #     }
 # }

=head1 EXAMPLE2

=for comment filename=struct2obj_value_property.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Struct::Value::Property qw(struct2obj);

 # Property structure.
 my $struct_hr = {
         'type' => 'wikibase-entityid',
         'value' => {
                 'entity-type' => 'property',
                 'id' => 'P123',
                 'numeric-id' => 123,
         },
 };

 # Get object.
 my $obj = struct2obj($struct_hr);

 # Get value.
 my $value = $obj->value;

 # Get type.
 my $type = $obj->type;

 # Print out.
 print "Type: $type\n";
 print "Value: $value\n";

 # Output:
 # Type: property
 # Value: P123

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<Wikibase::Datatype::Value::Property>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Struct>

Wikibase structure serialization.

=item L<Wikibase::Datatype::Value::Property>

Wikibase property value datatype.

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
