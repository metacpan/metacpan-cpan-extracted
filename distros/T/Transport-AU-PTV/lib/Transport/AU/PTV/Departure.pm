package Transport::AU::PTV::Departure;
$Transport::AU::PTV::Departure::VERSION = '0.01';
use strict;
use warnings;
use 5.010;

use parent qw(Transport::AU::PTV::NoError);

use Transport::AU::PTV::Error;
use DateTime::Format::ISO8601;


sub new {
    my $class = shift;
    my ($api, $departure) = @_;

    return bless { api => $api, departure => $departure }, $class;
}


sub scheduled_departure { 
    my $datetime = $_[0]->{departure}{scheduled_departure_utc} // "<undef>";
    my $dt = eval { DateTime::Format::ISO8601->parse_datetime($datetime) };

    return Transport::AU::PTV::Error->message("scheduled_departure(): cannot convert date '$datetime' to DateTime object") if $@;

    return $dt;
}


sub estimated_departure { 
    my $datetime = $_[0]->{departure}{estimated_departure_utc} // "<undef>";
    my $dt = eval { DateTime::Format::ISO8601->parse_datetime($datetime) };
    return Transport::AU::PTV::Error->message("scheduled_departure(): cannot convert date '$datetime' to DateTime object") if $@;

    return $dt;
}


sub at_platform { return $_[0]->{departure}{at_platform} }


sub platform_number { return $_[0]->{departure}{platform_number} }


sub direction_id { return $_[0]->{departure}{direction_id} }


sub run_id { return $_[0]->{departure}{run_id} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Transport::AU::PTV::Departure

=head1 VERSION

version 0.01

=head1 NAME

Transport::AU::PTV::Departures - a collections of departures for a particular stop on the Victorian Public Transport Network

=head1 SYNOPSIS 

    # Credentials are in environment variables
    my @departures = Transport::AU::PTV->new
    ->routes->find({ name => 'Upfield' })
    ->stops->find({ name => "Coburg Station" })
    ->departures({ max_results => 1 })
    ->as_array;

    for my $departure (@departures) {
        say "Scheduled Departure: ". $departure->scheduled_departure;
        say "Estimated Departure: ". $departure->estimated_departure;
        say "Run ID: ". $departure->run_id;
    }

=head1 METHODS

=head2 new

    my $departure = Transport::AU::PTV::Departure->new( Transport::AU::PTV::APIRequest->new, $departure_structure );

=head2 scheduled_departure

    my $scheduled = $departure->scheduled_departure;
    say "Hour:Minute:Second: ".$scheduled->hms;

Returns a L<DateTime> object representing the scheduled date/time that the the train/tram/bus will depart from the station.

=head2 estimated_departure 

    my $estimated = $departure->estimated_departure;
    say "Hour:Minute:Second: ".$scheduled->hms;

Returns a L<DateTime> object representing the estimated date/time that the the train/tram/bus will depart from the station.

=head2 at_platform

    say "At platform" if $departure->at_platform;

Returns 1 if the departure is currently at the stop/platform. Returns 0 if it is not.

=head2 platform_number

Returns the platform number of the stop that this departure will leave from.

=head2 direction_id

Returns the direction identifier for the direction that this departure will head towards.

=head2 run_id 

Returns the run identifier for this departure.

=head1 AUTHOR

Greg Foletta <greg@foletta.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Greg Foletta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
