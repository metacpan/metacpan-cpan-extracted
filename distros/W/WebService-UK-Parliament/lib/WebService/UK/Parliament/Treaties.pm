package WebService::UK::Parliament::Treaties;

use Mojo::Base 'WebService::UK::Parliament::Base';

has public_url => "https://treaties-api.parliament.uk/swagger/v1/swagger.json";

has private_url => "swagger/treaties-api.json";

has base_url => 'https://treaties-api.parliament.uk/';

1;

__END__

=head1 NAME

WebService::UK::Parliament::Treaties - Query the UK Parliament Treaties API

=head1 VERSION

Version 1.00

=cut

=head1 SYNOPSIS

	use WebService::UK::Parliament::Treaties;

	my $client = WebService::UK::Parliament::Treaties->new();

	my $data = $client->$endpoint($params);

=cut

=head1 DESCRIPTION

The following documentation is automatically generated using the UK Parliament OpenAPI specification.

An API exposing details of the treaties laid before Parliament.

=cut

=head1 Sections

=cut

=head2 BusinessItem

=cut

=head3 getBusinessItem

Returns the business item for the given ID.

=cut

=head4 Method

get

=cut

=head4 Path

/api/BusinessItem/{id}

=cut

=head4 Parameters

=over

=item id

Business item with the ID specified

string

=back

=cut

=head2 GovernmentOrganisation

=cut

=head3 getGovernmentOrganisation

Returns all government organisations.

=cut

=head4 Method

get

=cut

=head4 Path

/api/GovernmentOrganisation

=cut

=head2 SeriesMembership

=cut

=head3 getSeriesMembership

Returns all series memberships.

=cut

=head4 Method

get

=cut

=head4 Path

/api/SeriesMembership

=cut

=head2 Treaty

=cut

=head3 getTreaty

Returns a list of treaties.

=cut

=head4 Method

get

=cut

=head4 Path

/api/Treaty

=cut

=head4 Parameters

=over

=item SearchText

Treaties which contains the search text specified

string

=item GovernmentOrganisationId

Treaties with the government organisation id specified

integer

format: int32

=item Series

Treaties with the series membership type specified

string

CountrySeriesMembership
EuropeanUnionSeriesMembership
MiscellaneousSeriesMembership

=item ParliamentaryProcess

Treaties where the parliamentary process is concluded or notconcluded

string

NotConcluded
Concluded

=item DebateScheduled

Treaties which contain a scheduled debate

boolean

=item MotionToNotRatify

Treaties which contain a motion to not ratify

boolean

=item RecommendedNotRatify

Treaties which are recommended to not ratify

boolean

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

=head3 getTreaty1

Returns a treaty by ID.

=cut

=head4 Method

get

=cut

=head4 Path

/api/Treaty/{id}

=cut

=head4 Parameters

=over

=item id

Treaty with ID specified

string

=back

=cut

=head3 getTreatyBusinessItems

Returns business items belonging to the treaty with ID.

=cut

=head4 Method

get

=cut

=head4 Path

/api/Treaty/{id}/BusinessItems

=cut

=head4 Parameters

=over

=item id

Business items belonging to treaty with the ID specified

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
