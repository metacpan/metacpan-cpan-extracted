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

my $target_file = $ARGV[1];
die "The script expects a target filepath for the report as second argument" unless $target_file;

my $domains = load_csv($csv_file);

my $api = Webservice::OVH->new_from_json("../credentials.json");

my $zone = $api->domain->zone("nak-grossbottwar.de");

my $services = $api->domain->services;

my $lines = ["Domain,Fieldtype,Target,TTL,Subdomain\n"];

foreach my $domain ( keys %$domains ) {

    if ( $api->domain->zone_exists($domain) ) {

        my $line       = "";
        my $zone       = $api->domain->zone($domain);
        my $records_mx = $zone->records( field_type => 'MX' );
        my $records_a  = $zone->records( field_type => 'A' );

        foreach my $record ( @$records_mx, @$records_a ) {

            $line = sprintf( "%s,%s,%s,%s,%s\n", $domain, $record->field_type, $record->target, $record->ttl, $record->sub_domain );
            print STDERR $line;
            push @$lines, $line;
        }

    } else {

        push @$lines, $domain . "\n";

        print STDERR "Zone does not exist $domain \n";
    }
}

open( my $fh, '>', $target_file ) or die "Could not open file '$target_file' $!";

foreach my $line (@$lines) {

    print $fh $line;
}

close $fh;
