package Wikibase::Datatype::Lexeme;

use strict;
use warnings;

use Error::Pure qw(err);
use Mo qw(build default is);
use Mo::utils qw(check_array_object check_number);
use Wikibase::Datatype::Utils qw(check_entity);

our $VERSION = 0.25;

has forms => (
	default => [],
	is => 'ro',
);

has id => (
	is => 'ro',
);

has language => (
	is => 'ro',
);

has lastrevid => (
	is => 'ro',
);

has lemmas => (
	default => [],
	is => 'ro',
);

has lexical_category => (
	is => 'ro',
);

has modified => (
	is => 'ro',
);

has ns => (
	default => 146,
	is => 'ro',
);

has page_id => (
	is => 'ro',
);

has senses => (
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

	# Check forms.
	check_array_object($self, 'forms', 'Wikibase::Datatype::Form',
		'Form');

	# Check lemmas.
	check_array_object($self, 'lemmas', 'Wikibase::Datatype::Value::Monolingual',
		'Lemma');

	# Check lexical category.
	check_entity($self, 'lexical_category');

	# Check language.
	check_entity($self, 'language');

	# Check page id.
	check_number($self, 'page_id');

	# Check senses.
	check_array_object($self, 'senses', 'Wikibase::Datatype::Sense',
		'Sense');

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

Wikibase::Datatype::Lexeme - Wikibase lexeme datatype.

=head1 SYNOPSIS

 use Wikibase::Datatype::Lexeme;

 my $obj = Wikibase::Datatype::Lexeme->new(%params);
 my $forms_ar = $obj->forms;
 my $id = $obj->id;
 my $language = $obj->language;
 my $lastrevid = $obj->lastrevid;
 my $lemmas_ar = $obj->lemmas;
 my $lexical_category = $obj->lexical_category;
 my $modified = $obj->modified;
 my $ns = $obj->ns;
 my $page_id = $obj->page_id;
 my $senses_ar = $obj->senses;
 my $statements_ar = $obj->statements;
 my $title = $obj->title;

=head1 DESCRIPTION

This datatype is item class for representing claim.

=head1 METHODS

=head2 C<new>

 my $obj = Wikibase::Datatype::Lexeme->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<forms>

Forms.
Reference to array with Wikibase::Datatype::Form instances.
Parameter is optional.

=item * C<id>

Id.
Parameter is optional.

=item * C<language>

Language. Link to QID.
Parameter is optional.

=item * C<lastrevid>

Last revision ID.
Parameter is optional.

=item * C<lemmas>

Lemmas.
Reference to array with Wikibase::Datatype::Value::Monolingual instances.
Parameter is optional.

=item * C<lexical_category>

Lexical category. Link to QID.
Parameter is optional.

=item * C<modified>

Date of modification.
Parameter is optional.

=item * C<ns>

Namespace.
Default value is 146.

=item * C<page_id>

Page id. Numeric value.
Parameter is optional.

=item * C<senses>

Senses.
Reference to array with Wikibase::Datatype::Sense instances.
Parameter is optional.

=item * C<statements>

Item statements.
Reference to array with Wikibase::Datatype::Statement instances.
Parameter is optional.

=item * C<title>

Lexeme title.
Parameter is optional.

=back

=head2 C<forms>

 my $forms_ar = $obj->forms;

Get forms.

Returns reference to array with Wikibase::Datatype::Form instances.

=head2 C<id>

 my $id = $obj->id;

Get id.

Returns string.

=head2 C<language>

 my $language = $obj->language;

Get language.

Returns string with QID.

=head2 C<lastrevid>

 my $lastrevid = $obj->lastrevid;

Get last revision ID.

Returns string.

=head2 C<lemmas>

 my $lemmas_ar = $obj->lemmas;

Get lemmas.

Returns reference to array with Wikibase::Datatype::Value::Monolingual instances.

=head2 C<lexical_category>

 my $lexical_category = $obj->lexical_category;

Get lexical category.

Returns string with QID.

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

=head2 C<senses>

 my $senses_ar = $obj->senses;

Get senses.

Returns reference to array with Wikibase::Datatype::Sense instances.

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
                 Form isn't 'Wikibase::Datatype::Form' object.
                 Lemma isn't 'Wikibase::Datatype::Value::Monolingual' object.
                 Parameter 'forms' must be a array.
                 Parameter 'lemmas' must be a array.
                 Parameter 'senses' must be a array.
                 Parameter 'statements' must be a array.
                 Sense isn't 'Wikibase::Datatype::Sense' object.
                 Statement isn't 'Wikibase::Datatype::Statement' object.
         From Wikibase::Datatype::Utils::check_entity():
                 Parameter 'language' must begin with 'Q' and number after it.";
                 Parameter 'lexical_category' must begin with 'Q' and number after it.";

=head1 EXAMPLE

=for comment filename=create_and_print_lexeme.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Lexeme;
 use Wikibase::Datatype::Reference;
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
 my $obj = Wikibase::Datatype::Lexeme->new(
         'id' => 'L469',
         'lemmas' => [
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'cs',
                         'value' => 'pes',
                 ),
         ],
         'statements' => [
                 $statement1,
                 $statement2,
         ],
         'title' => 'Lexeme:L469',
 );

 # Print out.
 print "Title: ".$obj->title."\n";
 print 'Id: '.$obj->id."\n";
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
 # Title: Lexeme:L469
 # Id: L469
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
L<Mo::utils>,
L<Wikibase::Datatype::Utils>.

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

© 2020-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.25

=cut
