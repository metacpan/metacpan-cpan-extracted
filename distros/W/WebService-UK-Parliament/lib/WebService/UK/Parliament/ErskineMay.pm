package WebService::UK::Parliament::ErskineMay;

use Mojo::Base 'WebService::UK::Parliament::Base';

has public_url => "https://erskinemay-api.parliament.uk/swagger/v1/swagger.json";

has private_url => "swagger/erskinemay-api.json";

has base_url => 'https://erskinemay-api.parliament.uk/';

1;

__END__

=head1 NAME

WebService::UK::Parliament::ErskineMay - Query the UK Parliament Erskine Ma API

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS

	use WebService::UK::Parliament::ErskineMay;

	my $client = WebService::UK::Parliament::ErskineMay->new();

	my $data = $client->$endpoint($params);

=cut

=head1 DESCRIPTION

The following documentation is automatically generated using the UK Parliament OpenAPI specification.

An API that allows querying of Erskine May data.

=cut

=head1 Sections

=cut

=head2 Chapter

=cut

=head3 getChapter

Returns a single chapter overview by chapter number.

=cut

=head4 Method

get

=cut

=head4 Path

/api/Chapter/{chapterNumber}

=cut

=head4 Parameters

=over

=item chapterNumber

Chapter overview with the chapter number specified

integer

format: int32

=back

=cut

=head2 IndexTerm

=cut

=head3 getIndexTermbrowse

Returns a list of index terms by start letter.

=cut

=head4 Method

get

=cut

=head4 Path

/api/IndexTerm/browse

=cut

=head4 Parameters

=over

=item startLetter

Index terms by start letter

string

=item skip

The number of records to skip from the first, default is 0.

integer

format: int32

=item take

The number of records to return, default is 20, maximum is 20.

integer

format: int32

=back

=cut

=head3 getIndexTerm

Returns an index term by id.

=cut

=head4 Method

get

=cut

=head4 Path

/api/IndexTerm/{indexTermId}

=cut

=head4 Parameters

=over

=item indexTermId

Index term by if

integer

format: int32

=back

=cut

=head2 Part

=cut

=head3 getPart1

Returns a list of all parts.

=cut

=head4 Method

get

=cut

=head4 Path

/api/Part

=cut

=head3 getPart

Returns a part by part number.

=cut

=head4 Method

get

=cut

=head4 Path

/api/Part/{partNumber}

=cut

=head4 Parameters

=over

=item partNumber

Part by part number

integer

format: int32

=back

=cut

=head2 Search

=cut

=head3 getSearchIndexTermSearchResults

Returns a list of index terms which contain the search term.

=cut

=head4 Method

get

=cut

=head4 Path

/api/Search/IndexTermSearchResults/{searchTerm}

=cut

=head4 Parameters

=over

=item searchTerm

Index terms which contain search term.

string

=item skip

The number of records to skip from the first, default is 0.

integer

format: int32

=item take

The number of records to return, default is 20, maximum is 20.

integer

format: int32

=back

=cut

=head3 getSearchParagraph

Returns a section overview by reference.

=cut

=head4 Method

get

=cut

=head4 Path

/api/Search/Paragraph/{reference}

=cut

=head4 Parameters

=over

=item reference

Section overview by reference.

string

=back

=cut

=head3 getSearchParagraphSearchResults

Returns a list of paragraphs which contain the search term.

=cut

=head4 Method

get

=cut

=head4 Path

/api/Search/ParagraphSearchResults/{searchTerm}

=cut

=head4 Parameters

=over

=item searchTerm

Paragraphs which contain search term in their content.

string

=item skip

The number of records to skip from the first, default is 0.

integer

format: int32

=item take

The number of records to return, default is 20, maximum is 20.

integer

format: int32

=back

=cut

=head3 getSearchSectionSearchResults

Returns a list of sections which contain the search term.

=cut

=head4 Method

get

=cut

=head4 Path

/api/Search/SectionSearchResults/{searchTerm}

=cut

=head4 Parameters

=over

=item searchTerm

Sections which contain search term in their title.

string

=item skip

The number of records to skip from the first, default is 0.

integer

format: int32

=item take

The number of records to return, default is 20, maximum is 20.

integer

format: int32

=back

=cut

=head2 Section

=cut

=head3 getSection

Returns a section by section id.

=cut

=head4 Method

get

=cut

=head4 Path

/api/Section/{sectionId}

=cut

=head4 Parameters

=over

=item sectionId

Section by id.

integer

format: int32

=back

=cut

=head3 getSection,

Returns a section overview by section id and step.

=cut

=head4 Method

get

=cut

=head4 Path

/api/Section/{sectionId},{step}

=cut

=head4 Parameters

=over

=item sectionId

Section by id.

integer

format: int32

=item step

Number of sections to step over from given section.

integer

format: int32

=back

=cut

=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-uk-parliament at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-UK-Parliament>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::UK::Parliament


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-UK-Parliament>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/WebService-UK-Parliament>

=item * Search CPAN

L<https://metacpan.org/release/WebService-UK-Parliament>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

The first ticehurst bathroom experience

This software is Copyright (c) 2022 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
