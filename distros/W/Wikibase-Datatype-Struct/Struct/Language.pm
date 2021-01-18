package Wikibase::Datatype::Struct::Language;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Wikibase::Datatype::Value::Monolingual;

Readonly::Array our @EXPORT_OK => qw(obj2struct struct2obj);

our $VERSION = 0.06;

sub obj2struct {
	my $obj = shift;

	if (! defined $obj) {
		err "Object doesn't exist.";
	}
	if (! $obj->isa('Wikibase::Datatype::Value::Monolingual')) {
		err "Object isn't 'Wikibase::Datatype::Value::Monolingual'.";
	}

	my $struct_hr = {
		'language' => $obj->language,
		'value' => $obj->value,
	};

	return $struct_hr;
}

sub struct2obj {
	my $struct_hr = shift;

	my $obj = Wikibase::Datatype::Value::Monolingual->new(
		'language' => $struct_hr->{'language'},
		'value' => $struct_hr->{'value'},
	);

	return $obj;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Struct::Language - Wikibase language structure serialization.

=head1 SYNOPSIS

 use Wikibase::Datatype::Struct::Language qw(obj2struct struct2obj);

 my $struct_hr = obj2struct($obj);
 my $obj = struct2obj($struct_hr);

=head1 DESCRIPTION

This conversion is between objects defined in Wikibase::Datatype and structures
serialized via JSON to MediaWiki.

=head1 SUBROUTINES

=head2 C<obj2struct>

 my $struct_hr = obj2struct($obj);

Convert Wikibase::Datatype::Value::Monolingual instance to structure.

Returns reference to hash with structure.

=head2 C<struct2obj>

 my $obj = struct2obj($struct_hr);

Convert structure of language to object.

Returns Wikibase::Datatype::Value::Monolingual instance.

=head1 ERRORS

 obj2struct():
         Object doesn't exist.
         Object isn't 'Wikibase::Datatype::Value::Monolingual'.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Data::Printer;
 use Wikibase::Datatype::Value::Monolingual;
 use Wikibase::Datatype::Struct::Value::Monolingual qw(obj2struct);

 # Object.
 my $obj = Wikibase::Datatype::Value::Monolingual->new(
         'language' => 'en',
         'value' => 'English text',
 );

 # Get structure.
 my $struct_hr = obj2struct($obj);

 # Dump to output.
 p $struct_hr;

 # Output:
 # \ {
 #     language   "en",
 #     value      "English text"
 # }

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Wikibase::Datatype::Struct::Language qw(struct2obj);

 # Monolingualtext structure.
 my $struct_hr = {
         'language' => 'en',
         'text' => 'English text',
 };

 # Get object.
 my $obj = struct2obj($struct_hr);

 # Get language.
 my $language = $obj->language;

 # Get type.
 my $type = $obj->type;

 # Get value.
 my $value = $obj->value;

 # Print out.
 print "Language: $language\n";
 print "Type: $type\n";
 print "Value: $value\n";

 # Output:
 # Language: en
 # Type: monolingualtext
 # Value: English text

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<Wikibase::Datatype::Value::Monolingual>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Struct>

Wikibase structure serialization.

=item L<Wikibase::Datatype::Value::Monolingual>

Wikibase monolingual value datatype.

=item L<Wikibase::Datatype::Struct::Value::Monolingual>

Wikibase monolingual structure serialization.

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
