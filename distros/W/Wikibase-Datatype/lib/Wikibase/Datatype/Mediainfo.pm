package Wikibase::Datatype::Mediainfo;

use strict;
use warnings;

use Error::Pure qw(err);
use Mo qw(build default is);
use Mo::utils qw(check_array_object check_number check_number_of_items);

our $VERSION = 0.33;

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
	default => 6,
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
	check_array_object($self, 'statements', 'Wikibase::Datatype::MediainfoStatement',
		'MediainfoStatement');

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Mediainfo - Wikibase mediainfo datatype.

=head1 SYNOPSIS

 use Wikibase::Datatype::Mediainfo;

 my $obj = Wikibase::Datatype::Mediainfo->new(%params);
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

This datatype is mediainfo class for representing commons structured data.

=head1 METHODS

=head2 C<new>

 my $obj = Wikibase::Datatype::Mediainfo->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<descriptions>

Mediainfo descriptions. One per language.
Reference to array with Wikibase::Datatype::Value::Monolingual instances.
Parameter is optional.

=item * C<id>

Id.
Parameter is optional.

=item * C<labels>

Mediainfo descriptions. One per language.
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
Default value is 6.

=item * C<page_id>

Page id. Numeric value.
Parameter is optional.

=item * C<statements>

Mediainfo statements.
Reference to array with Wikibase::Datatype::MediainfoStatement instances.
Parameter is optional.

=item * C<title>

Mediainfo title.
Parameter is optional.

=back

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

Returns reference to array with Wikibase::Datatype::MediainfoStatement instances.

=head2 C<title>

 my $title = $obj->title;

Get title.

Returns string.

=head1 ERRORS

 new():
         From Mo::utils::check_array_object():
                 Description isn't 'Wikibase::Datatype::Value::Monolingual' object.
                 Label isn't 'Wikibase::Datatype::Value::Monolingual' object.
                 Parameter 'descriptions' must be a array.
                 Parameter 'labels' must be a array.
                 Parameter 'statements' must be a array.
                 MediainfoStatement isn't 'Wikibase::Datatype::MediainfoStatement' object.
         From Mo::utils::check_page_id():
                 Parameter 'page_id' must a number.
         From Mo::utils::check_number_of_items():
                 Sitelink for site '%s' has multiple values.
                 Description for language '%s' has multiple values.
                 Label for language '%s' has multiple values.

=head1 EXAMPLE

=for comment filename=create_and_print_mediainfo.pl

 use strict;
 use warnings;

 use Unicode::UTF8 qw(decode_utf8 encode_utf8);
 use Wikibase::Datatype::Mediainfo;
 use Wikibase::Datatype::MediainfoSnak;
 use Wikibase::Datatype::MediainfoStatement;
 use Wikibase::Datatype::Value::Item;
 use Wikibase::Datatype::Value::Monolingual;
 use Wikibase::Datatype::Value::String;
 use Wikibase::Datatype::Value::Time;

 # Statements.
 my $statement1 = Wikibase::Datatype::MediainfoStatement->new(
         # depicts (P180) beach (Q40080)
         'snak' => Wikibase::Datatype::MediainfoSnak->new(
                 'datavalue' => Wikibase::Datatype::Value::Item->new(
                         'value' => 'Q40080',
                 ),
                 'property' => 'P180',
         ),
 );
 my $statement2 = Wikibase::Datatype::MediainfoStatement->new(
         # creator (P170)
         'snak' => Wikibase::Datatype::MediainfoSnak->new(
                  'property' => 'P170',
                  'snaktype' => 'novalue',
         ),
         'property_snaks' => [
                 # Wikimedia username (P4174): Lviatour
                 Wikibase::Datatype::MediainfoSnak->new(
                          'datavalue' => Wikibase::Datatype::Value::String->new(
                                  'value' => 'Lviatour',
                          ),
                          'property' => 'P4174',
                 ),

                 # URL (P2699): https://commons.wikimedia.org/wiki/user:Lviatour
                 Wikibase::Datatype::MediainfoSnak->new(
                          'datavalue' => Wikibase::Datatype::Value::String->new(
                                  'value' => 'https://commons.wikimedia.org/wiki/user:Lviatour',
                          ),
                          'property' => 'P2699',
                 ),

                 # author name string (P2093): Lviatour
                 Wikibase::Datatype::MediainfoSnak->new(
                          'datavalue' => Wikibase::Datatype::Value::String->new(
                                  'value' => 'Lviatour',
                          ),
                          'property' => 'P2093',
                 ),

                 # object has role (P3831): photographer (Q33231)
                 Wikibase::Datatype::MediainfoSnak->new(
                          'datavalue' => Wikibase::Datatype::Value::Item->new(
                                  'value' => 'Q33231',
                          ),
                          'property' => 'P3831',
                 ),
         ],
 );
 my $statement3 = Wikibase::Datatype::MediainfoStatement->new(
         # copyright status (P6216) copyrighted (Q50423863)
         'snak' => Wikibase::Datatype::MediainfoSnak->new(
                 'datavalue' => Wikibase::Datatype::Value::Item->new(
                         'value' => 'Q50423863',
                 ),
                 'property' => 'P6216',
         ),
 );
 my $statement4 = Wikibase::Datatype::MediainfoStatement->new(
         # copyright license (P275) Creative Commons Attribution-ShareAlike 3.0 Unported (Q14946043)
         'snak' => Wikibase::Datatype::MediainfoSnak->new(
                 'datavalue' => Wikibase::Datatype::Value::Item->new(
                         'value' => 'Q14946043',
                 ),
                 'property' => 'P275',
         ),
 );
 my $statement5 = Wikibase::Datatype::MediainfoStatement->new(
         # Commons quality assessment (P6731) Wikimedia Commons featured picture (Q63348049)
         'snak' => Wikibase::Datatype::MediainfoSnak->new(
                 'datavalue' => Wikibase::Datatype::Value::Item->new(
                         'value' => 'Q63348049',
                 ),
                 'property' => 'P6731',
         ),
 );
 my $statement6 = Wikibase::Datatype::MediainfoStatement->new(
         # inception (P571) 16. 7. 2011
         'snak' => Wikibase::Datatype::MediainfoSnak->new(
                 'datavalue' => Wikibase::Datatype::Value::Time->new(
                         'value' => '+2011-07-16T00:00:00Z',
                 ),
                 'property' => 'P571',
         ),
 );
 my $statement7 = Wikibase::Datatype::MediainfoStatement->new(
         # source of file (P7482) original creation by uploader (Q66458942)
         'snak' => Wikibase::Datatype::MediainfoSnak->new(
                 'datavalue' => Wikibase::Datatype::Value::Item->new(
                         'value' => 'Q66458942',
                 ),
                 'property' => 'P7482',
         ),
 );

 # Main mediainfo.
 my $obj = Wikibase::Datatype::Mediainfo->new(
         'id' => 'M16041229',
         'labels' => [
                 Wikibase::Datatype::Value::Monolingual->new(
                         'language' => 'cs',
                         'value' => decode_utf8('Pláž Papagayo, ostrov Lanzarote, Kanárské ostrovy, Španělsko'),
                 ),
         ],
         'lastrevid' => 528085091,
         'modified' => '2021-01-24T11:44:10Z',
         'page_id' => 16041229,
         'statements' => [
                 $statement1,
                 $statement2,
                 $statement3,
                 $statement4,
                 $statement5,
                 $statement6,
                 $statement7,
         ],
         'title' => 'File:Lanzarote 1 Luc Viatour.jpg',
 );

 # Print out.
 print "Title: ".$obj->title."\n";
 print 'Id: '.$obj->id."\n";
 print 'Page id: '.$obj->page_id."\n";
 print 'Modified: '.$obj->modified."\n";
 print 'Last revision id: '.$obj->lastrevid."\n";
 print "Labels:\n";
 foreach my $label (sort { $a->language cmp $b->language } @{$obj->labels}) {
         print "\t".encode_utf8($label->value).' ('.$label->language.")\n";
 }
 print "Statements:\n";
 foreach my $statement (@{$obj->statements}) {
         print "\t".$statement->snak->property.' -> ';
         if ($statement->snak->snaktype eq 'value') {
                 print $statement->snak->datavalue->value."\n";
         } elsif ($statement->snak->snaktype eq 'novalue') {
                 print "-\n";
         } elsif ($statement->snak->snaktype eq 'somevalue') {
                 print "?\n";
         }
         if (@{$statement->property_snaks}) {
                 print "\t\tQualifers:\n";
                 foreach my $property_snak (@{$statement->property_snaks}) {
                         print "\t\t\t".$property_snak->property.' -> '.
                                 $property_snak->datavalue->value."\n";
                 }
         }
 }

 # Output:
 # Title: File:Lanzarote 1 Luc Viatour.jpg
 # Id: M16041229
 # Page id: 16041229
 # Modified: 2021-01-24T11:44:10Z
 # Last revision id: 528085091
 # Labels:
 #         Pláž Papagayo, ostrov Lanzarote, Kanárské ostrovy, Španělsko (cs)
 # Statements:
 #         P180 -> Q40080
 #         P170 -> -
 #                 Qualifers:
 #                         P4174 -> Lviatour
 #                         P2699 -> https://commons.wikimedia.org/wiki/user:Lviatour
 #                         P2093 -> Lviatour
 #                         P3831 -> Q33231
 #         P6216 -> Q50423863
 #         P275 -> Q14946043
 #         P6731 -> Q63348049
 #         P571 -> +2011-07-16T00:00:00Z
 #         P7482 -> Q66458942

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

© 2020-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.33

=cut
