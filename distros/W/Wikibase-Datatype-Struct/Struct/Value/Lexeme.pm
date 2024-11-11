package Wikibase::Datatype::Struct::Value::Lexeme;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Value::Lexeme;

Readonly::Array our @EXPORT_OK => qw(obj2struct struct2obj);

our $VERSION = 0.13;

sub obj2struct {
	my $obj = shift;

	if (! defined $obj) {
		err "Object doesn't exist.";
	}
	if (! $obj->isa('Wikibase::Datatype::Value::Lexeme')) {
		err "Object isn't 'Wikibase::Datatype::Value::Lexeme'.";
	}

	my $numeric_id = $obj->value;
	$numeric_id =~ s/^L//ms;
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
		|| $struct_hr->{'value'}->{'entity-type'} ne 'lexeme') {

		err "Structure isn't for 'lexeme' datatype.";
	}

	my $obj = Wikibase::Datatype::Value::Lexeme->new(
		'value' => $struct_hr->{'value'}->{'id'},
	);

	return $obj;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Struct::Value::Lexeme - Wikibase lexeme value structure serialization.

=head1 SYNOPSIS

 use Wikibase::Datatype::Struct::Value::Lexeme qw(obj2struct struct2obj);

 my $struct_hr = obj2struct($obj);
 my $obj = struct2obj($struct_hr);

=head1 DESCRIPTION

This conversion is between objects defined in Wikibase::Datatype and structures
serialized via JSON to MediaWiki.

=head1 SUBROUTINES

=head2 C<obj2struct>

 my $struct_hr = obj2struct($obj);

Convert Wikibase::Datatype::Value::Lexeme instance to structure.

Returns reference to hash with structure.

=head2 C<struct2obj>

 my $obj = struct2obj($struct_hr);

Convert structure of item to object.

Returns Wikibase::Datatype::Value::Lexeme instance.

=head1 ERRORS

 obj2struct():
         Object doesn't exist.
         Object isn't 'Wikibase::Datatype::Value::Lexeme'.

 struct2obj():
         Structure isn't for 'lexeme' datatype.

=head1 EXAMPLE1

=for comment filename=obj2struct_value_lexeme.pl

 use strict;
 use warnings;

 use Data::Printer;
 use Wikibase::Datatype::Value::Lexeme;
 use Wikibase::Datatype::Struct::Value::Lexeme qw(obj2struct);

 # Object.
 my $obj = Wikibase::Datatype::Value::Lexeme->new(
         'value' => 'L42284',
 );

 # Get structure.
 my $struct_hr = obj2struct($obj);

 # Dump to output.
 p $struct_hr;

 # Output:
 # \ {
 #     type    "wikibase-entityid",
 #     value   {
 #         entity-type   "lexeme",
 #         id            "L42284",
 #         numeric-id    42284
 #     }
 # }

=head1 EXAMPLE2

=for comment filename=struct2obj_value_lexeme.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Struct::Value::Lexeme qw(struct2obj);

 # Item structure.
 my $struct_hr = {
         'type' => 'wikibase-entityid',
         'value' => {
                 'entity-type' => 'lexeme',
                 'id' => 'L42284',
                 'numberic-id' => 42284,
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
 # Type: lexeme
 # Value: L42284

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<Wikibase::Datatype::Value::Lexeme>.

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

© 2020-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.13

=cut
