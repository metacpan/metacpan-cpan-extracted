package Wikibase::Datatype::Item;

use strict;
use warnings;

use Error::Pure qw(err);
use Mo qw(build default is);
use Mo::utils qw(check_array_object check_number check_number_of_items);

our $VERSION = 0.21;

has aliases => (
	default => [],
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
	default => 0,
	is => 'ro',
);

has page_id => (
	is => 'ro',
);

has sitelinks => (
	default => [],
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

	# Check sitelinks.
	check_array_object($self, 'sitelinks', 'Wikibase::Datatype::Sitelink',
		'Sitelink');
	check_number_of_items($self, 'sitelinks', 'site', 'Sitelink', 'site');

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

Wikibase::Datatype::Item - Wikibase item datatype.

=head1 SYNOPSIS

 use Wikibase::Datatype::Item;

 my $obj = Wikibase::Datatype::Item->new(%params);
 my $aliases_ar = $obj->aliases;
 my $descriptions_ar = $obj->descriptions;
 my $id = $obj->id;
 my $labels_ar = $obj->labels;
 my $lastrevid = $obj->lastrevid;
 my $modified = $obj->modified;
 my $ns = $obj->ns;
 my $page_id = $obj->page_id;
 my $sitelinks_ar = $obj->sitelinks;
 my $statements_ar = $obj->statements;
 my $title = $obj->title;

=head1 DESCRIPTION

This datatype is item class for representing claim.

=head1 METHODS

=head2 C<new>

 my $obj = Wikibase::Datatype::Item->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<aliases>

Item aliases. Multiple per language.
Reference to array with Wikibase::Datatype::Value::Monolingual instances.
Parameter is optional.

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
Default value is 0.

=item * C<page_id>

Page id. Numeric value.
Parameter is optional.

=item * C<sitelinks>

Item sitelinks. One per site.
Reference to array with Wikibase::Datatype::Sitelink instances.
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

=head2 C<sitelinks>

 my $sitelinks_ar = $obj->sitelinks;

Get sitelinks.

Returns reference to array with Wikibase::Datatype::Sitelink instances.

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
                 Parameter 'sitelinks' must be a array.
                 Parameter 'statements' must be a array.
                 Sitelink isn't 'Wikibase::Datatype::Sitelink' object.
                 Statement isn't 'Wikibase::Datatype::Statement' object.
         From Mo::utils::check_page_id():
                 Parameter 'page_id' must a number.
         From Mo::utils::check_number_of_items():
                 Sitelink for site '%s' has multiple values.
                 Description for language '%s' has multiple values.
                 Label for language '%s' has multiple values.

=head1 EXAMPLE

=for comment filename=create_and_print_item.pl

 use strict;
 use warnings;

 use Unicode::UTF8 qw(decode_utf8 encode_utf8);
 use Wikibase::Datatype::Item;
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
         # instance of (P31) human (Q5)
         'snak' => Wikibase::Datatype::Snak->new(
                 'datatype' => 'wikibase-item',
                 'datavalue' => Wikibase::Datatype::Value::Item->new(
                         'value' => 'Q5',
                 ),
                 'property' => 'P31',
         ),
         'property_snaks' => [
                 # of (P642) alien (Q474741)
                 Wikibase::Datatype::Snak->new(
                         'datatype' => 'wikibase-item',
                         'datavalue' => Wikibase::Datatype::Value::Item->new(
                                 'value' => 'Q474741',
                         ),
                         'property' => 'P642',
                 ),
         ],
         'references' => [
                 Wikibase::Datatype::Reference->new(
                         'snaks' => [
                                 # stated in (P248) Virtual International Authority File (Q53919)
                                 Wikibase::Datatype::Snak->new(
                                         'datatype' => 'wikibase-item',
                                         'datavalue' => Wikibase::Datatype::Value::Item->new(
                                                 'value' => 'Q53919',
                                         ),
                                         'property' => 'P248',
                                 ),

                                 # VIAF ID (P214) 113230702
                                 Wikibase::Datatype::Snak->new(
                                         'datatype' => 'external-id',
                                         'datavalue' => Wikibase::Datatype::Value::String->new(
                                                 'value' => '113230702',
                                         ),
                                         'property' => 'P214',
                                 ),

                                 # retrieved (P813) 7 December 2013
                                 Wikibase::Datatype::Snak->new(
                                         'datatype' => 'time',
                                         'datavalue' => Wikibase::Datatype::Value::Time->new(
                                                 'value' => '+2013-12-07T00:00:00Z',
                                         ),
                                         'property' => 'P813',
                                 ),
                         ],
                 ),
         ],
 );
 my $statement2 = Wikibase::Datatype::Statement->new(
         # sex or gender (P21) male (Q6581097)
         'snak' => Wikibase::Datatype::Snak->new(
                 'datatype' => 'wikibase-item',
                 'datavalue' => Wikibase::Datatype::Value::Item->new(
                         'value' => 'Q6581097',
                 ),
                 'property' => 'P21',
         ),
         'references' => [
                 Wikibase::Datatype::Reference->new(
                         'snaks' => [
                                 # stated in (P248) Virtual International Authority File (Q53919)
                                 Wikibase::Datatype::Snak->new(
                                         'datatype' => 'wikibase-item',
                                         'datavalue' => Wikibase::Datatype::Value::Item->new(
                                                 'value' => 'Q53919',
                                         ),
                                         'property' => 'P248',
                                 ),

                                 # VIAF ID (P214) 113230702
                                 Wikibase::Datatype::Snak->new(
                                         'datatype' => 'external-id',
                                         'datavalue' => Wikibase::Datatype::Value::String->new(
                                                 'value' => '113230702',
                                         ),
                                         'property' => 'P214',
                                 ),

                                 # retrieved (P813) 7 December 2013
                                 Wikibase::Datatype::Snak->new(
                                         'datatype' => 'time',
                                         'datavalue' => Wikibase::Datatype::Value::Time->new(
                                                 'value' => '+2013-12-07T00:00:00Z',
                                         ),
                                         'property' => 'P813',
                                 ),
                         ],
                 ),
         ],
 );

 # Main item.
 my $obj = Wikibase::Datatype::Item->new(
         'aliases' => [
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'cs',
                         'value' => decode_utf8('Douglas Noël Adams'),
                 ),
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'cs',
                         'value' => 'Douglas Noel Adams',
                 ),
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'cs',
                         'value' => 'Douglas N. Adams',
                 ),
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'en',
                         'value' => 'Douglas Noel Adams',
                 ),
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'en',
                         'value' => decode_utf8('Douglas Noël Adams'),
                 ),
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'en',
                         'value' => 'Douglas N. Adams',
                 ),
         ],
         'descriptions' => [
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'cs',
                         'value' => decode_utf8('anglický spisovatel, humorista a dramatik'),
                 ),
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'en',
                         'value' => 'English writer and humorist',
                 ),
         ],
         'id' => 'Q42',
         'labels' => [
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'cs',
                         'value' => 'Douglas Adams',
                 ),
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'en',
                         'value' => 'Douglas Adams',
                 ),
         ],
         'page_id' => 123,
         'sitelinks' => [
                 Wikibase::Datatype::Sitelink->new(
                         'site' => 'cswiki',
                         'title' => 'Douglas Adams',
                 ),
                 Wikibase::Datatype::Sitelink->new(
                         'site' => 'enwiki',
                         'title' => 'Douglas Adams',
                 ),
         ],
         'statements' => [
                 $statement1,
                 $statement2,
         ],
         'title' => 'Q42',
 );

 # Print out.
 print "Title: ".$obj->title."\n";
 print 'Id: '.$obj->id."\n";
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
 print "Sitelinks:\n";
 foreach my $sitelink (@{$obj->sitelinks}) {
         print "\t".$sitelink->title.' ('.$sitelink->site.")\n";
 }
 print "Statements:\n";
 foreach my $statement (@{$obj->statements}) {
         print "\tStatement:\n";
         print "\t\t".$statement->snak->property.' -> '.$statement->snak->datavalue->value."\n";
         print "\t\tQualifers:\n";
         foreach my $property_snak (@{$statement->property_snaks}) {
                 print "\t\t\t".$property_snak->property.' -> '.
                         $property_snak->datavalue->value."\n";
         }
         print "\t\tReferences:\n";
         foreach my $reference (@{$statement->references}) {
                 print "\t\t\tReference:\n";
                 foreach my $reference_snak (@{$reference->snaks}) {
                         print "\t\t\t".$reference_snak->property.' -> '.
                                 $reference_snak->datavalue->value."\n";
                 }
         }
 }

 # Output:
 # Title: Q42
 # Id: Q42
 # Page id: 123
 # Labels:
 #         Douglas Adams (cs)
 #         Douglas Adams (en)
 # Descriptions:
 #         anglický spisovatel, humorista a dramatik (cs)
 #         English writer and humorist (en)
 # Aliases:
 #         Douglas Noël Adams (cs)
 #         Douglas Noel Adams (cs)
 #         Douglas N. Adams (cs)
 #         Douglas Noel Adams (en)
 #         Douglas Noël Adams (en)
 #         Douglas N. Adams (en)
 # Sitelinks:
 #         Douglas Adams (cswiki)
 #         Douglas Adams (enwiki)
 # Statements:
 #         Statement:
 #                 P31 -> Q5
 #                 Qualifers:
 #                         P642 -> Q474741
 #                 References:
 #                         Reference:
 #                         P248 -> Q53919
 #                         P214 -> 113230702
 #                         P813 -> +2013-12-07T00:00:00Z
 #         Statement:
 #                 P21 -> Q6581097
 #                 Qualifers:
 #                 References:
 #                         Reference:
 #                         P248 -> Q53919
 #                         P214 -> 113230702
 #                         P813 -> +2013-12-07T00:00:00Z

=head1 DEPENDENCIES

L<Error::Pure>,
L<Mo>,
L<Mo:utils>.

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

0.21

=cut
