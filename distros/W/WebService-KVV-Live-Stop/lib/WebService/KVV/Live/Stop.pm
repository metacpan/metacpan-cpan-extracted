use strict;
use warnings;
package WebService::KVV::Live::Stop;

# ABSTRACT: Arrival times for Trams/Buses in the Karlsruhe metropolitan area
our $VERSION = '0.007'; # VERSION

use Carp;
use utf8;
use Net::HTTP::Spore::Middleware::Format::JSON;
use Net::HTTP::Spore 0.08;
use Net::HTTP::Spore::Middleware::DefaultParams;
use File::ShareDir 'dist_file';

=pod

=encoding utf8

=head1 NAME

WebService::KVV::Live::Stop - Arrival times for Trams/Buses in the Karlsruhe metropolitan area


=head1 SYNOPSIS

    use WebService::KVV::Live::Stop;
    use utf8;
    use open qw( :encoding(UTF-8) :std );

    my $stop = WebService::KVV::Live::Stop->new("Siemensallee");
    print "Arrival time: $_->{time} $_->{route} $_->{destination}\n" for $stop->departures;

Print departure table:

    use WebService::KVV::Live::Stop;
    use utf8;
    use open qw( :encoding(UTF-8) :std );
    
    use Data::Dumper::Table;
    use Data::Visitor::Callback;

    $stop = WebService::KVV::Live::Stop->new($ARGV[0] // 'Kronenplatz');
    my @entries = $stop->departures;
    Data::Visitor::Callback->new('JSON::PP::Boolean' => sub { $_ = $_ ? 'true' : 0 })->visit(@entries);
    my $departure_table = Tabulate \@entries;
    $departure_table =~ s/^.*\n//; # remove object type

    print $departure_tabletable;



=head1 DESCRIPTION

API for searching for bus/tram stops in the Karlsruhe Metropolitan Area (Karlsruhe Verkehrsvertriebe network to be exact) and for listing departure times at said stops.

=cut

my $client = Net::HTTP::Spore->new_from_spec(dist_file 'WebService-KVV-Live-Stop', 'kvvlive.json');
$client->enable('Format::JSON');
$client->enable('DefaultParams', default_params => { key => '377d840e54b59adbe53608ba1aad70e8' });
$client->enable('UserAgent', useragent => __PACKAGE__ ." $VERSION");

=head1 IMPLEMENTATION

Not really an API, just a client for L<http://live.kvv.de>. See L<kvvlive.json|https://github.com/athreef/WebService-KVV-Live-Stop/blob/master/share/kvvlive.json> for details.

The client is based on L<Net::HTTP::Spore> and has some workarounds: It overrides a method from C<Net::HTTP::Spore > that doesn't handle colons properly and throws a generic message on errors instead of the more specific HTTP error messages. 

=head1 METHODS AND ARGUMENTS

=over 4

=item new($latitude, $langitude), new($name), new($id)

Search for matching local transport stops. C<$id> are identifiers starting with C<"de:">. C<$name> need not be an exact match.

Returns a list of C<WebService::KVV::Live::Stop>s in list context. In scalar context returns the best match.

=cut

#FIXME: timeout
sub new {
	my $class = shift;
    
    my @self;
    @_ or croak "No stop specified";
    my $response = 
        @_ == 2          ? $client->stop_by_latlon(LAT => shift, LON => shift)
      : $_[0] =~ /^de:$/ ? $client->stop_by_id(ID => shift)
                         : $client->stop_by_name(NAME => shift)
                         ;
    @{$response->{body}{stops}} or croak "No stops match arguments";
    $response->{body}{stops} = [$response->{body}{stops}[0]] unless wantarray;
    for my $stop (@{$response->{body}{stops}}) {
        my $obj = $stop;
		bless $obj, $class;
        push @self, $obj;
    }

	return wantarray ? @self : $self[0];
}


=item departures([$route])

Returns a list of departures for a WebService::KVV::Live::Stop. Results can be restricted to a particular route (Linie) by the optional argument.

=cut

sub _departures {
    my $id = shift;
    my $route = shift;

    # ?maxInfos=:maxInfos
    return defined $route ? $client->departures_by_route(ID => $id, ROUTE => $route)
                       : $client->departures_by_stop(ID => $id);
}

sub departures {
    my $self = shift;
    my $route = shift;

    my $id = $self->{id};
    my $response;
    eval {
    $response = _departures $id, $route;
    };
    defined $response or croak "Error during REST request (Ye, I know the error message sucks but it's acutally Net::HTTP::Spore throwing an exception without context)";
    return @{$response->{body}->{departures}}
}


1;
__END__

=back


=head1 GIT REPOSITORY

L<http://github.com/athreef/WebService-KVV-Live-Stop>

=head1 SEE ALSO

L<http://live.kvv.de>

=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
