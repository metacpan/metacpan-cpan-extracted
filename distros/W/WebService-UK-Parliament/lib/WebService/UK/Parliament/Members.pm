package WebService::UK::Parliament::Members;

use Mojo::Base 'WebService::UK::Parliament::Base';

has public_url => "https://members-api.parliament.uk/swagger/v1/swagger.json";

has private_url => "swagger/members-api.json";

has base_url => 'https://members-api.parliament.uk/';

1;

__END__

=head1 NAME

WebService::UK::Parliament::Members - Query the UK Parliament Members API

=head1 VERSION

Version 1.00

=cut

=head1 SYNOPSIS

	use WebService::UK::Parliament::Members;

	my $client = WebService::UK::Parliament::Members->new();

	my $data = $client->$endpoint($params);

=cut

=head1 DESCRIPTION

The following documentation is automatically generated using the UK Parliament OpenAPI specification.

An API which retrieves Members data.

=cut

=head1 Sections

=cut

=head2 Location

=cut

=head3 getLocationBrowse

Returns a list of locations, both parent and child

=cut

=head4 Method

get

=cut

=head4 Path

/api/Location/Browse/{locationType}/{locationName}

=cut

=head4 Parameters

=over

=item locationType

Location by type of location

integer

0
1
2
3

=item locationName

Location by name specified

string

=back

=cut

=head3 getLocationConstituencySearch

Returns a list of constituencies

=cut

=head4 Method

get

=cut

=head4 Path

/api/Location/Constituency/Search

=cut

=head4 Parameters

=over

=item searchText

Constituencies containing serach term in their name

string

=item skip

The number of records to skip from the first, default is 0

integer

format: int32

=item take

The number of records to return, default is 20. Maximum is 20

integer

format: int32

=back

=cut

=head3 getLocationConstituency

Returns a constituency by ID

=cut

=head4 Method

get

=cut

=head4 Path

/api/Location/Constituency/{id}

=cut

=head4 Parameters

=over

=item id

Constituency by ID

integer

format: int32

=back

=cut

=head3 getLocationConstituencyElectionResultLatest

Returns latest election result by constituency id

=cut

=head4 Method

get

=cut

=head4 Path

/api/Location/Constituency/{id}/ElectionResult/Latest

=cut

=head4 Parameters

=over

=item id

Latest election result by constituency id

integer

format: int32

=back

=cut

=head3 getLocationConstituencyElectionResult

Returns an election result by constituency and election id

=cut

=head4 Method

get

=cut

=head4 Path

/api/Location/Constituency/{id}/ElectionResult/{electionId}

=cut

=head4 Parameters

=over

=item id

Election result by constituency id

integer

format: int32

=item electionId

Election result by election id

integer

format: int32

=back

=cut

=head3 getLocationConstituencyElectionResults

Returns a list of election results by constituency ID

=cut

=head4 Method

get

=cut

=head4 Path

/api/Location/Constituency/{id}/ElectionResults

=cut

=head4 Parameters

=over

=item id

Elections results by constituency ID

integer

format: int32

=back

=cut

=head3 getLocationConstituencyGeometry

Returns geometry by constituency ID

=cut

=head4 Method

get

=cut

=head4 Path

/api/Location/Constituency/{id}/Geometry

=cut

=head4 Parameters

=over

=item id

Geometry by constituency ID

integer

format: int32

=back

=cut

=head3 getLocationConstituencyRepresentations

Returns a list of representations by constituency ID

=cut

=head4 Method

get

=cut

=head4 Path

/api/Location/Constituency/{id}/Representations

=cut

=head4 Parameters

=over

=item id

Representations by constituency ID

integer

format: int32

=back

=cut

=head3 getLocationConstituencySynopsis

Returns a synopsis by constituency ID

=cut

=head4 Method

get

=cut

=head4 Path

/api/Location/Constituency/{id}/Synopsis

=cut

=head4 Parameters

=over

=item id

Synopsis by constituency ID

integer

format: int32

=back

=cut

=head2 LordsInterests

=cut

=head3 getLordsInterestsRegister

Returns a list of registered interests

=cut

=head4 Method

get

=cut

=head4 Path

/api/LordsInterests/Register

=cut

=head4 Parameters

=over

=item searchTerm

Registered interests containing search term

string

=item page

Page of results to return, default 0. Results per page 20.

integer

format: int32

=item includeDeleted

Registered interests that have been deleted

boolean

=back

=cut

=head3 getLordsInterestsStaff

Returns a list of staff

=cut

=head4 Method

get

=cut

=head4 Path

/api/LordsInterests/Staff

=cut

=head4 Parameters

=over

=item searchTerm

Staff containing search term

string

=item page

Page of results to return, default 0. Results per page 20.

integer

format: int32

=back

=cut

=head2 Members

=cut

=head3 getMembersHistory

Return members by ID with list of their historical names, parties and memberships

=cut

=head4 Method

get

=cut

=head4 Path

/api/Members/History

=cut

=head4 Parameters

=over

=item ids

List of MemberIds to find

array

{"type":"integer","format":"int32"}

=back

=cut

=head3 getMembersSearch

Returns a list of current members of the Commons or Lords

=cut

=head4 Method

get

=cut

=head4 Path

/api/Members/Search

=cut

=head4 Parameters

=over

=item Name

Members where name contains term specified

string

=item Location

Members where postcode or geographical location matches the term specified

string

=item PostTitle

Members which have held the post specified

string

=item PartyId

Members which are currently affiliated with party with party ID

integer

format: int32

=item House

Members where their most recent house is the house specified

integer

1
2

=item ConstituencyId

Members which currently hold the constituency with constituency id

integer

format: int32

=item NameStartsWith

Members with surname begining with letter(s) specified

string

=item Gender

Members with the gender specified

string

=item MembershipStartedSince

Members who started on or after the date given

string

format: date-time

=item MembershipEnded.MembershipEndedSince

Members who left the House on or after the date given

string

format: date-time

=item MembershipEnded.MembershipEndReasonIds

array

{"format":"int32","type":"integer"}

=item MembershipInDateRange.WasMemberOnOrAfter

Members who were active on or after the date specified

string

format: date-time

=item MembershipInDateRange.WasMemberOnOrBefore

Members who were active on or before the date specified

string

format: date-time

=item MembershipInDateRange.WasMemberOfHouse

Members who were active in the house specifid

integer

1
2

=item IsEligible

Members currently Eligible to sit in their House

boolean

=item IsCurrentMember

Members who are current or former members

boolean

=item PolicyInterestId

Members with specified policy interest

integer

format: int32

=item Experience

Members with specified experience

string

=item skip

The number of records to skip from the first, default is 0

integer

format: int32

=item take

The number of records to return, default is 20. Maximum is 20

integer

format: int32

=back

=cut

=head3 getMembersSearchHistorical

Returns a list of members of the Commons or Lords

=cut

=head4 Method

get

=cut

=head4 Path

/api/Members/SearchHistorical

=cut

=head4 Parameters

=over

=item name

Members with names containing the term specified

string

=item dateToSearchFor

Members that were an active member of the Commons or Lords on the date specified

string

format: date-time

=item skip

The number of records to skip from the first, default is 0

integer

format: int32

=item take

The number of records to return, default is 20. Maximum is 20

integer

format: int32

=back

=cut

=head3 getMembers

Return member by ID

=cut

=head4 Method

get

=cut

=head4 Path

/api/Members/{id}

=cut

=head4 Parameters

=over

=item id

Member by ID specified

integer

format: int32

=item detailsForDate

Member object will be populated with details from the date specified

string

format: date-time

=back

=cut

=head3 getMembersBiography

Return biography of member by ID

=cut

=head4 Method

get

=cut

=head4 Path

/api/Members/{id}/Biography

=cut

=head4 Parameters

=over

=item id

Biography of Member by ID specified

integer

format: int32

=back

=cut

=head3 getMembersContact

Return list of contact details of member by ID

=cut

=head4 Method

get

=cut

=head4 Path

/api/Members/{id}/Contact

=cut

=head4 Parameters

=over

=item id

Contact details of Member by ID specified

integer

format: int32

=back

=cut

=head3 getMembersContributionSummary

Return contribution summary of member by ID

=cut

=head4 Method

get

=cut

=head4 Path

/api/Members/{id}/ContributionSummary

=cut

=head4 Parameters

=over

=item id

Contribution summary of Member by ID specified

integer

format: int32

=item page

integer

format: int32

=back

=cut

=head3 getMembersEdms

Return list of early day motions of member by ID

=cut

=head4 Method

get

=cut

=head4 Path

/api/Members/{id}/Edms

=cut

=head4 Parameters

=over

=item id

Early day motions of Member by ID specified

integer

format: int32

=item page

integer

format: int32

=back

=cut

=head3 getMembersExperience

Return experience of member by ID

=cut

=head4 Method

get

=cut

=head4 Path

/api/Members/{id}/Experience

=cut

=head4 Parameters

=over

=item id

Experience of Member by ID specified

integer

format: int32

=back

=cut

=head3 getMembersFocus

Return list of areas of focus of member by ID

=cut

=head4 Method

get

=cut

=head4 Path

/api/Members/{id}/Focus

=cut

=head4 Parameters

=over

=item id

Areas of focus of Member by ID specified

integer

format: int32

=back

=cut

=head3 getMembersLatestElectionResult

Return latest election result of member by ID

=cut

=head4 Method

get

=cut

=head4 Path

/api/Members/{id}/LatestElectionResult

=cut

=head4 Parameters

=over

=item id

Latest election result of Member by ID specified

integer

format: int32

=back

=cut

=head3 getMembersPortrait

Return portrait of member by ID

=cut

=head4 Method

get

=cut

=head4 Path

/api/Members/{id}/Portrait

=cut

=head4 Parameters

=over

=item id

Portrait of Member by ID specified

integer

format: int32

=item cropType

integer

0
1
2
3

=item webVersion

boolean

=back

=cut

=head3 getMembersPortraitUrl

Return portrait url of member by ID

=cut

=head4 Method

get

=cut

=head4 Path

/api/Members/{id}/PortraitUrl

=cut

=head4 Parameters

=over

=item id

Portrait url of Member by ID specified

integer

format: int32

=back

=cut

=head3 getMembersRegisteredInterests

Return list of registered interests of member by ID

=cut

=head4 Method

get

=cut

=head4 Path

/api/Members/{id}/RegisteredInterests

=cut

=head4 Parameters

=over

=item id

Registered interests of Member by ID specified

integer

format: int32

=back

=cut

=head3 getMembersStaff

Return list of staff of member by ID

=cut

=head4 Method

get

=cut

=head4 Path

/api/Members/{id}/Staff

=cut

=head4 Parameters

=over

=item id

Staff of Member by ID specified

integer

format: int32

=back

=cut

=head3 getMembersSynopsis

Return synopsis of member by ID

=cut

=head4 Method

get

=cut

=head4 Path

/api/Members/{id}/Synopsis

=cut

=head4 Parameters

=over

=item id

Synopsis of Member by ID specified

integer

format: int32

=back

=cut

=head3 getMembersThumbnail

Return thumbnail of member by ID

=cut

=head4 Method

get

=cut

=head4 Path

/api/Members/{id}/Thumbnail

=cut

=head4 Parameters

=over

=item id

Thumbnail of Member by ID specified

integer

format: int32

=back

=cut

=head3 getMembersThumbnailUrl

Return thumbnail url of member by ID

=cut

=head4 Method

get

=cut

=head4 Path

/api/Members/{id}/ThumbnailUrl

=cut

=head4 Parameters

=over

=item id

Thumbnail url of Member by ID specified

integer

format: int32

=back

=cut

=head3 getMembersVoting

Return list of votes by member by ID

=cut

=head4 Method

get

=cut

=head4 Path

/api/Members/{id}/Voting

=cut

=head4 Parameters

=over

=item id

Votes by Member by ID specified

integer

format: int32

=item house

integer

1
2

=item page

integer

format: int32

=back

=cut

=head3 getMembersWrittenQuestions

Return list of written questions by member by ID

=cut

=head4 Method

get

=cut

=head4 Path

/api/Members/{id}/WrittenQuestions

=cut

=head4 Parameters

=over

=item id

Written questions by Member by ID specified

integer

format: int32

=item page

integer

format: int32

=back

=cut

=head2 Parties

=cut

=head3 getPartiesGetActive

Returns a list of current parties with at least one active member.

=cut

=head4 Method

get

=cut

=head4 Path

/api/Parties/GetActive/{house}

=cut

=head4 Parameters

=over

=item house

Current parties by house

integer

1
2

=back

=cut

=head3 getPartiesLordsByType

Returns the composition of the House of Lords by peerage type.

=cut

=head4 Method

get

=cut

=head4 Path

/api/Parties/LordsByType/{forDate}

=cut

=head4 Parameters

=over

=item forDate

Composition of the Lords for date specified.

string

format: date-time

=back

=cut

=head3 getPartiesStateOfTheParties

Returns current state of parties

=cut

=head4 Method

get

=cut

=head4 Path

/api/Parties/StateOfTheParties/{house}/{forDate}

=cut

=head4 Parameters

=over

=item house

State of parties in Commons or Lords.

integer

1
2

=item forDate

State of parties for the date specified

string

format: date-time

=back

=cut

=head2 Posts

=cut

=head3 getPostsDepartments

Returns a list of departments.

=cut

=head4 Method

get

=cut

=head4 Path

/api/Posts/Departments/{type}

=cut

=head4 Parameters

=over

=item type

Departments by type

integer

0
1
2

=back

=cut

=head3 getPostsGovernmentPosts

Returns a list of government posts.

=cut

=head4 Method

get

=cut

=head4 Path

/api/Posts/GovernmentPosts

=cut

=head4 Parameters

=over

=item departmentId

Government posts by department ID

integer

format: int32

=back

=cut

=head3 getPostsOppositionPosts

Returns a list of opposition posts.

=cut

=head4 Method

get

=cut

=head4 Path

/api/Posts/OppositionPosts

=cut

=head4 Parameters

=over

=item departmentId

Opposition posts by department ID

integer

format: int32

=back

=cut

=head3 getPostsSpeakerAndDeputies

Returns a list containing the speaker and deputy speakers.

=cut

=head4 Method

get

=cut

=head4 Path

/api/Posts/SpeakerAndDeputies/{forDate}

=cut

=head4 Parameters

=over

=item forDate

Speaker and deputy speakers for date specified

string

format: date-time

=back

=cut

=head3 getPostsSpokespersons

Returns a list of spokespersons.

=cut

=head4 Method

get

=cut

=head4 Path

/api/Posts/Spokespersons

=cut

=head4 Parameters

=over

=item partyId

Spokespersons by party ID

integer

format: int32

=back

=cut

=head2 Reference

=cut

=head3 getReferenceAnsweringBodies

Returns a list of answering bodies.

=cut

=head4 Method

get

=cut

=head4 Path

/api/Reference/AnsweringBodies

=cut

=head4 Parameters

=over

=item id

integer

format: int32

=item nameContains

string

=back

=cut

=head3 getReferenceDepartments

Returns a list of departments.

=cut

=head4 Method

get

=cut

=head4 Path

/api/Reference/Departments

=cut

=head4 Parameters

=over

=item id

integer

format: int32

=item nameContains

string

=back

=cut

=head3 getReferenceDepartmentsLogo

Returns department logo.

=cut

=head4 Method

get

=cut

=head4 Path

/api/Reference/Departments/{id}/Logo

=cut

=head4 Parameters

=over

=item id

Logo by department ID

integer

format: int32

=back

=cut

=head3 getReferencePolicyInterests

Returns a list of policy interest.

=cut

=head4 Method

get

=cut

=head4 Path

/api/Reference/PolicyInterests

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
