package WebService::UK::Parliament::WrittenQuestions;

use Mojo::Base 'WebService::UK::Parliament::Base';

has public_url => "https://writtenquestions-api.parliament.uk/swagger/v1/swagger.json";

has private_url => "swagger/writtenquestions-api.json";

has base_url => 'https://writtenquestions-api.parliament.uk/';

1;

__END__

=head1 NAME

WebService::UK::Parliament::WrittenQuestions - Query the UK Parliament Written Qu API

=head1 VERSION

Version 1.00

=cut

=head1 SYNOPSIS

	use WebService::UK::Parliament::WrittenQuestions;

	my $client = WebService::UK::Parliament::WrittenQuestions->new();

	my $data = $client->$endpoint($params);

=cut

=head1 DESCRIPTION

The following documentation is automatically generated using the UK Parliament OpenAPI specification.

Data around written questions and answers, as well as written ministerial statements.

=cut

=head1 Sections

=cut

=head2 DailyReports

=cut

=head3 getdailyreportsdailyreports

Returns a list of daily reports

=cut

=head4 Method

get

=cut

=head4 Path

/api/dailyreports/dailyreports

=cut

=head4 Parameters

=over

=item dateFrom

Daily report with report date on or after the date specified. Date format yyyy-mm-dd

string

format: date-time

=item dateTo

Daily report with report date on or before the date specified. Date format yyyy-mm-dd

string

format: date-time

=item house

Daily report relating to the House specified. Defaults to Bicameral

string

Bicameral
Commons
Lords

=item skip

Number of records to skip, default is 0

integer

format: int32

=item take

Number of records to take, default is 20

integer

format: int32

=back

=cut

=head2 WrittenQuestions

=cut

=head3 getwrittenquestionsquestions

Returns a list of written questions

=cut

=head4 Method

get

=cut

=head4 Path

/api/writtenquestions/questions

=cut

=head4 Parameters

=over

=item askingMemberId

Written questions asked by member with member ID specified

integer

format: int32

=item answeringMemberId

Written questions answered by member with member ID specified

integer

format: int32

=item tabledWhenFrom

Written questions tabled on or after the date specified. Date format yyyy-mm-dd

string

format: date-time

=item tabledWhenTo

Written questions tabled on or before the date specified. Date format yyyy-mm-dd

string

format: date-time

=item answered

Written questions that have been answered, unanswered or either.

string

Any
Answered
Unanswered

=item answeredWhenFrom

Written questions answered on or after the date specified. Date format yyyy-mm-dd

string

format: date-time

=item answeredWhenTo

Written questions answered on or before the date specified. Date format yyyy-mm-dd

string

format: date-time

=item questionStatus

Written questions with the status specified

string

NotAnswered
AnsweredOnly
AllQuestions

=item includeWithdrawn

Include written questions that have been withdrawn

boolean

=item expandMember

Expand the details of Members in the results

boolean

=item correctedWhenFrom

Written questions corrected on or after the date specified. Date format yyyy-mm-dd

string

format: date-time

=item correctedWhenTo

Written questions corrected on or before the date specified. Date format yyyy-mm-dd

string

format: date-time

=item searchTerm

Written questions / statements containing the search term specified, searches item content

string

=item uIN

Written questions / statements with the uin specified

string

=item answeringBodies

Written questions / statements relating to the answering bodies with the IDs specified

array

{"format":"int32","type":"integer"}

=item members

Written questions / statements relating to the members with the IDs specified

array

{"format":"int32","type":"integer"}

=item house

Written questions / statements relating to the House specified

string

Bicameral
Commons
Lords

=item skip

Number of records to skip, default is 0

integer

format: int32

=item take

Number of records to take, default is 20

integer

format: int32

=back

=cut

=head3 getwrittenquestionsquestions1

Returns a written question

=cut

=head4 Method

get

=cut

=head4 Path

/api/writtenquestions/questions/{date}/{uin}

=cut

=head4 Parameters

=over

=item date

Written question on date specified

string

format: date-time

=item uin

Written question with uid specified

string

=item expandMember

Expand the details of Members in the results

boolean

=back

=cut

=head3 getwrittenquestionsquestions1

Returns a written question

=cut

=head4 Method

get

=cut

=head4 Path

/api/writtenquestions/questions/{id}

=cut

=head4 Parameters

=over

=item id

written question with ID specified

integer

format: int32

=item expandMember

Expand the details of Members in the result

boolean

=back

=cut

=head2 WrittenStatements

=cut

=head3 getwrittenstatementsstatements

Returns a list of written statements

=cut

=head4 Method

get

=cut

=head4 Path

/api/writtenstatements/statements

=cut

=head4 Parameters

=over

=item madeWhenFrom

Written statements made on or after the date specified. Date format yyyy-mm-dd

string

format: date-time

=item madeWhenTo

Written statements made on or before the date specified. Date format yyyy-mm-dd

string

format: date-time

=item searchTerm

Written questions / statements containing the search term specified, searches item content

string

=item uIN

Written questions / statements with the uin specified

string

=item answeringBodies

Written questions / statements relating to the answering bodies with the IDs specified

array

{"type":"integer","format":"int32"}

=item members

Written questions / statements relating to the members with the IDs specified

array

{"format":"int32","type":"integer"}

=item house

Written questions / statements relating to the House specified

string

Bicameral
Commons
Lords

=item skip

Number of records to skip, default is 0

integer

format: int32

=item take

Number of records to take, default is 20

integer

format: int32

=item expandMember

Expand the details of Members in the results

boolean

=back

=cut

=head3 getwrittenstatementsstatements1

Returns a written statemnet

=cut

=head4 Method

get

=cut

=head4 Path

/api/writtenstatements/statements/{date}/{uin}

=cut

=head4 Parameters

=over

=item date

Written statement on date specified

string

format: date-time

=item uin

Written statement with uid specified

string

=item expandMember

Expand the details of Members in the results

boolean

=back

=cut

=head3 getwrittenstatementsstatements1

Returns a written statement

=cut

=head4 Method

get

=cut

=head4 Path

/api/writtenstatements/statements/{id}

=cut

=head4 Parameters

=over

=item id

Written statement with ID specified

integer

format: int32

=item expandMember

Expand the details of Members in the results

boolean

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
