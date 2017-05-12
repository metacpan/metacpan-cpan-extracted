#!perl

use strict;
use warnings;
use Test::More;
use Data::Dumper;

my $ywsid = $ENV{'YWSID'};

if($ywsid) {
  plan tests => 145;
}
else {
  plan skip_all => "Please set your YWSID environment variable to run tests";
}

use_ok('WebService::Yelp');

my $yelp = WebService::Yelp->new({ywsid => $ywsid});
  
isa_ok($yelp, 'WebService::Yelp');
can_ok($yelp, qw(new call search_review_bb search_review_gpr 
                 search_review_hood search_phone 
                 search_neighborhood_geocode
                 search_neighborhood_location));
  

my $biz_bb_res = $yelp->call('search.review.bb', {
                                                  tl_lat => 37.9,
                                                  tl_long => -122.5,
                                                  br_lat => 37.788022,
                                                  br_long => -122.399797,
                                                  num_biz_requested => 3,
                                                 });

is(3, scalar(@{$biz_bb_res->businesses}));
is($biz_bb_res->message()->text(), 'OK');
is($biz_bb_res->message()->code(), 0);

is_deeply($biz_bb_res, $yelp->search_review_bb({
                                                tl_lat => 37.9,
                                                tl_long => -122.5,
                                                br_lat => 37.788022,
                                                br_long => -122.399797,
                                                num_biz_requested => 3,
                                               }));
  
  
my $biz_gpr_res = $yelp->call('search.review.gpr', {
                                                    lat => 37.788022,
                                                    long => -122.399797,
                                                    term => 'soup',
                                                    radius => 10,
                                                    num_biz_requested => 1,
                                                   });
  
is(1, scalar(@{$biz_gpr_res->businesses}));
is($biz_gpr_res->message()->text(), 'OK');
is($biz_gpr_res->message()->code(), 0);


my $biz_hood_res = $yelp->call('search.review.hood', {
                                                      term => 'cream puffs',
                                                      location => '650 Mission St, San Francisco, CA',
                                                      num_biz_requested => 4,
                                                     });

is(4, scalar(@{$biz_hood_res->businesses}));
is($biz_hood_res->message()->text(), 'OK');
is($biz_hood_res->message()->code(), 0);

my $biz_phone = $yelp->call('search.phone', {
                                             phone => '4152550300',
                                            });

for my $b (
           (@{$biz_bb_res->businesses},
            @{$biz_gpr_res->businesses},
            @{$biz_hood_res->businesses},
            @{$biz_phone->businesses}),
          ) {
  

  isa_ok($b, 'WebService::Yelp::Business');
  can_ok($b, qw/distance neighborhoods state avg_rating city
         review_count latitude url id longitude 
         rating_img_url_small reviews name categories
         rating_img_url phone photo_url address1 address2
         nearby_url zip photo_url_small/);
  
  
  for my $n (@{$b->neighborhoods()}) {
    isa_ok($n, 'WebService::Yelp::Neighborhood');
    can_ok($n, qw/name url/);
  }
  
  for my $r (@{$b->reviews()}) {
    isa_ok($r, 'WebService::Yelp::Review');
    can_ok($r, qw/user_photo_url_small rating_img_url_small
           user_url rating_img_url user_name rating url
           text_excerpt user_photo_url id/);
  }
  
  for my $c (@{$b->categories()}) {
    isa_ok($c, 'WebService::Yelp::Category');
    can_ok($c, qw/search_url name category_filter/);
  }
}


my $hood_geo_res = $yelp->call('search.neighborhood.geocode', {
                                                               lat => 37.788022,
                                                               long => -122.399797,
                                                              });
my $hood_location_res = $yelp->call('search.neighborhood.location', {
                                                                     location => 'Shattuck Avenue, Berkeley, CA',
                                                                    });

for my $n (
           (@{$hood_geo_res->neighborhoods},
            @{$hood_location_res->neighborhoods})
          ) {
  isa_ok($n, 'WebService::Yelp::Neighborhood');
  can_ok($n, qw/name url city state/);

}

