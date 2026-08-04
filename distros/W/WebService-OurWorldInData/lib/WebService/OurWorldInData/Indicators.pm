package WebService::OurWorldInData::Indicators;
# ABSTRACT: Queries the Our World in Data Indicators endpoint and collects the results

use Moo;
extends 'WebService::OurWorldInData';

use Carp;
use JSON qw(decode_json);
use PerlX::Maybe qw( maybe );
use Types::Standard qw( Str Int Num ); # Bool Enum ArrayRef HashRef InstanceOf ConsumerOf

has base_url => (
    is      => 'ro',
    default => sub { 'https://search.owid.io' },
);

has q => (
    is  => 'rw',
    isa => Str,
);

has limit => (
    is       => 'rw',
    isa      => Int,
);

has min_popularity => (
    is      => 'rw',
    isa     => Num, # score 0-1 to filter results
);


sub query {
    my ($self, $q) = @_;
    my $url = join '/', $self->base_url, 'indicators';

    $q //= $self->q;
    unless ( defined $q ) {
        warn 'query method requires an argument to search on';
        return;
    }

    my $query = ref $q eq 'HASH'
        ? $q
        : {
            query                => $q,
            maybe limit          => $self->limit,
            maybe min_popularity => $self->min_popularity,
        };
    unless ( ( exists $query->{query} && $query->{query} =~ /\w/)
                || ( exists $query->{q} && $query->{q} =~ /\w/) ) {
        warn 'query missing "q" or "query" parameter';
        return;
    }

    return decode_json $self->get_response( $url, $query );
}

sub health {
    my $self = shift;
    my $url = join '/', $self->base_url, 'health';
    my $msg = decode_json $self->get_response( $url );

    warn 'OWID Health check failed' unless $msg->{status} eq 'ok';
    return $msg;
}

1; # Perl is my Igor

=head1 SYNOPSIS

    my $ind = WebService::OurWorldInData::Indicators->new();

    my $result = $ind->query('gdp');

=head1 DESCRIPTION

Queries the Our World in Data Indicators api which provides data and metadata
in CSV format. The Indicators object can be created with the following attributes:

=over 4

=item limit - the number of results to return

=item min_popularity - filter results based on popularity score, value between 0 and 1

=back

as described by the OWiD API.

    my $ind = WebService::OurWorldInData::Indicators->new();

=head1 Methods

=head2 query

Search for indicators using semantic similarity.

    my $json_response = $ind->query('gdp');

=head2 health

Runs a health check on the endpoint and returns a hashref with the status.
It will warn if the status is not 'ok'.

=head2 Notes

Results returned in the JSON structure provided by OWID. No Perl object handling.

=head1 SEE ALSO

=over 4

=item * L<HTTP::Tiny>

=item * L<Indicators API|https://docs.owid.io/projects/etl/api/semantic-search-api>

=back

=cut
