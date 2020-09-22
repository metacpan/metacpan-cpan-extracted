use strict;
use warnings;
use FindBin qw/$Bin/;
use JSON::XS   ();
use File::Temp ();
use Net::Ping  ();

use Test::More;
use Test::Exception;

use_ok q{Weather::NHC::TropicalCyclone};

my $obj = Weather::NHC::TropicalCyclone->new;
isa_ok $obj, q{Weather::NHC::TropicalCyclone}, q{Can create instance of Weather::NHC::TropicalCyclone};

can_ok( $obj, (qw/new fetch active_storms get_storm_by_id get_storm_ids _update_storm_cache fetch_rss_atlantic fetch_rss_east_pacific fetch_rss_central_pacific/) );

{
    ok $Weather::NHC::TropicalCyclone::DEFAULT_RSS_ATLANTIC,        q{Found default Atlantic RSS URL};
    ok $Weather::NHC::TropicalCyclone::DEFAULT_RSS_EAST_PACIFIC,    q{Found default Eastern Pacific RSS URL};
    ok $Weather::NHC::TropicalCyclone::DEFAULT_RSS_CENTRAL_PACIFIC, q{Found default Central Pacific RSS URL};

    local $Weather::NHC::TropicalCyclone::DEFAULT_RSS_ATLANTIC        = q{obviously bad url};
    local $Weather::NHC::TropicalCyclone::DEFAULT_RSS_EAST_PACIFIC    = q{foo bar};
    local $Weather::NHC::TropicalCyclone::DEFAULT_RSS_CENTRAL_PACIFIC = q{herp derp};

    dies_ok sub { $obj->fetch_rss_atlantic },        q{ rss fails on bad atlantic request };
    dies_ok sub { $obj->fetch_rss_east_pacific },    q{ rss fails on bad east pacific request };
    dies_ok sub { $obj->fetch_rss_central_pacific }, q{ rss fails on bad central pacific request };
}

my $p = Net::Ping->new();
SKIP: {
    skip( qq{Can't access NHC website\n}, 18 ) unless ( eval { $p->ping( q{www.nhc.noaa.gov}, 2 ); 1 } );
    my $at_rss = q{};
    ok $at_rss = $obj->fetch_rss_atlantic, q{make atlantic rss call};
    like $at_rss, qr/<rss/, q{appears to be RSS};

    {
        my $fh        = File::Temp->new();
        my $atl_fname = $fh->filename;
        ok $at_rss = $obj->fetch_rss_atlantic($atl_fname), q{make atlantic rss call};
        like $at_rss, qr/<rss/, q{appears to be RSS};
        ok -e $atl_fname, q{RSS file detected};
        local $/;
        my $atl_fname_rss = <$fh>;
        like $atl_fname_rss, qr/<rss/, q{saved file appears to be RSS};
        close $fh;
    }

    my $ep_rss = q{};
    ok $ep_rss = $obj->fetch_rss_east_pacific, q{make east pacific rss call};
    like $ep_rss, qr/<rss/, q{appears to be RSS};

    {
        my $fh         = File::Temp->new();
        my $epac_fname = $fh->filename;
        ok $ep_rss = $obj->fetch_rss_east_pacific($epac_fname), q{make east rss call};
        like $ep_rss, qr/<rss/, q{appears to be RSS};
        ok -e $epac_fname, q{RSS file detected};
        local $/;
        my $epac_fname_rss = <$fh>;
        like $epac_fname_rss, qr/<rss/, q{saved file appears to be RSS};
        close $fh;
    }

    my $cp_rss = q{};
    ok $cp_rss = $obj->fetch_rss_central_pacific, q{make central pacific rss call};
    like $cp_rss, qr/<rss/, q{appears to be RSS};

    {
        my $fh         = File::Temp->new();
        my $cpac_fname = $fh->filename;
        ok $cp_rss = $obj->fetch_rss_central_pacific($cpac_fname), q{make central rss call};
        like $cp_rss, qr/<rss/, q{appears to be RSS};
        ok -e $cpac_fname, q{RSS file detected};
        local $/;
        my $cpac_fname_rss = <$fh>;
        like $cpac_fname_rss, qr/<rss/, q{saved file appears to be RSS};
        close $fh;
    }
}

open my $dh, q{<}, qq{$Bin/../../data/CurrentStorms.json} or die $!;
local $/;
my $json     = <$dh>;
my $json_ref = JSON::XS::decode_json $json;
$obj->{_obj} = $json_ref;
ok exists $json_ref->{activeStorms}, q{data for test set up ok};
ok ref $obj->active_storms eq q{ARRAY}, q{active_storms is an array ref};

# simulating HTTP::Tiny->get...
{
    no warnings qw/redefine once/;
    local *HTTP::Tiny::get = sub {
        return { content => $json, status => 200 };
    };
    my $obj2 = Weather::NHC::TropicalCyclone->new;
    isa_ok $obj2, q{Weather::NHC::TropicalCyclone}, q{Can create instance of Weather::NHC::TropicalCyclone};
    ok $obj2->fetch, q{testing 'fetch' method};
    is q{HASH}, ref $obj2->{_storms}, q{internal storm cache is a hash ref};
    ok defined $obj2->{_storms}, q{internal storm cache is defined};
    is( 2, scalar @{ $obj2->{_obj}->{activeStorms} }, q{active_storms count is as expected} );
    for my $s ( @{ $obj2->active_storms } ) {
        isa_ok $s, q{Weather::NHC::TropicalCyclone::Storm};
    }

    for my $id ( @{ $obj2->get_storm_ids } ) {
        ok defined $id, q{storm id is defined, from cache};
        my $s = $obj2->get_storm_by_id($id);
        isa_ok $s, q{Weather::NHC::TropicalCyclone::Storm};
    }

    # test alarm in fetch
    local *HTTP::Tiny::get = sub {
        sleep 2;
    };

    dies_ok( sub { $obj2->fetch(1) }, q{testing 'fetch' method timeout} );
}

done_testing;

__END__
