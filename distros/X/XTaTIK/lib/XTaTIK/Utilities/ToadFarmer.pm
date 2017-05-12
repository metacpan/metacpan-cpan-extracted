package XTaTIK::Utilities::ToadFarmer;

use strict;
use warnings;

our $VERSION = '0.005002'; # VERSION

use Toadfarm -init;
use XTaTIK::Utilities::Misc qw/merge_conf/;
use File::Find::Rule;

sub farm {
    my @sites = grep length, map s'^silo/?''r,
        File::Find::Rule->directory->maxdepth(1)->in('silo');

    my $main_conf = do 'XTaTIK.conf'
        or die "Failed to load main config file: $@ $!";
    for my $site ( @sites ) {
        my $site_conf = do "silo/$site/XTaTIK.conf"
            or die "Failed to load silo [$site] config file: $@ $!";

        mount XTaTIK => {
            Host       => qr{^\Q$site\E(:3000)?$},
            local_port => 3000,
            config     => {
                merge_conf( $main_conf, $site_conf ),
                site => $site,
            },
        };
    }

    start;
}

1;