package Test::Shared::Fixture::Wikibase::Datatype::Mediainfo::Commons::ImageOfHuman;

use base qw(Wikibase::Datatype::Mediainfo);
use strict;
use warnings;

use Test::Shared::Fixture::Wikibase::Datatype::MediainfoStatement::Commons::Depicts::Human;
use Wikibase::Datatype::Value::Monolingual;

our $VERSION = 0.24;

sub new {
	my $class = shift;

	my @params = (
		'descriptions' => [
		],
		'id' => 'M10031710',
		'labels' => [
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => 'Portrait of Douglas Adams',
			),
		],
		'lastrevid' => 617544224,
		'modified' => '2021-12-30T08:38:29Z',
		'ns' => 6,
		'pageid' => 10031710,
		'statements' => [
			Test::Shared::Fixture::Wikibase::Datatype::MediainfoStatement::Commons::Depicts::Human->new,
		],
		'title' => 'File:Douglas adams portrait cropped.jpg',
	);

	my $self = $class->SUPER::new(@params);

	return $self;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Test::Shared::Fixture::Wikibase::Datatype::Mediainfo::Commons::ImageOfHuman - Test instance for Wikidata mediainfo.

=head1 SYNOPSIS

 use Test::Shared::Fixture::Wikibase::Datatype::Mediainfo::Commons::ImageOfHuman;

 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Mediainfo::Commons::ImageOfHuman->new;
 my $descriptions_ar = $obj->descriptions;
 my $id = $obj->id;
 my $labels_ar = $obj->labels;
 my $lastrevid = $obj->lastrevid;
 my $modified = $obj->modified;
 my $ns = $obj->ns;
 my $page_id = $obj->page_id;
 my $statements_ar = $obj->statements;
 my $title = $obj->title;

=head1 METHODS

=head2 C<new>

 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Mediainfo::Commons::ImageOfHuman->new;

Constructor.

Returns instance of object.

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

=head1 EXAMPLE

=for comment filename=fixture_create_and_print_mediainfo_commons_imageofhuman.pl

 use strict;
 use warnings;

 use Test::Shared::Fixture::Wikibase::Datatype::Mediainfo::Commons::ImageOfHuman;
 use Unicode::UTF8 qw(encode_utf8);
 use Wikibase::Datatype::Print::Mediainfo;

 # Object.
 my $obj = Test::Shared::Fixture::Wikibase::Datatype::Mediainfo::Commons::ImageOfHuman->new;

 # Print out.
 print encode_utf8(scalar Wikibase::Datatype::Print::Mediainfo::print($obj))."\n";

 # Output:
 # Id: M10031710
 # Title: File:Douglas adams portrait cropped.jpg
 # NS: 6
 # Last revision id: 617544224
 # Date of modification: 2021-12-30T08:38:29Z
 # Label: Portrait of Douglas Adams (en)
 # Statements:
 #   P180: Q42 (normal)

=head1 DEPENDENCIES

L<Test::Shared::Fixture::Wikibase::Datatype::MediainfoStatement::Commons::Depicts::Human>,
L<Wikibase::Datatype::Mediainfo>,
L<Wikibase::Datatype::Value::Monolingual>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype>

Wikibase datatypes.

=item L<Wikibase::Datatype::Mediainfo>

Wikibase mediainfo datatype.

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

0.24

=cut
