package WebService::UK::Parliament::OralQuestions;

use Mojo::Base 'WebService::UK::Parliament::Base';

has public_url => "https://oralquestionsandmotions-api.parliament.uk/swagger/docs/v1";

has private_url => "swagger/oralquestions-api.json";

has base_url => 'https://oralquestionsandmotions-api.parliament.uk/';

1;

__END__

=head1 NAME

WebService::UK::Parliament::OralQuestions - Query the UK Parliament Oral Qu API

=head1 VERSION

Version 0.03

=cut

=head1 SYNOPSIS

	use WebService::UK::Parliament::OralQuestions;

	my $client = WebService::UK::Parliament::OralQuestions->new();

	my $data = $client->$endpoint($params);

=cut

=head1 DESCRIPTION

The following documentation is automatically generated using the UK Parliament OpenAPI specification.

An API that allows querying all tabled oral and written questions, and motions for the House of Commons.

=cut

=head1 Sections

=cut

=head2 Early Day Motions

=cut

=head3 getEarlyDayMotion

Returns a single Early Day Motion by ID

=cut

=head4 Method

get

=cut

=head4 Path

/EarlyDayMotion/{id}

=cut

=head4 Parameters

=over

=item id

Early Day Motion with the ID specified.

integer

format: int32

=back

=cut

=head3 getEarlyDayMotionslist

Returns a list of Early Day Motions

=cut

=head4 Method

get

=cut

=head4 Path

/EarlyDayMotions/list

=cut

=head4 Parameters

=over

=item parameters.edmIds

Early Day Motions with an ID in the list provided.

array

{"format":"int32","type":"integer"}

=item parameters.uINWithAmendmentSuffix

Early Day Motions with an UINWithAmendmentSuffix provided.

string

=item parameters.searchTerm

Early Day Motions where the title includes the search term provided.

string

=item parameters.currentStatusDateStart

Early Day Motions where the current status has been set on or after the date provided. Date format YYYY-MM-DD.

string

format: date-time

=item parameters.currentStatusDateEnd

Early Day Motions where the current status has been set on or before the date provided. Date format YYYY-MM-DD.

string

format: date-time

=item parameters.isPrayer

Early Day Motions which are a prayer against a Negative Statutory Instrument.

boolean

=item parameters.memberId

Return Early Day Motions tabled by Member with ID provided.

integer

format: int32

=item parameters.includeSponsoredByMember

Include Early Day Motions sponsored by Member specified

boolean

=item parameters.tabledStartDate

Early Day Motions where the date tabled is on or after the date provided. Date format YYYY-MM-DD.

string

format: date-time

=item parameters.tabledEndDate

Early Day Motions where the date tabled is on or before the date provided. Date format YYYY-MM-DD.

string

format: date-time

=item parameters.statuses

Early Day Motions where current status is in the selected list.

array

{"enum":["Published","Withdrawn"],"type":"string"}

=item parameters.orderBy

Order results by date tabled, title or signature count. Default is date tabled.

string

DateTabledAsc
DateTabledDesc
TitleAsc
TitleDesc
SignatureCountAsc
SignatureCountDesc

=item parameters.skip

The number of records to skip from the first, default is 0.

integer

format: int32

=item parameters.take

The number of records to return, default is 25, maximum is 100.

integer

format: int32

=back

=cut

=head2 Oral Question Times

=cut

=head3 getoralquestiontimeslist

Returns a list of oral question times

=cut

=head4 Method

get

=cut

=head4 Path

/oralquestiontimes/list

=cut

=head4 Parameters

=over

=item parameters.answeringDateStart

Oral Questions Time where the answering date has been set on or after the date provided. Date format YYYY-MM-DD.

string

format: date-time

=item parameters.answeringDateEnd

Oral Questions Time where the answering date has been set on or before the date provided. Date format YYYY-MM-DD.

string

format: date-time

=item parameters.deadlineDateStart

Oral Questions Time where the deadline date has been set on or after the date provided. Date format YYYY-MM-DD.

string

format: date-time

=item parameters.deadlineDateEnd

Oral Questions Time where the deadline date has been set on or before the date provided. Date format YYYY-MM-DD.

string

format: date-time

=item parameters.oralQuestionTimeId

Identifier of the OQT

integer

format: int32

=item parameters.answeringBodyIds

Which answering body is to respond. A list of answering bodies can be found <a target="_blank" href="http://data.parliament.uk/membersdataplatform/services/mnis/referencedata/AnsweringBodies/">here</a>.

array

{"type":"integer","format":"int32"}

=item parameters.skip

The number of records to skip from the first, default is 0.

integer

format: int32

=item parameters.take

The number of records to return, default is 25, maximum is 100.

integer

format: int32

=back

=cut

=head2 Oral Questions

=cut

=head3 getoralquestionslist

Returns a list of oral questions

=cut

=head4 Method

get

=cut

=head4 Path

/oralquestions/list

=cut

=head4 Parameters

=over

=item parameters.answeringDateStart

Oral Questions where the answering date has been set on or after the date provided. Date format YYYY-MM-DD.

string

format: date-time

=item parameters.answeringDateEnd

Oral Questions where the answering date has been set on or before the date provided. Date format YYYY-MM-DD.

string

format: date-time

=item parameters.questionType

Oral Questions where the question type is the selected type, substantive or topical.

string

Substantive
Topical

=item parameters.oralQuestionTimeId

Oral Questions where the question is within the question time with the ID provided

integer

format: int32

=item parameters.askingMemberIds

The ID of the member asking the question. Lists of member IDs for each house are available <a href="http://data.parliament.uk/membersdataplatform/services/mnis/members/query/house=Commons" target="_blank">Commons</a> and <a href="http://data.parliament.uk/membersdataplatform/services/mnis/members/query/house=Lords" target="_blank">Lords</a>.

array

{"format":"int32","type":"integer"}

=item parameters.uINs

The UIN for the question - note that UINs reset at the start of each Parliamentary session.

array

{"type":"integer","format":"int32"}

=item parameters.answeringBodyIds

Which answering body is to respond. A list of answering bodies can be found <a target="_blank" href="http://data.parliament.uk/membersdataplatform/services/mnis/referencedata/AnsweringBodies/">here</a>.

array

{"format":"int32","type":"integer"}

=item parameters.skip

The number of records to skip from the first, default is 0.

integer

format: int32

=item parameters.take

The number of records to return, default is 25, maximum is 100.

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