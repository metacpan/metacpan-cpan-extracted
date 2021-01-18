package Wikibase::Datatype::Struct::Value::Item;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Value::Item;

Readonly::Array our @EXPORT_OK => qw(obj2struct struct2obj);

our $VERSION = 0.06;

sub obj2struct {
	my $obj = shift;

	if (! defined $obj) {
		err "Object doesn't exist.";
	}
	if (! $obj->isa('Wikibase::Datatype::Value::Item')) {
		err "Object isn't 'Wikibase::Datatype::Value::Item'.";
	}

	my $numeric_id = $obj->value;
	$numeric_id =~ s/^Q//ms;
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
		|| $struct_hr->{'type'} ne 'wikibase-entityid'
		|| ! exists $struct_hr->{'value'}->{'entity-type'}
		|| $struct_hr->{'value'}->{'entity-type'} ne 'item') {

		err "Structure isn't for 'item' datatype.";
	}

	my $obj = Wikibase::Datatype::Value::Item->new(
		'value' => $struct_hr->{'value'}->{'id'},
	);

	return $obj;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Struct::Value::Item - Wikibase item structure serialization.

=head1 SYNOPSIS

 use Wikibase::Datatype::Struct::Value::Item qw(obj2struct struct2obj);

 my $struct_hr = obj2struct($obj);
 my $obj = struct2obj($struct_hr);

=head1 DESCRIPTION

This conversion is between objects defined in Wikibase::Datatype and structures
serialized via JSON to MediaWiki.

=head1 SUBROUTINES

=head2 C<obj2struct>

 my $struct_hr = obj2struct($obj);

Convert Wikibase::Datatype::Value::Item instance to structure.

Returns reference to hash with structure.

=head2 C<struct2obj>

 my $obj = struct2obj($struct_hr);

Convert structure of item to object.

Returns Wikibase::Datatype::Value::Item instance.

=head1 ERRORS

 obj2struct():
         Object doesn't exist.
         Object isn't 'Wikibase::Datatype::Value::Item'.

 struct2obj():
         Structure isn't for 'item' datatype.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Data::Printer;
 use Wikibase::Datatype::Value::Item;
 use Wikibase::Datatype::Struct::Value::Item qw(obj2struct);

 # Object.
 my $obj = Wikibase::Datatype::Value::Item->new(
         'value' => 'Q123',
 );

 # Get structure.
 my $struct_hr = obj2struct($obj);

 # Dump to output.
 p $struct_hr;

 # Output:
 # \ {
 #     type    "wikibase-entityid",
 #     value   {
 #         entity-type   "item",
 #         id            "Q123",
 #         numeric-id    123
 #     }
 # }

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Wikibase::Datatype::Struct::Value::Item qw(struct2obj);

 # Item structure.
 my $struct_hr = {
         'type' => 'wikibase-entityid',
         'value' => {
                 'entity-type' => 'item',
                 'id' => 'Q123',
                 'numberic-id' => 123,
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
 # Type: item
 # Value: Q123

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<Wikibase::Datatype::Value::Item>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Struct>

Wikibase structure serialization.

=item L<Wikibase::Datatype::Value::Item>

Wikibase item value datatype.

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
