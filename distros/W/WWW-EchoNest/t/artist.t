#!/usr/bin/perl -T

use 5.010;
use strict;
use warnings;

use Test::More 'no_plan';

BEGIN {
    use_ok( 'WWW::EchoNest',            qw[ get_artist                 ] );
    use_ok( 'WWW::EchoNest::Id',        qw[ is_id                      ] );
    use_ok( 'WWW::EchoNest::Artist',    qw[
                                              list_terms
                                              similar
                                              search_artist
                                              top_hottt
                                              top_terms
                                         ]
          );
}


########################################################################
#
# Test basic artist creation providing a 'name' field
#
my $residents = new_ok('WWW::EchoNest::Artist', [ { name => 'The Residents' } ]);
isa_ok( $residents, q/WWW::EchoNest::Artist/ );



########################################################################
#
# get_name, get_id,
#
is( $residents->get_name(), 'The Residents', '$residents->get_name()' );
my $residents_id = $residents->get_id;
ok( defined($residents_id), '$residents->get_id() defined' );
ok( is_id($residents_id), '$residents->get_id() is valid id' );
# Test artist creation with no 'name' field
my $jeck = new_ok('WWW::EchoNest::Artist' => [ { id => 'ARAOQE51187B9B3DF3' } ]);
my $jeck_name = $jeck->get_name;
ok( defined($jeck_name), '$jeck->get_name defined' );
like( $jeck_name, qr/Philip Jeck/, q[$jeck->get_name matches /Philip Jeck/] );



########################################################################
#
# &WWW::EchoNest::Artist::get_audio
#
can_ok( $jeck, 'get_audio', );
my $jeck_audio = $jeck->get_audio();
# ok( defined($jeck_audio), 'get_audio result is defined' );
isa_ok( $jeck_audio, 'WWW::EchoNest::Result::List',
        'get_audio returns Result::List' );

# each audio doc should be a hash ref!
foreach my $audio_doc_ref ( $jeck_audio->list() ) {
    is( ref($audio_doc_ref), 'HASH', '$audio_doc_ref is a hash ref' );
    my $artist_field = $audio_doc_ref->{artist};
    ok( defined($artist_field), '$audio_doc_ref->{artist} is defined' );
    is( lc $artist_field,
        'philip jeck',
        '$audio_doc_ref->{artist} eq "Philip Jeck"' );
}

# Test the caching feature of &WWW::EchoNest::Artist::get_audio
my $second_jeck_audio_array_ref = $jeck->get_audio();
ok( $jeck_audio eq $second_jeck_audio_array_ref,
    'get_audio caches results properly' );

# Test get_audio with arguments
my $jeck_audio_w_args =
    $jeck->get_audio({ results => 1, start => 1, });

ok( defined($jeck_audio_w_args), 'get_audio w\args is defined' );
is( scalar( $jeck_audio_w_args->list() ), 1,
    q[get_audio w\args { results=>1, start=>1 } returned a single result] );



########################################################################
#
# get_biographies
#
can_ok( $jeck, 'get_biographies', );
my $jeck_biographies = $jeck->get_biographies();
isa_ok( $jeck_biographies, 'WWW::EchoNest::Result::List',
        'get_biographies returns Result::List' );

foreach my $biography ( $jeck_biographies->list() ) {
    is( ref($biography), 'HASH', '$biography is a hash ref' );
    my $text_field = $biography->{text};
    ok( defined($text_field), '$biography->{text} is defined' );
    like( $text_field, qr/philip/i, '$biography->{text} =~ m[Philip]i' );
}

# Test the caching feature of get_biographies
my $second_jeck_biographies = $jeck->get_biographies();
ok( $jeck_biographies eq $second_jeck_biographies,
    'get_biographies caches results properly' );



########################################################################
#
# get_blogs
#
can_ok( $jeck, 'get_blogs', );

my $jeck_blogs = $jeck->get_blogs();
isa_ok( $jeck_blogs, 'WWW::EchoNest::Result::List',
        'get_blogs returns Result::List' );

foreach my $blog ( $jeck_blogs->list() ) {
    is( ref($blog), 'HASH', '$blog is a hash ref' );
    my $summary_field = $blog->{summary};
    ok( defined($summary_field), '$blog->{summary} is defined' );
    like( $summary_field, qr/philip/i, '$blog->{summary} =~ m[philip]i' );
}

# Test the caching feature of &WWW::EchoNest::Artist::get_blogs
my $second_jeck_blogs = $jeck->get_blogs();
ok( $jeck_blogs eq $second_jeck_blogs, 'get_blogs caches results properly' );



########################################################################
#
# &WWW::EchoNest::Artist::get_familiarity
#
can_ok( $jeck, 'get_familiarity', );

my $jeck_familiarity = $jeck->get_familiarity();
like( $jeck_familiarity, qr/^\d*\.\d*$/, 'get_familiarity returns a float' );

# Test the caching feature of &WWW::EchoNest::Artist::get_familiarity
my $second_jeck_familiarity = $jeck->get_familiarity();
ok( $jeck_familiarity == $second_jeck_familiarity,
    'get_familiarity caches results properly' );



########################################################################
#
# &WWW::EchoNest::Artist::get_foreign_id
#
can_ok( $residents, 'get_foreign_id', );

my $residents_musicbrainz_id =
    $residents->get_foreign_id({ idspace => 'musicbrainz', });

ok( defined($residents_musicbrainz_id),
    '$residents->get_foreign_id({ idspace=>\'musicbrainz\' }) is defined' );

ok( is_id($residents_musicbrainz_id),
      'is_id(get_foreign_id) is TRUE' );

# Test the caching feature of &WWW::EchoNest::Artist::get_familiarity
my $second_residents_musicbrainz_id =
    $residents->get_foreign_id({ idspace => 'musicbrainz', });

ok( $residents_musicbrainz_id eq $second_residents_musicbrainz_id,
    'get_foreign_id caches results properly' );



########################################################################
#
# &WWW::EchoNest::Artist::get_hotttnesss
#
my $lmfao = get_artist('lmfao');
my $lmfao_hotttnesss = $lmfao->get_hotttnesss();
like( $lmfao_hotttnesss, qr/^\d*\.\d*$/, 'get_hotttnesss returns a float' );

# Test the caching feature of &WWW::EchoNest::Artist::get_hotttnesss
my $second_lmfao_hotttnesss = $lmfao->get_hotttnesss();
ok( $lmfao_hotttnesss == $second_lmfao_hotttnesss,
    'get_hotttnesss caches results properly' );



########################################################################
#
# &WWW::EchoNest::Artist::get_images
#
can_ok( $residents, 'get_images', );

my $residents_images = $residents->get_images();
isa_ok( $residents_images, 'WWW::EchoNest::Result::List',
        'get_images returns Result::List' );

# each images doc should be a hash ref!
for my $image_doc ( $residents_images->list() ) {
    is( ref($image_doc), 'HASH', '$images_doc_ref is a hash ref' );
}

# Test the caching feature of &WWW::EchoNest::Artist::get_images
my $second_residents_images = $residents->get_images();
ok( $residents_images eq $second_residents_images,
    'get_images caches results properly' );

########################################################################
#
# &WWW::EchoNest::Artist::get_news
#
can_ok( $lmfao, 'get_news' );
my $lmfao_news = $lmfao->get_news();
isa_ok( $lmfao_news, 'WWW::EchoNest::Result::List',
        'get_news returns Result::List' );

foreach my $news_doc_ref ( $lmfao_news->list() ) {
    is( ref($news_doc_ref), 'HASH', '$news_doc_ref is a hash ref' );
    my $summary_field = $news_doc_ref->{summary};
    ok( defined($summary_field), '$news_doc_ref->{summary} is defined' );
    like( $summary_field, qr/lmfao/i, '$news_doc_ref->{summary} =~ m[lmfao]i' );
}

# Test the caching feature of &WWW::EchoNest::Artist::get_news
my $second_lmfao_news = $lmfao->get_news();
ok( $lmfao_news eq $second_lmfao_news, 'get_news caches results properly' );



########################################################################
#
# &WWW::EchoNest::Artist::get_reviews
#
can_ok( $lmfao, 'get_reviews', );
my $lmfao_reviews = $lmfao->get_reviews();
isa_ok( $lmfao_reviews, 'WWW::EchoNest::Result::List',
        'get_reviews returns Result::List' );

# each reviews doc should be a hash ref!
for my $reviews_doc_ref ( $lmfao_reviews->list() ) {
    is( ref($reviews_doc_ref), 'HASH', '$reviews_doc_ref is a hash ref' );
    my $name_field = $reviews_doc_ref->{name};
    ok( defined($name_field), '$reviews_doc_ref->{name} is defined' );
    like( $name_field, qr/lmfao/i, '$reviews_doc_ref->{name} =~ m[lmfao]i' );
}

# Test the caching feature of &WWW::EchoNest::Artist::get_reviews
my $second_lmfao_reviews = $lmfao->get_reviews();
ok( $lmfao_reviews eq $second_lmfao_reviews,
    'get_reviews caches results properly' );



########################################################################
#
# &WWW::EchoNest::Artist::get_similar
#
can_ok( $residents, 'get_similar', );

my $similar_artists_aref = $residents->get_similar();
is( ref($similar_artists_aref), 'ARRAY',
    'get_similar returns ARRAY ref' );

for my $similar_artist ( @$similar_artists_aref ) {
    isa_ok( $similar_artist, 'WWW::EchoNest::Artist' );
}



########################################################################
#
# Test &WWW::EchoNest::Artist::get_songs
#
# Implementing this method is a work in progress...




########################################################################
#
# Test &WWW::EchoNest::Artist::get_terms
#
can_ok( $lmfao, 'get_terms', );
my $terms_ref = $lmfao->get_terms();
is( ref($terms_ref), 'ARRAY', 'get_terms returns ARRAY ref' );
for my $term (@$terms_ref) {
    is( ref($term), 'HASH', '$term is a HASH ref');
}



########################################################################
#
# Test &WWW::EchoNest::Artist::get_urls
#
can_ok( $jeck, 'get_urls', );
my $urls_ref = $jeck->get_urls();
is( ref($urls_ref), 'HASH', '$urls_ref is a HASH ref' );



########################################################################
#
# Test &WWW::EchoNest::Artist::get_video
#
can_ok( $residents, 'get_video', );
my $videos_ref = $residents->get_video();
isa_ok( $videos_ref, 'WWW::EchoNest::Result::List',
        'get_video returns Result::List' );

for my $video ( $videos_ref->list() ) {
    ok( exists $video->{title}, '$video->{title} exists' );
}



########################################################################
#
# We move on to testing the functional interface...
#
# &WWW::EchoNest::Artist::search_artist
#
can_ok( 'WWW::EchoNest::Artist', 'search_artist', );

my $artist_array_ref = search_artist( { name => 'Autechre' } );
is( ref($artist_array_ref), 'ARRAY', 'search_artist returns ARRAY ref' );

for my $artist ( @{ $artist_array_ref } ) {
    isa_ok( $artist, 'WWW::EchoNest::Artist' );
    like( $artist->get_name(), qr/autechre/i,
          'artist\'s name matches qr[autechre]i' );
}



########################################################################
#
# &WWW::EchoNest::Artist::top_hottt
#
can_ok( 'WWW::EchoNest::Artist', 'top_hottt', );
my $top_hottt_array_ref = top_hottt(
                                    {
                                     buckets => [ 'hotttnesss' ],
                                     results => 12
                                    }
                                   );
is( ref($top_hottt_array_ref), 'ARRAY', 'top_hottt returns ARRAY ref' );
for my $artist ( @{ $top_hottt_array_ref } ) {
    isa_ok( $artist, 'WWW::EchoNest::Artist' );
    my $hotttnesss = $artist->get_hotttnesss();
    ok( defined $hotttnesss, 'artist\'s hotttnesss is defined' );
    like( $hotttnesss, qr[\d*\.?\d*], 'artist\'s hotttnesss is a float' );
}



########################################################################
#
# &WWW::EchoNest::Artist::top_terms
#
can_ok( 'WWW::EchoNest::Artist', 'top_terms', );
my $top_terms_array_ref = top_terms( { results => 10 } );
is( ref($top_terms_array_ref), 'ARRAY', 'top_terms returns ARRAY ref' );

for my $term_hash_ref ( @{ $top_terms_array_ref } ) {
    is( ref($term_hash_ref), 'HASH', 'top_terms returns list of HASH refs');
    my $freq = $term_hash_ref->{ 'frequency' };
    my $name = $term_hash_ref->{ 'name'      };
    ok( defined($name), 'term\'s name is defined'      );
    ok( defined($freq), 'term\'s frequency is defined' );
    like( $name, qr/[\w\s]+/, 'term\'s name matches qr;[\w\s]+;' );
    like( $freq, qr/\d*\.?\d*/, 'term\'s frequency matches qr[\d*\.?\d*]' );
}



########################################################################
#
# &WWW::EchoNest::Artist::list_terms
#
can_ok( 'WWW::EchoNest::Artist', 'list_terms', );
my $list_terms_aref = list_terms('mood' );
is( ref($list_terms_aref), 'ARRAY', 'list_terms returns ARRAY ref' );

for my $term_hash_ref ( @{ $list_terms_aref } ) {
    is( ref($term_hash_ref), 'HASH', 'list_terms returns list of HASH refs');
    my $name = $term_hash_ref->{name};
    ok( defined($name), 'term\'s name is defined' );
    like( $name, qr/[\w\s]+/, 'term\'s name matches qr;[\w\s]+;' );
}



########################################################################
#
# &WWW::EchoNest::Artist::similar
#
can_ok( 'WWW::EchoNest::Artist', 'similar', );
my $similar_artist_aref = similar( { names => 'Autechre' } );
is( ref($similar_artist_aref), 'ARRAY', 'similar returns ARRAY ref' );

for my $artist ( @{ $similar_artist_aref } ) {
    isa_ok( $artist, 'WWW::EchoNest::Artist' );
}



