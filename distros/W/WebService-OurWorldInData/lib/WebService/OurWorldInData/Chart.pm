package WebService::OurWorldInData::Chart;
# ABSTRACT: Queries the Our World in Data Chart endpoint and collects the results

use Moo;
extends 'WebService::OurWorldInData';

use Carp;
use JSON qw(decode_json);
use PerlX::Maybe qw( maybe provided );
use Types::Standard qw( Str Bool Enum ); # Int ArrayRef HashRef InstanceOf ConsumerOf

has chart => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

has short_names => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

has csv_type => (
    is      => 'rw',
    isa     => Enum[qw( full filtered )],
    default => 'full',
);

has [qw/time country/] => (
    is  => 'rw',
    isa => Str,
);


sub data {
    my $self = shift;
    my $url = $self->get_path . '.csv';

    my $query = {
        maybe time    => $self->time,
        maybe country => $self->country,
        provided $self->csv_type eq 'filtered',
                csvType => $self->csv_type,
        provided $self->short_names,
                useColumnShortNames => 'true',
    };

    return $self->get_response( $url, $query );
}

sub get_path {
    my $self = shift;
    return join '/', $self->base_url, 'grapher', $self->chart;
}

sub metadata {
    my ($self) = @_;

    my $url = $self->get_path . '.metadata.json';

    my $response = $self->get_response( $url );
    my $json = decode_json( $response );
    return $json;
}

sub zip {
    my ($self) = @_;

    my $url = $self->get_path . '.zip';

    my $response = $self->get_response( $url );
    return $response;
}

sub parse_data {
    my ($self, $body) = @_;

    require Text::CSV;
    my $csv = Text::CSV->new;
    my @rows = ();
    for my $line (split /\n/, $body) {
        unless ( $csv->parse($line) ) {
            carp "Error parsing CSV data (", $csv->error_diag(),
                ") suggest you save as a file and parse the file instead.";
            return;
        }
        push @rows, [ $csv->fields ];
    }

    return \@rows;
}

1; # Perl is my Igor

=head1 SYNOPSIS

    my $chart = WebService::OurWorldInData::Chart->new({
        chart => 'sea-surface-temperature-anomaly', # dataset name
    });

    my $result = $chart->data(); # get the csv data
    my $rows = $chart->parse_data($result);

=head1 DESCRIPTION

Queries the Our World in Data Chart api which provides data and metadata
in CSV format. The Chart object can be created with the following attributes:

short_names - a boolean flag to affect the results
csv_type - either full (default) or filtered
time/country - filter the results you request

as described by the OWiD API.

    my $chile = WebService::OurWorldInData::Chart->new(
                    chart => 'life-expectancy',
                    csv_type => 'filtered',
                    country => '~CHL',
                    time => '1998..2023' );

=head1 Methods

=head2 data

Queries the endpoint for the csv file

    my $result = $chart->data(); # get the csv data
    my $rows   = $chart->parse_data($result);

or save the data to a file

    open my $fh, '>', 'data.csv';
    print $fh $result;
    close $fh

=head2 parse_data

This is a convenience function to turn your csv data into a perl arrayref.
It's not very clever, but it will warn you when it runs into trouble and
suggests saving to a file instead.

=head2 metadata

Queries the endpoint for *.metadata.json

    my $json   = $chart->metadata(); # get the metadata
    my $column = (keys $result->{columns}->%*)[0]; # grab one of the really long keys
    print $json->{chart}{title},
        $json->{columns}{$column}{timespan};

=head2 zip

Queries the endpoint for the zip file

    my $result = $chart->zip;

    my $filename = $dataset . 'zip';
    open my $fh, '>:raw', $filename; # write out binary
    print $fh $result;
    close $fh;

    my $ae = Archive::Extract->new( archive => $filename );
    $ae->extract or warn "Error extracting $filename: ", $ae->error;
    my $files = $ae->files;

=head2 Notes


=head1 SEE ALSO

=over 4

=item * L<HTTP::Tiny>

=back

=cut
