use strict;
use warnings;
use FindBin qw/$Bin/;
use JSON::XS ();

use Test::More tests => 11;
use Test::Exception;

use_ok q{Weather::NHC::TropicalCyclone};

my $obj = Weather::NHC::TropicalCyclone->new;
isa_ok $obj, q{Weather::NHC::TropicalCyclone}, q{Can create instance of Weather::NHC::TropicalCyclone};

can_ok( $obj, (qw/new fetch active_storms/) );

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
    is( 2, scalar @{ $obj2->{_obj}->{activeStorms} }, q{active_storms count is as expected} );
    for my $s ( @{ $obj2->active_storms } ) {
        isa_ok $s, q{Weather::NHC::TropicalCyclone::Storm};
    }

    # test alarm in fetch
    local *HTTP::Tiny::get = sub {
        sleep 2;
    };

    dies_ok( sub { $obj2->fetch(1) }, q{testing 'fetch' method timeout} );
}

__END__
