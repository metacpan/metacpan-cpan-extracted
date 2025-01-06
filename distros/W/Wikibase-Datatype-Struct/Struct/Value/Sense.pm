package Wikibase::Datatype::Struct::Value::Sense;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Value::Sense;

Readonly::Array our @EXPORT_OK => qw(obj2struct struct2obj);

our $VERSION = 0.14;

sub obj2struct {
	my $obj = shift;

	if (! defined $obj) {
		err "Object doesn't exist.";
	}
	if (! $obj->isa('Wikibase::Datatype::Value::Sense')) {
		err "Object isn't 'Wikibase::Datatype::Value::Sense'.";
	}

	my $struct_hr = {
		'value' => {
			'entity-type' => $obj->type,
			'id' => $obj->value,
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
		|| $struct_hr->{'value'}->{'entity-type'} ne 'sense') {

		err "Structure isn't for 'sense' datatype.";
	}

	my $obj = Wikibase::Datatype::Value::Sense->new(
		'value' => $struct_hr->{'value'}->{'id'},
	);

	return $obj;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Struct::Value::Sense - Wikibase sense value structure serialization.

=head1 SYNOPSIS

 use Wikibase::Datatype::Struct::Value::Sense qw(obj2struct struct2obj);

 my $struct_hr = obj2struct($obj);
 my $obj = struct2obj($struct_hr);

=head1 DESCRIPTION

This conversion is between objects defined in Wikibase::Datatype and structures
serialized via JSON to MediaWiki.

=head1 SUBROUTINES

=head2 C<obj2struct>

 my $struct_hr = obj2struct($obj);

Convert Wikibase::Datatype::Value::Sense instance to structure.

Returns reference to hash with structure.

=head2 C<struct2obj>

 my $obj = struct2obj($struct_hr);

Convert structure of sense to object.

Returns Wikibase::Datatype::Value::Sense instance.

=head1 ERRORS

 obj2struct():
         Object doesn't exist.
         Object isn't 'Wikibase::Datatype::Value::Sense'.

 struct2obj():
         Structure isn't for 'sense' datatype.

=head1 EXAMPLE1

=for comment filename=obj2struct_value_sense.pl

 use strict;
 use warnings;

 use Data::Printer;
 use Wikibase::Datatype::Value::Sense;
 use Wikibase::Datatype::Struct::Value::Sense qw(obj2struct);

 # Object.
 my $obj = Wikibase::Datatype::Value::Sense->new(
         'value' => 'L34727-S1',
 );

 # Get structure.
 my $struct_hr = obj2struct($obj);

 # Dump to output.
 p $struct_hr;

 # Output:
 # \ {
 #     type    "wikibase-entityid",
 #     value   {
 #         entity-type   "sense",
 #         id            "L34727-S1",
 #     }
 # }

=head1 EXAMPLE2

=for comment filename=struct2obj_value_sense.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Struct::Value::Sense qw(struct2obj);

 # Property structure.
 my $struct_hr = {
         'type' => 'wikibase-entityid',
         'value' => {
                 'entity-type' => 'sense',
                 'id' => 'L34727-S1',
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
 # Type: sense
 # Value: L34727-S1

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<Wikibase::Datatype::Value::Sense>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Struct>

Wikibase structure serialization.

=item L<Wikibase::Datatype::Value::Sense>

Wikibase sense value datatype.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype-Struct>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.14

=cut
