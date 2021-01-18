use strict;
use warnings;
use utf8;

use Test::More;

if ( !eval { require Test::TestCoverage; 1 } ) {
    plan skip_all => q{Test::TestCoverage required for testing test coverage};
}
plan tests => 7;
my $TEST    = q{TEST};
my $API_KEY = $ENV{'NOSOPEN_API_KEY'} || $TEST;
my $XML     = q{XML};

my $obj; #= WWW::NOS::Open->new($API_KEY);
#my $e;
#eval { $obj->get_version; };
#$e = Exception::Class->caught('NOSOpenInternalServerErrorException')
#  || Exception::Class->caught('NOSOpenUnauthorizedException');

TODO: {
    todo_skip
q{Can't test coverage on immutable instances},
      7
      if 1;

    Test::TestCoverage::test_coverage( 'WWW::NOS::Open' );
    Test::TestCoverage::test_coverage_except( 'WWW::NOS::Open', 'meta' );
    $obj = WWW::NOS::Open->new($API_KEY);
    $obj->get_api_key;
    $obj->set_api_key($API_KEY);
    $obj->get_version;
    $obj->get_latest_videos;
    $obj->get_latest_audio_fragments;
    $obj->search(q{cricket});
    $obj->get_tv_broadcasts;
    $obj->get_radio_broadcasts;
    $obj->DESTROY();
    Test::TestCoverage::ok_test_coverage('WWW::NOS::Open');

    $obj = WWW::NOS::Open::Version->new( q{v1}, q{0.0.1} );
    $obj->get_version;
    $obj->get_build;
    $obj->DESTROY();
    Test::TestCoverage::ok_test_coverage('WWW::NOS::Open::Version');

    $obj = WWW::NOS::Open::Resource->new();
    $obj->get_id;
    $obj->get_type;
    $obj->get_title;
    $obj->get_description;
    $obj->get_published;
    $obj->get_last_update;
    $obj->get_thumbnail_xs;
    $obj->get_thumbnail_s;
    $obj->get_thumbnail_m;
    $obj->get_link;
    $obj->get_keywords;
    $obj->DESTROY();
    Test::TestCoverage::ok_test_coverage('WWW::NOS::Open::Resource');

    $obj = WWW::NOS::Open::Article->new();
    $obj->get_id;
    $obj->get_type;
    $obj->get_title;
    $obj->get_description;
    $obj->get_published;
    $obj->get_last_update;
    $obj->get_thumbnail_xs;
    $obj->get_thumbnail_s;
    $obj->get_thumbnail_m;
    $obj->get_link;
    $obj->get_keywords;
    $obj->DESTROY();
    Test::TestCoverage::ok_test_coverage('WWW::NOS::Open::Article');

    $obj = WWW::NOS::Open::MediaResource->new();
    $obj->get_id;
    $obj->get_type;
    $obj->get_title;
    $obj->get_description;
    $obj->get_published;
    $obj->get_last_update;
    $obj->get_thumbnail_xs;
    $obj->get_thumbnail_s;
    $obj->get_thumbnail_m;
    $obj->get_link;
    $obj->get_keywords;
    $obj->get_embedcode;
    $obj->DESTROY();
    Test::TestCoverage::ok_test_coverage('WWW::NOS::Open::MediaResource');

    $obj = WWW::NOS::Open::Video->new();
    $obj->get_id;
    $obj->get_type;
    $obj->get_title;
    $obj->get_description;
    $obj->get_published;
    $obj->get_last_update;
    $obj->get_thumbnail_xs;
    $obj->get_thumbnail_s;
    $obj->get_thumbnail_m;
    $obj->get_link;
    $obj->get_keywords;
    $obj->get_embedcode;
    $obj->DESTROY();
    Test::TestCoverage::ok_test_coverage('WWW::NOS::Open::Video');

    $obj = WWW::NOS::Open::AudioFragment->new();
    $obj->get_id;
    $obj->get_type;
    $obj->get_title;
    $obj->get_description;
    $obj->get_published;
    $obj->get_last_update;
    $obj->get_thumbnail_xs;
    $obj->get_thumbnail_s;
    $obj->get_thumbnail_m;
    $obj->get_link;
    $obj->get_keywords;
    $obj->get_embedcode;
    $obj->DESTROY();
    Test::TestCoverage::ok_test_coverage('WWW::NOS::Open::AudioFragment');

}
