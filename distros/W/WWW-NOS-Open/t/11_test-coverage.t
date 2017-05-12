use Test::More;
eval "use Test::TestCoverage 0.08";
plan skip_all => "Test::TestCoverage 0.08 required for testing test coverage"
  if $@;

use WWW::NOS::Open;

plan tests => 7;
my $TEST    = q{TEST};
my $API_KEY = $ENV{'NOSOPEN_API_KEY'} || $TEST;
my $XML     = q{XML};

my $obj = WWW::NOS::Open->new($API_KEY);
my $e;
eval { $obj->get_version; };
$e = Exception::Class->caught('NOSOpenInternalServerErrorException')
  || Exception::Class->caught('NOSOpenUnauthorizedException');

TODO: {
    todo_skip
q{Need a connection to the NOS Open server. Set the enviroment variables NOSOPEN_SERVER and NOSOPEN_API_KEY to connect.},
      7
      if $e;

	TODO: {
		todo_skip
	q{Fails on calling add_method on an immutable Moose object},
		  7
		  if 1;

		test_coverage("WWW::NOS::Open");
		$obj = WWW::NOS::Open->new($API_KEY);
		$obj->get_api_key;
		$obj->set_api_key($API_KEY);
		$obj->get_version;
		$obj->get_latest_articles;
		$obj->get_latest_videos;
		$obj->get_latest_audio_fragments;
		$obj->search(q{cricket});
		$obj->get_tv_broadcasts;
		$obj->get_radio_broadcasts;
		$obj->DESTROY();
		$obj->meta();
		ok_test_coverage('WWW::NOS::Open');

		test_coverage("WWW::NOS::Open::Version");
		$obj = WWW::NOS::Open::Version->new( q{v1}, q{0.0.1} );
		$obj->get_version;
		$obj->get_build;
		$obj->DESTROY();
		$obj->meta();
		ok_test_coverage('WWW::NOS::Open::Version');

		test_coverage("WWW::NOS::Open::Resource");
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
		$obj->meta();
		ok_test_coverage("WWW::NOS::Open::Resource");

		test_coverage("WWW::NOS::Open::Article");
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
		$obj->meta();
		ok_test_coverage("WWW::NOS::Open::Article");

		test_coverage("WWW::NOS::Open::MediaResource");
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
		$obj->meta();
		ok_test_coverage("WWW::NOS::Open::MediaResource");

		test_coverage("WWW::NOS::Open::Video");
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
		$obj->meta();
		ok_test_coverage("WWW::NOS::Open::Video");

		test_coverage("WWW::NOS::Open::AudioFragment");
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
		$obj->meta();
		ok_test_coverage("WWW::NOS::Open::AudioFragment");

	}
}
