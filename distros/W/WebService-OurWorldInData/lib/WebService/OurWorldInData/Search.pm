package WebService::OurWorldInData::Search;
# ABSTRACT: Queries the Our World in Data Search endpoint and collects the results

use Moo;
extends 'WebService::OurWorldInData';

use Carp;
use JSON qw(decode_json);
use PerlX::Maybe qw( maybe provided );
use Types::Standard qw( Int Str Bool Enum ); # ArrayRef HashRef InstanceOf ConsumerOf

has q => (
    is       => 'rw',
    isa      => Str,
);

has type => (
    is      => 'rw',
    isa     => Enum[qw( charts pages )],
    default => 'charts',
);

has [qw/page hitsPerPage/] => (
    is  => 'rw',
    isa => Int,
);

has [qw/countries topics pageTypes/] => (
    is  => 'rw',
    isa => Str,
);

has require_all_countries => (
    is      => 'rw',
    isa     => Bool,
);


sub query {
    my ($self, $query_string) = @_;
    my $url = $self->get_path;

    my $query = {
        q => $query_string || $self->q,

        maybe type => $self->type,
        maybe page => $self->page,
        maybe hitsPerPage => $self->hitsPerPage,
    };
    if ($self->type eq 'charts') {
        $query->{countries} = $self->countries if $self->countries;
        $query->{topics} = $self->topics if $self->topics;
    }
    else {
        $query->{pageTypes} = $self->pageTypes if $self->pageTypes;
    }

    if (exists $query->{countries}) {
        maybe $query->{requireAllCountries} => $self->require_all_countries;
    }

    return decode_json $self->get_response( $url, $query );
}

sub get_path {
    my $self = shift;
    return join '/', $self->base_url, qw(api search);
}

sub extract_urls {
    my ($self, $data) = @_;

    return map { $_->{url} } @{$data->{results}};
}

1; # Perl is my Igor

=head1 SYNOPSIS

    my $search = WebService::OurWorldInData::Search->new();

    my $gdp = $search->query('gdp');
    for my $chart ( $gdp->{results}->@* ) {
        say $chart->{title};
    }

    my @urls = $search->extract_urls($gdp);

=head1 DESCRIPTION

Queries the Our World in Data Search api for charts or pages.
The Search object can be created with the following attributes:

=over 4

=item q - query text used when the query method is called with no arguments

=item type - either charts (default) or pages

=item page - page number for pagination

=item hitsPerPage - number of results per page

=item countries - (charts only) filter results based on countries (separated by ~)

=item topics - (charts only) topic name for filtering charts

=item requireAllCountries - boolean (only if countries provided)

=item pageTypes - (pages only) Comma-separated list of page content types to search

=back

Refine search query as described by the
L<OWiD Search API|https://docs.owid.io/projects/etl/api/search-api/>. eg.

    my $nato_fr = WebService::OurWorldInData::Search->new(
                    countries => 'Canada~France~Belgium',
                    );
    $nato_fr->hitsPerPage(50);
    $nato_fr->require_all_countries(1);

=head2 extract_urls

Provided as a utility function, it takes the response as an argument
and returns a list of urls extracted from the results.

=head2 NOTES

I haven't deconstructed the response from the Search endpoint.
Your results are a list of hashrefs in the data structure.
Let me know if you'd like a smoother api.

=head2 TODO

Add a C<next_page> function to continue fetching results.
This may need to store current page in a SearchResponse object.

=head1 SEE ALSO

=over 4

=item * L<HTTP::Tiny>

=back

=cut
