package Wikibase::Datatype::Struct::Value::String;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Value::String;

Readonly::Array our @EXPORT_OK => qw(obj2struct struct2obj);

our $VERSION = 0.06;

sub obj2struct {
	my $obj = shift;

	if (! defined $obj) {
		err "Object doesn't exist.";
	}
	if (! $obj->isa('Wikibase::Datatype::Value::String')) {
		err "Object isn't 'Wikibase::Datatype::Value::String'.";
	}

	my $struct_hr = {
		'type' => 'string',
		'value' => $obj->value,
	};

	return $struct_hr;
}

sub struct2obj {
	my $struct_hr = shift;

	if (! exists $struct_hr->{'type'}
		|| $struct_hr->{'type'} ne 'string') {

		err "Structure isn't for 'string' datatype.";
	}

	my $obj = Wikibase::Datatype::Value::String->new(
		'value' => $struct_hr->{'value'},
	);

	return $obj;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Struct::Value::String - Wikibase string structure serialization.

=head1 SYNOPSIS

 use Wikibase::Datatype::Struct::Value::String qw(obj2struct struct2obj);

 my $struct_hr = obj2struct($obj);
 my $obj = struct2obj($struct_hr);

=head1 DESCRIPTION

This conversion is between objects defined in Wikibase::Datatype and structures
serialized via JSON to MediaWiki.

=head1 SUBROUTINES

=head2 C<obj2struct>

 my $struct_hr = obj2struct($obj);

Convert Wikibase::Datatype::Value::String instance to structure.

Returns reference to hash with structure.

=head2 C<struct2obj>

 my $obj = struct2obj($struct_hr);

Convert structure of string to object.

Returns Wikibase::Datatype::Value::String instance.

=head1 ERRORS

 obj2struct():
         Object doesn't exist.
         Object isn't 'Wikibase::Datatype::Value::String'.

 struct2obj():
         Structure isn't for 'string' datatype.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Data::Printer;
 use Wikibase::Datatype::Value::String;
 use Wikibase::Datatype::Struct::Value::String qw(obj2struct);

 # Object.
 my $obj = Wikibase::Datatype::Value::String->new(
         'value' => 'foo',
 );

 # Get structure.
 my $struct_hr = obj2struct($obj);

 # Dump to output.
 p $struct_hr;

 # Output:
 # \ {
 #     type    "string",
 #     value   "foo"
 # }

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Wikibase::Datatype::Struct::Value::String qw(struct2obj);

 # String structure.
 my $struct_hr = {
         'type' => 'string',
         'value' => 'foo',
 };

 # Get object.
 my $obj = struct2obj($struct_hr);

 # Get type.
 my $type = $obj->type;

 # Get value.
 my $value = $obj->value;

 # Print out.
 print "Type: $type\n";
 print "Value: $value\n";

 # Output:
 # Type: string
 # Value: foo

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<Wikibase::Datatype::Value::String>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Struct>

Wikibase structure serialization.

=item L<Wikibase::Datatype::Value::String>

Wikibase string value datatype.

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
