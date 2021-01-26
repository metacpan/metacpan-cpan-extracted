package Wikibase::Datatype::Mediainfo;

use strict;
use warnings;

use Error::Pure qw(err);
use Mo qw(build default is);
use Mo::utils qw(check_array_object check_number check_number_of_items);

our $VERSION = 0.07;

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

 # Object.
 my $statement1 = Wikibase::Datatype::MediainfoStatement->new(
         # instance of (P31) human (Q5)
         'snak' => Wikibase::Datatype::MediainfoSnak->new(
                 'datavalue' => Wikibase::Datatype::Value::Item->new(
                         'value' => 'Q5',
                 ),
                 'property' => 'P31',
         ),
         'property_snaks' => [
                 # of (P642) alien (Q474741)
                 Wikibase::Datatype::MediainfoSnak->new(
                         'datavalue' => Wikibase::Datatype::Value::Item->new(
                                 'value' => 'Q474741',
                         ),
                         'property' => 'P642',
                 ),
         ],
 );
 my $statement2 = Wikibase::Datatype::MediainfoStatement->new(
         # sex or gender (P21) male (Q6581097)
         'snak' => Wikibase::Datatype::MediainfoSnak->new(
                 'datavalue' => Wikibase::Datatype::Value::Item->new(
                         'value' => 'Q6581097',
                 ),
                 'property' => 'P21',
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
         print "\tStatement:\n";
         print "\t\t".$statement->snak->property.' -> '.$statement->snak->datavalue->value."\n";
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
 #         Statement:
 #                 P31 -> Q5
 #                 Qualifers:
 #                         P642 -> Q474741
 #         Statement:
 #                 P21 -> Q6581097

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

© Michal Josef Špaček 2020-2021

BSD 2-Clause License

=head1 VERSION

0.07

=cut
