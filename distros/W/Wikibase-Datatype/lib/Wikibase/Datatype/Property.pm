package Wikibase::Datatype::Property;

use strict;
use warnings;

use Error::Pure qw(err);
use List::Util qw(none);
use Mo qw(build default is);
use Mo::utils qw(check_array_object check_number check_number_of_items check_required);
use Readonly;

# Pairs data type and datatype.
Readonly::Hash our %DATA_TYPES => (
	'commonsMedia' => 'Wikibase::Datatype::Value::String',
	'external-id' => 'Wikibase::Datatype::Value::String',
	'geo-shape' => 'Wikibase::Datatype::Value::String',
	'globe-coordinate' => 'Wikibase::Datatype::Value::Globecoordinate',
	'math' => 'Wikibase::Datatype::Value::String',
	'monolingualtext' => 'Wikibase::Datatype::Value::Monolingual',
	'musical-notation' => 'Wikibase::Datatype::Value::String',
	'quantity' => 'Wikibase::Datatype::Value::Quantity',
	'string' => 'Wikibase::Datatype::Value::String',
	'tabular-data' => 'Wikibase::Datatype::Value::String',
	'time' => 'Wikibase::Datatype::Value::Time',
	'url' => 'Wikibase::Datatype::Value::String',
	'wikibase-item' => 'Wikibase::Datatype::Value::Item',
	'wikibase-property' => 'Wikibase::Datatype::Value::Property',
);

our $VERSION = 0.22;

has aliases => (
	default => [],
	is => 'ro',
);

has datatype => (
	is => 'ro',
);

has descriptions => (
	default => [],
	is => 'ro',
);

has id => (
	is => 'ro',
);

has labels => (
	default => [],
	is => 'ro',
);

has lastrevid => (
	is => 'ro',
);

has modified => (
	is => 'ro',
);

has ns => (
	default => 120,
	is => 'ro',
);

has page_id => (
	is => 'ro',
);

has statements => (
	default => [],
	is => 'ro',
);

has title => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check aliases.
	check_array_object($self, 'aliases', 'Wikibase::Datatype::Value::Monolingual',
		'Alias');

	# Check data type.
	check_required($self, 'datatype');
	if (none { $self->{'datatype'} eq $_ } keys %DATA_TYPES) {
		err "Parameter 'datatype' = '$self->{'datatype'}' isn't supported.";
	}

	# Check descriptions.
	check_array_object($self, 'descriptions', 'Wikibase::Datatype::Value::Monolingual',
		'Description');
	check_number_of_items($self, 'descriptions', 'language', 'Description', 'language');

	# Check labels.
	check_array_object($self, 'labels', 'Wikibase::Datatype::Value::Monolingual',
		'Label');
	check_number_of_items($self, 'labels', 'language', 'Label', 'language');

	# Check page id.
	check_number($self, 'page_id');

	# Check statements.
	check_array_object($self, 'statements', 'Wikibase::Datatype::Statement',
		'Statement');

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Property - Wikibase property datatype.

=head1 SYNOPSIS

 use Wikibase::Datatype::Property;

 my $obj = Wikibase::Datatype::Property->new(%params);
 my $aliases_ar = $obj->aliases;
 my $datatype = $obj->datatype;
 my $descriptions_ar = $obj->descriptions;
 my $id = $obj->id;
 my $labels_ar = $obj->labels;
 my $lastrevid = $obj->lastrevid;
 my $modified = $obj->modified;
 my $ns = $obj->ns;
 my $page_id = $obj->page_id;
 my $statements_ar = $obj->statements;
 my $title = $obj->title;

=head1 DESCRIPTION

This datatype is property class for representing property.

=head1 METHODS

=head2 C<new>

 my $obj = Wikibase::Datatype::Property->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<aliases>

Item aliases. Multiple per language.
Reference to array with Wikibase::Datatype::Value::Monolingual instances.
Parameter is optional.

=item * C<datatype>

Type of data.
Parameter is required.

 Possible datatypes are (datavalue instance in parenthesis):
 - commonsMedia (Wikibase::Datatype::Value::String)
 - external-id (Wikibase::Datatype::Value::String)
 - geo-shape (Wikibase::Datatype::Value::String)
 - globe-coordinate (Wikibase::Datatype::Value::Globecoordinate)
 - math (Wikibase::Datatype::Value::String)
 - monolingualtext (Wikibase::Datatype::Value::Monolingual)
 - musical-notation (Wikibase::Datatype::Value::String)
 - quantity (Wikibase::Datatype::Value::Quantity)
 - string (Wikibase::Datatype::Value::String)
 - tabular-data (Wikibase::Datatype::Value::String)
 - time (Wikibase::Datatype::Value::Time)
 - url (Wikibase::Datatype::Value::String)
 - wikibase-item (Wikibase::Datatype::Value::Item)
 - wikibase-property (Wikibase::Datatype::Value::Property)

=item * C<descriptions>

Item descriptions. One per language.
Reference to array with Wikibase::Datatype::Value::Monolingual instances.
Parameter is optional.

=item * C<id>

Id.
Parameter is optional.

=item * C<labels>

Item descriptions. One per language.
Reference to array with Wikibase::Datatype::Value::Monolingual instances.
Parameter is optional.

=item * C<lastrevid>

Last revision ID.
Parameter is optional.

=item * C<modified>

Date of modification.
Parameter is optional.

=item * C<ns>

Namespace.
Default value is 120.

=item * C<page_id>

Page id. Numeric value.
Parameter is optional.

=item * C<statements>

Item statements.
Reference to array with Wikibase::Datatype::Statement instances.
Parameter is optional.

=item * C<title>

Item title.
Parameter is optional.

=back

=head2 C<aliases>

 my $aliases_ar = $obj->aliases;

Get aliases.

Returns reference to array with Wikibase::Datatype::Value::Monolingual instances.

=head2 C<datatype>

 my $datatype = $obj->datatype;

Get data type.

Returns string.

=head2 C<descriptions>

 my $descriptions_ar = $obj->descriptions;

Get descriptions.

Returns reference to array with Wikibase::Datatype::Value::Monolingual instances.

=head2 C<id>

 my $id = $obj->id;

Get id.

Returns string.

=head2 C<labels>

 my $labels_ar = $obj->labels;

Get labels.

Returns reference to array with Wikibase::Datatype::Value::Monolingual instances.

=head2 C<lastrevid>

 my $lastrevid = $obj->lastrevid;

Get last revision ID.

Returns string.

=head2 C<modified>

 my $modified = $obj->modified;

Get date of modification.

Returns string.

=head2 C<ns>

 my $ns = $obj->ns;

Get namespace.

Returns number.

=head2 C<page_id>

 my $page_id = $obj->page_id;

Get page id.

Returns number.

=head2 C<statements>

 my $statements_ar = $obj->statements;

Get statements.

Returns reference to array with Wikibase::Datatype::Statement instances.

=head2 C<title>

 my $title = $obj->title;

Get title.

Returns string.

=head1 ERRORS

 new():
         From Mo::utils::check_array_object():
                 Alias isn't 'Wikibase::Datatype::Value::Monolingual' object.
                 Description isn't 'Wikibase::Datatype::Value::Monolingual' object.
                 Label isn't 'Wikibase::Datatype::Value::Monolingual' object.
                 Parameter 'aliases' must be a array.
                 Parameter 'descriptions' must be a array.
                 Parameter 'labels' must be a array.
                 Parameter 'statements' must be a array.
                 Statement isn't 'Wikibase::Datatype::Statement' object.
         From Mo::utils::check_page_id():
                 Parameter 'page_id' must a number.
         From Mo::utils::check_number_of_items():
                 Description for language '%s' has multiple values.
                 Label for language '%s' has multiple values.
         From Mo::utils::check_required():
                 Parameter 'datatype' is required.
         Parameter 'datatype' = '%s' isn't supported.

=head1 EXAMPLE

=for comment filename=create_and_print_property.pl

 use strict;
 use warnings;

 use Unicode::UTF8 qw(decode_utf8 encode_utf8);
 use Wikibase::Datatype::Property;
 use Wikibase::Datatype::Reference;
 use Wikibase::Datatype::Sitelink;
 use Wikibase::Datatype::Snak;
 use Wikibase::Datatype::Statement;
 use Wikibase::Datatype::Value::Item;
 use Wikibase::Datatype::Value::Monolingual;
 use Wikibase::Datatype::Value::String;
 use Wikibase::Datatype::Value::Time;

 # Object.
 my $statement1 = Wikibase::Datatype::Statement->new(
         # instance of (P31) Wikidata property (Q18616576)
         'snak' => Wikibase::Datatype::Snak->new(
                 'datatype' => 'wikibase-item',
                 'datavalue' => Wikibase::Datatype::Value::Item->new(
                         'value' => 'Q18616576',
                 ),
                 'property' => 'P31',
         ),
 );

 # Main item.
 my $obj = Wikibase::Datatype::Property->new(
         'aliases' => [
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'cs',
                         'value' => 'je',
                 ),
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'en',
                         'value' => 'is a',
                 ),
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'en',
                         'value' => 'is an',
                 ),
         ],
         'datatype' => 'wikibase-item',
         'descriptions' => [
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'cs',
                         'value' => decode_utf8('tato položka je jedna konkrétní věc (exemplář, '.
                                 'příklad) patřící do této třídy, kategorie nebo skupiny předmětů'),
                 ),
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'en',
                         'value' => 'that class of which this subject is a particular example and member',
                 ),
         ],
         'id' => 'P31',
         'labels' => [
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'cs',
                         'value' => decode_utf8('instance (čeho)'),
                 ),
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'en',
                         'value' => 'instance of',
                 ),
         ],
         'page_id' => 3918489,
         'statements' => [
                 $statement1,
         ],
         'title' => 'Property:P31',
 );

 # Print out.
 print "Title: ".$obj->title."\n";
 print 'Id: '.$obj->id."\n";
 print 'Data type: '.$obj->datatype."\n";
 print 'Page id: '.$obj->page_id."\n";
 print "Labels:\n";
 foreach my $label (sort { $a->language cmp $b->language } @{$obj->labels}) {
         print "\t".encode_utf8($label->value).' ('.$label->language.")\n";
 }
 print "Descriptions:\n";
 foreach my $desc (sort { $a->language cmp $b->language } @{$obj->descriptions}) {
         print "\t".encode_utf8($desc->value).' ('.$desc->language.")\n";
 }
 print "Aliases:\n";
 foreach my $alias (sort { $a->language cmp $b->language } @{$obj->aliases}) {
         print "\t".encode_utf8($alias->value).' ('.$alias->language.")\n";
 }
 print "Statements:\n";
 foreach my $statement (@{$obj->statements}) {
         print "\tStatement:\n";
         print "\t\t".$statement->snak->property.' -> '.$statement->snak->datavalue->value."\n";
 }

 # Output:
 # Title: Property:P31
 # Id: P31
 # Data type: wikibase-item
 # Page id: 3918489
 # Labels:
 #         instance (čeho) (cs)
 #         instance of (en)
 # Descriptions:
 #         tato položka je jedna konkrétní věc (exemplář, příklad) patřící do této třídy, kategorie nebo skupiny předmětů (cs)
 #         that class of which this subject is a particular example and member (en)
 # Aliases:
 #         je (cs)
 #         is a (en)
 #         is an (en)
 # Statements:
 #         Statement:
 #                 P31 -> Q18616576

=head1 DEPENDENCIES

L<Error::Pure>,
L<List::Util>,
L<Mo>,
L<Mo:utils>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype>

Wikibase datatypes.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.22

=cut
