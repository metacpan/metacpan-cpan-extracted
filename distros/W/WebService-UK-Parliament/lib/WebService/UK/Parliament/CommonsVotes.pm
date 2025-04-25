package WebService::UK::Parliament::CommonsVotes;

use Mojo::Base 'WebService::UK::Parliament::Base';

has public_url => "https://commonsvotes-api.parliament.uk/swagger/docs/v1";

has private_url => "swagger/commonsvotes-api.json";

has base_url => 'https://commonsvotes-api.parliament.uk';

1;

__END__

=head1 NAME

WebService::UK::Parliament::CommonsVotes - Query the UK Parliament Commons Vo API

=head1 VERSION

Version 1.01

=cut

=head1 SYNOPSIS

	use WebService::UK::Parliament::CommonsVotes;

	my $client = WebService::UK::Parliament::CommonsVotes->new();

	my $data = $client->$endpoint($params);

=cut

=head1 DESCRIPTION

The following documentation is automatically generated using the UK Parliament OpenAPI specification.

An API that allows querying of Commons Votes data.

=cut

=head1 Sections

=cut

=head2 Divisions

=cut

=head3 getdatadivision.

Return a Division

=cut

=head4 Method

get

=cut

=head4 Path

/data/division/{divisionId}.{format}

=cut

=head4 Parameters

=over

=item divisionId

Id number of a Division whose records are to be returned

integer

format: int32

=item format

xml or json

string

=back

=cut

=head3 getdatadivisions.groupedbyparty

Return Divisions results grouped by party

=cut

=head4 Method

get

=cut

=head4 Path

/data/divisions.{format}/groupedbyparty

=cut

=head4 Parameters

=over

=item format

xml or json

string

=item queryParameters.searchTerm

Divisions containing search term within title or number

string

=item queryParameters.memberId

Divisions returning Member with Member ID voting records

integer

format: int32

=item queryParameters.includeWhenMemberWasTeller

Divisions where member was a teller as well as if they actually voted

boolean

=item queryParameters.startDate

Divisions where division date in one or after date provided. Date format is yyyy-MM-dd

string

format: date-time

=item queryParameters.endDate

Divisions where division date in one or before date provided. Date format is yyyy-MM-dd

string

format: date-time

=item queryParameters.divisionNumber

Division Number - as specified by the House, unique within a session. This is different to the division id which uniquely identifies a division in this system and is passed to the GET division endpoint

integer

format: int32

=back

=cut

=head3 getdatadivisions.membervoting

Return voting records for a Member

=cut

=head4 Method

get

=cut

=head4 Path

/data/divisions.{format}/membervoting

=cut

=head4 Parameters

=over

=item format

xml or json

string

=item queryParameters.memberId

Id number of a Member whose voting records are to be returned

integer

format: int32

=item queryParameters.skip

The number of records to skip. Default is 0

integer

format: int32

=item queryParameters.take

The number of records to return per page. Default is 25

integer

format: int32

=item queryParameters.searchTerm

Divisions containing search term within title or number

string

=item queryParameters.includeWhenMemberWasTeller

Divisions where member was a teller as well as if they actually voted

boolean

=item queryParameters.startDate

Divisions where division date in one or after date provided. Date format is yyyy-MM-dd

string

format: date-time

=item queryParameters.endDate

Divisions where division date in one or before date provided. Date format is yyyy-MM-dd

string

format: date-time

=item queryParameters.divisionNumber

Division Number - as specified by the House, unique within a session. This is different to the division id which uniquely identifies a division in this system and is passed to the GET division endpoint

integer

format: int32

=back

=cut

=head3 getdatadivisions.search

Return a list of Divisions

=cut

=head4 Method

get

=cut

=head4 Path

/data/divisions.{format}/search

=cut

=head4 Parameters

=over

=item format

json or xml

string

=item queryParameters.skip

The number of records to skip. Default is 0

integer

format: int32

=item queryParameters.take

The number of records to return per page. Default is 25

integer

format: int32

=item queryParameters.searchTerm

Divisions containing search term within title or number

string

=item queryParameters.memberId

Divisions returning Member with Member ID voting records

integer

format: int32

=item queryParameters.includeWhenMemberWasTeller

Divisions where member was a teller as well as if they actually voted

boolean

=item queryParameters.startDate

Divisions where division date in one or after date provided. Date format is yyyy-MM-dd

string

format: date-time

=item queryParameters.endDate

Divisions where division date in one or before date provided. Date format is yyyy-MM-dd

string

format: date-time

=item queryParameters.divisionNumber

Division Number - as specified by the House, unique within a session. This is different to the division id which uniquely identifies a division in this system and is passed to the GET division endpoint

integer

format: int32

=back

=cut

=head3 getdatadivisions.searchTotalResults

Return total results count

=cut

=head4 Method

get

=cut

=head4 Path

/data/divisions.{format}/searchTotalResults

=cut

=head4 Parameters

=over

=item format

json or xml

string

=item queryParameters.searchTerm

Divisions containing search term within title or number

string

=item queryParameters.memberId

Divisions returning Member with Member ID voting records

integer

format: int32

=item queryParameters.includeWhenMemberWasTeller

Divisions where member was a teller as well as if they actually voted

boolean

=item queryParameters.startDate

Divisions where division date in one or after date provided. Date format is yyyy-MM-dd

string

format: date-time

=item queryParameters.endDate

Divisions where division date in one or before date provided. Date format is yyyy-MM-dd

string

format: date-time

=item queryParameters.divisionNumber

Division Number - as specified by the House, unique within a session. This is different to the division id which uniquely identifies a division in this system and is passed to the GET division endpoint

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

=item * Search CPAN

L<https://metacpan.org/release/WebService-UK-Parliament>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

The first ticehurst bathroom experience

This software is Copyright (c) 2022->2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
