package WebService::UK::Parliament::StatutoryInstruments;

use Mojo::Base 'WebService::UK::Parliament::Base';

has public_url => "https://statutoryinstruments-api.parliament.uk/swagger/v1/swagger.json";

has private_url => "swagger/statutoryinstruments-api.json";

has base_url => 'https://statutoryinstruments-api.parliament.uk/';

1;

__END__

=head1 NAME

WebService::UK::Parliament::StatutoryInstruments - Query the UK Parliament Statutory In API

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS

	use WebService::UK::Parliament::StatutoryInstruments;

	my $client = WebService::UK::Parliament::StatutoryInstruments->new();

	my $data = $client->$endpoint($params);

=cut

=head1 DESCRIPTION

The following documentation is automatically generated using the UK Parliament OpenAPI specification.

An API exposing details of the various types of Statutory Instruments laid before Parliament.

=cut

=head1 Sections

=cut

=head2 BusinessItem

=cut

=head3 getv1BusinessItem

Returns the business item for the given ID.

=cut

=head4 Method

get

=cut

=head4 Path

/api/v1/BusinessItem/{id}

=cut

=head4 Parameters

=over

=item id

Business item with the ID specified

string

=item LaidPaper

Business item by laid paper type

string

StatutoryInstrument
ProposedNegative

=back

=cut

=head2 LayingBody

=cut

=head3 getv1LayingBody

Returns all laying bodies.

=cut

=head4 Method

get

=cut

=head4 Path

/api/v1/LayingBody

=cut

=head2 Procedure

=cut

=head3 getv1Procedure1

Returns all procedures.

=cut

=head4 Method

get

=cut

=head4 Path

/api/v1/Procedure

=cut

=head3 getv1Procedure

Returns procedure by ID.

=cut

=head4 Method

get

=cut

=head4 Path

/api/v1/Procedure/{id}

=cut

=head4 Parameters

=over

=item id

Procedure with the ID specified

string

=back

=cut

=head2 ProposedNegativeStatutoryInstrument

=cut

=head3 getv1ProposedNegativeStatutoryInstrument

Returns a list of proposed negative statutory instruments.

=cut

=head4 Method

get

=cut

=head4 Path

/api/v1/ProposedNegativeStatutoryInstrument

=cut

=head4 Parameters

=over

=item Name

Proposed negative statutory instruments with the name provided

string

=item RecommendedForProcedureChange

Proposed negative statutory instruments recommended for procedure change

boolean

=item DepartmentId

Proposed negative statutory instruments with the department ID specified

integer

format: int32

=item LayingBodyId

Proposed negative statutory instruments with the laying body ID specified

string

=item Skip

The number of records to skip from the first, default is 0

integer

format: int32

=item Take

The number of records to return, default is 20

integer

format: int32

=back

=cut

=head3 getv1ProposedNegativeStatutoryInstrument1

Returns proposed negative statutory instrument by ID.

=cut

=head4 Method

get

=cut

=head4 Path

/api/v1/ProposedNegativeStatutoryInstrument/{id}

=cut

=head4 Parameters

=over

=item id

Proposed negative statutory instrument with the ID specified

string

=back

=cut

=head3 getv1ProposedNegativeStatutoryInstrumentBusinessItems

Returns business items belonging to a proposed negative statutory instrument.

=cut

=head4 Method

get

=cut

=head4 Path

/api/v1/ProposedNegativeStatutoryInstrument/{id}/BusinessItems

=cut

=head4 Parameters

=over

=item id

Business items belonging to proposed negative statutory instrument with the ID specified

string

=back

=cut

=head2 StatutoryInstrument

=cut

=head3 getv1StatutoryInstrument1

Returns a list of statutory instruments.

=cut

=head4 Method

get

=cut

=head4 Path

/api/v1/StatutoryInstrument

=cut

=head4 Parameters

=over

=item Name

Statutory instruments with the name specified

string

=item StatutoryInstrumentType

Statutory instruments where the statutory instrument type is the type provided

string

DraftAffirmative
DraftNegative
MadeAffirmative
MadeNegative

=item ScheduledDebate

Statutory instrument which contains a scheduled debate

boolean

=item MotionToStop

Statutory instruments which contains a motion to stop

boolean

=item ConcernsRaisedByCommittee

Statutory instruments which contains concerns raised by committee

boolean

=item ParliamentaryProcessConcluded

Statutory instruments where the parliamentary process is concluded or notconcluded

string

NotConcluded
Concluded

=item DepartmentId

Statutory instruments with the department ID specified

integer

format: int32

=item LayingBodyId

Statutory instruments with the laying body ID specified

string

=item House

Statutory instruments laid in the house specified

string

Commons
Lords

=item Skip

The number of records to skip from the first, default is 0

integer

format: int32

=item Take

The number of records to return, default is 20

integer

format: int32

=back

=cut

=head3 getv1StatutoryInstrument

Returns a statutory instrument by ID.

=cut

=head4 Method

get

=cut

=head4 Path

/api/v1/StatutoryInstrument/{id}

=cut

=head4 Parameters

=over

=item id

Statutory instrument with the ID specified

string

=back

=cut

=head3 getv1StatutoryInstrumentBusinessItems

Returns business items belonging to statutory instrument with ID.

=cut

=head4 Method

get

=cut

=head4 Path

/api/v1/StatutoryInstrument/{id}/BusinessItems

=cut

=head4 Parameters

=over

=item id

Business items belonging to statutory instrument with the ID specified

string

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
