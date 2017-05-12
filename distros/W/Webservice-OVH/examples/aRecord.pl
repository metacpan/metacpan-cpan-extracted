use strict;
use warnings;
use List::Util qw(first);
use DateTime;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use lib "$Bin/../inc";
use Webservice::OVH;

my $csv_file = $ARGV[0];
die "The script expects a filepath to a csv file as first argument" unless $csv_file;

# load CSV for domains that should be changed
sub load_csv {

    my ($file) = @_;

    my $domain_list = {};

    open( my $fh, '<:encoding(UTF-8)', $file ) or die "Could not open file '$file' $!";

    while ( my $row = <$fh> ) {

        $row =~ s/\r\n//g;
        my @row = split( ',', $row );
        my $object = { area => $row[0], domain => $row[1], status => $row[2], auth => $row[3] };
        $domain_list->{ $row[1] } = $object;
    }

    close $fh;

    return $domain_list;
}

my $domains = load_csv($csv_file);

my $api = Webservice::OVH->new_from_json("../credentials.json");

my $zones = $api->domain->zones;

foreach my $domain ( keys %$domains ) {

    print STDERR "Zone $domain does not exist\n";
    next unless $api->domain->zone_exists( $domains->{$domain}{domain} );

    #next unless( $domains->{$domain}{status} eq 'connect' && $domains->{$domain}{auth} );

    my $zone           = $api->domain->zone( $domains->{$domain}{domain} );
    my $www_a_records  = $zone->records( field_type => 'A', subdomain => 'www' );
    my $base_a_records = $zone->records( field_type => 'A', subdomain => '' );

    foreach my $record ( @$www_a_records, @$base_a_records ) {

        $record->change( target => '', ttl => '' );
    }
}
