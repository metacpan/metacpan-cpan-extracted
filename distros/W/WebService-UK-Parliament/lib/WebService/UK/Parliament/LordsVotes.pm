package WebService::UK::Parliament::LordsVotes;

use Mojo::Base 'WebService::UK::Parliament::Base';

has public_url => "https://lordsvotes-api.parliament.uk/swagger/v1/swagger.json";

has private_url => "swagger/lordsvotes-api.json";

has base_url => 'https://lordsvotes-api.parliament.uk/';

1;

__END__

=head1 NAME

WebService::UK::Parliament::LordsVotes - Query the UK Parliament Lords Vo API

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS

	use WebService::UK::Parliament::LordsVotes;

	my $client = WebService::UK::Parliament::LordsVotes->new();

	my $data = $client->$endpoint($params);

=cut

=head1 DESCRIPTION

The following documentation is automatically generated using the UK Parliament OpenAPI specification.

An API that allows querying of Lords Votes data.

=cut

=head1 Sections

=cut

=head2 Divisions

=cut

=head3 getdataDivisionsgroupedbyparty

Return Divisions results grouped by party

=cut

=head4 Method

get

=cut

=head4 Path

/data/Divisions/groupedbyparty

=cut

=head4 Parameters

=over

=item SearchTerm

Divisions containing search term within title or number

string

=item MemberId

Divisions returning Member with Member ID voting records

integer

format: int32

=item IncludeWhenMemberWasTeller

Divisions where member was a teller as well as if they actually voted

boolean

=item StartDate

Divisions where division date in one or after date provided. Date format is yyyy-MM-dd

string

format: date-time

=item EndDate

Divisions where division date in one or before date provided. Date format is yyyy-MM-dd

string

format: date-time

=item DivisionNumber

Division Number - as specified by the House, unique within a session. This is different to the division id which uniquely identifies a division in this system and is passed to the GET division endpoint

integer

format: int32

=item TotalVotesCast.Comparator

comparison operator to use

string

LessThan
LessThanOrEqualTo
EqualTo
GreaterThanOrEqualTo
GreaterThan

=item TotalVotesCast.ValueToCompare

value to compare to with the operator provided

integer

format: int32

=item Majority.Comparator

comparison operator to use

string

LessThan
LessThanOrEqualTo
EqualTo
GreaterThanOrEqualTo
GreaterThan

=item Majority.ValueToCompare

value to compare to with the operator provided

integer

format: int32

=back

=cut

=head3 getdataDivisionsmembervoting

Return voting records for a Member

=cut

=head4 Method

get

=cut

=head4 Path

/data/Divisions/membervoting

=cut

=head4 Parameters

=over

=item MemberId

Id number of a Member whose voting records are to be returned

integer

format: int32

=item SearchTerm

Divisions containing search term within title or number

string

=item IncludeWhenMemberWasTeller

Divisions where member was a teller as well as if they actually voted

boolean

=item StartDate

Divisions where division date in one or after date provided. Date format is yyyy-MM-dd

string

format: date-time

=item EndDate

Divisions where division date in one or before date provided. Date format is yyyy-MM-dd

string

format: date-time

=item DivisionNumber

Division Number - as specified by the House, unique within a session. This is different to the division id which uniquely identifies a division in this system and is passed to the GET division endpoint

integer

format: int32

=item TotalVotesCast.Comparator

comparison operator to use

string

LessThan
LessThanOrEqualTo
EqualTo
GreaterThanOrEqualTo
GreaterThan

=item TotalVotesCast.ValueToCompare

value to compare to with the operator provided

integer

format: int32

=item Majority.Comparator

comparison operator to use

string

LessThan
LessThanOrEqualTo
EqualTo
GreaterThanOrEqualTo
GreaterThan

=item Majority.ValueToCompare

value to compare to with the operator provided

integer

format: int32

=item skip

The number of records to skip. Must be a positive integer. Default is 0

integer

format: int32

=item take

The number of records to return per page. Must be more than 0. Default is 25

integer

format: int32

=back

=cut

=head3 getdataDivisionssearch

Return a list of Divisions

=cut

=head4 Method

get

=cut

=head4 Path

/data/Divisions/search

=cut

=head4 Parameters

=over

=item SearchTerm

Divisions containing search term within title or number

string

=item MemberId

Divisions returning Member with Member ID voting records

integer

format: int32

=item IncludeWhenMemberWasTeller

Divisions where member was a teller as well as if they actually voted

boolean

=item StartDate

Divisions where division date in one or after date provided. Date format is yyyy-MM-dd

string

format: date-time

=item EndDate

Divisions where division date in one or before date provided. Date format is yyyy-MM-dd

string

format: date-time

=item DivisionNumber

Division Number - as specified by the House, unique within a session. This is different to the division id which uniquely identifies a division in this system and is passed to the GET division endpoint

integer

format: int32

=item TotalVotesCast.Comparator

comparison operator to use

string

LessThan
LessThanOrEqualTo
EqualTo
GreaterThanOrEqualTo
GreaterThan

=item TotalVotesCast.ValueToCompare

value to compare to with the operator provided

integer

format: int32

=item Majority.Comparator

comparison operator to use

string

LessThan
LessThanOrEqualTo
EqualTo
GreaterThanOrEqualTo
GreaterThan

=item Majority.ValueToCompare

value to compare to with the operator provided

integer

format: int32

=item skip

The number of records to skip. Must be a positive integer. Default is 0

integer

format: int32

=item take

The number of records to return per page. Must be more than 0. Default is 25

integer

format: int32

=back

=cut

=head3 getdataDivisionssearchTotalResults

Return total results count

=cut

=head4 Method

get

=cut

=head4 Path

/data/Divisions/searchTotalResults

=cut

=head4 Parameters

=over

=item SearchTerm

Divisions containing search term within title or number

string

=item MemberId

Divisions returning Member with Member ID voting records

integer

format: int32

=item IncludeWhenMemberWasTeller

Divisions where member was a teller as well as if they actually voted

boolean

=item StartDate

Divisions where division date in one or after date provided. Date format is yyyy-MM-dd

string

format: date-time

=item EndDate

Divisions where division date in one or before date provided. Date format is yyyy-MM-dd

string

format: date-time

=item DivisionNumber

Division Number - as specified by the House, unique within a session. This is different to the division id which uniquely identifies a division in this system and is passed to the GET division endpoint

integer

format: int32

=item TotalVotesCast.Comparator

comparison operator to use

string

LessThan
LessThanOrEqualTo
EqualTo
GreaterThanOrEqualTo
GreaterThan

=item TotalVotesCast.ValueToCompare

value to compare to with the operator provided

integer

format: int32

=item Majority.Comparator

comparison operator to use

string

LessThan
LessThanOrEqualTo
EqualTo
GreaterThanOrEqualTo
GreaterThan

=item Majority.ValueToCompare

value to compare to with the operator provided

integer

format: int32

=back

=cut

=head3 getdataDivisions

Return a Division

=cut

=head4 Method

get

=cut

=head4 Path

/data/Divisions/{divisionId}

=cut

=head4 Parameters

=over

=item divisionId

Division with ID specified

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
