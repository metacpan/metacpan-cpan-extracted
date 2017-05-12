
package WWW::EchoNest::Artist;

use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw( first );

use WWW::EchoNest::Functional qw(
                                    keep
                                    stupid_get_attr
                                    simple_get_attr
                                    editorial_get_attr
                                    numerical_get_attr
                               );

use WWW::EchoNest::Util qw(
                              fix_keys
                              call_api
                         );

use WWW::EchoNest::Result::List;

BEGIN {
    our @EXPORT      = qw(  );
    our @EXPORT_OK   =
        (
         'list_terms',
         'similar',
         'search_artist',
         'top_hottt',
         'top_terms',
        );
}
use parent qw( WWW::EchoNest::ArtistProxy Exporter );

use overload
    '""' => '_stringify',
    ;



# # # # METHODS # # # #

sub new {
    my $class       = $_[0];
    my $args_ref    = $_[1];
    return $class->SUPER::new( $args_ref );
}



sub get_audio {
    return stupid_get_attr( $_[0], $_[1], 'audio' );
}

sub get_biographies {
    return simple_get_attr( $_[0], $_[1], 'biographies' );
}

sub get_blogs {
    return editorial_get_attr( $_[0], $_[1], 'blogs' );
}

sub get_familiarity {
    return numerical_get_attr( $_[0], $_[1], 'familiarity' );
}

# This one is unique!
sub get_foreign_id {
    my($self, $args_href) = @_;
    
    my $idspace      = $args_href->{idspace}       // 'musicbrainz';
    my $cache        = $args_href->{cache}         // 1;
    my $cached_val   = $self->{foreign_ids};
    my @matches      = grep { $_->{catalog} eq $idspace } @$cached_val;
    my $match        = $matches[0]->{foreign_id};

    # Possibly return the cached value
    return $match if $cache and $cached_val and $match;

    # Get a new value
    my $response = $self->get_attribute(
                                        {
                                         method => 'profile',
                                         bucket => "id:$idspace"
                                        }
                                       );
    my $foreign_ids = $response->{artist}{foreign_ids}   // [];
    push @{ $self->{foreign_ids} }, @$foreign_ids;
    @matches = grep { $_->{catalog} eq $idspace } @{ $self->{foreign_ids} };
    return $matches[0]->{foreign_id};
}

sub get_hotttnesss {
    return numerical_get_attr( $_[0], $_[1], 'hotttnesss' );
}

sub get_images {
    return simple_get_attr( $_[0], $_[1], 'images' );
}

sub get_news {
    return editorial_get_attr( $_[0], $_[1], 'news' );
}

sub get_reviews {
    return stupid_get_attr( $_[0], $_[1], 'reviews' );
}

sub get_similar {
    my($self, $args_href) = @_;
    my $cache             = $args_href->{cache}       // 1;
    my $start             = $args_href->{start}       // 0;
    my $results           = $args_href->{results}     // 15;
    my $limit             = $args_href->{limit}       // 0;
    my $reverse           = $args_href->{reverse}     // 0;
    my $buckets           = $args_href->{buckets}     || [];
    my $cached_val        = $self->{similar};

    my $kwargs_href = keep( $args_href, sub { $_[0] },
                             [ qw( min_familiarity max_familiarity
                                   min_hotttnesss  max_hotttnesss
                                   min_results buckets limit reverse
                                ) ] );

    $kwargs_href->{bucket} = delete $kwargs_href->{buckets}
        if $kwargs_href->{buckets};

    $kwargs_href->{limit}   = 'true' if $kwargs_href->{limit};
    $kwargs_href->{reverse} = 'true' if $kwargs_href->{reverse};
    
    my @artist_list
        = map { WWW::EchoNest::Artist->new(fix_keys($_)) } @$cached_val;
    
    return \@artist_list if $cache and $cached_val and $results == 15
        and $start == 0 and not $kwargs_href;

    my $request_href = {};
    for (keys %$kwargs_href) {
        $request_href->{$_} = $kwargs_href->{$_} if exists $kwargs_href->{$_};
    }
    $request_href->{method}    = 'similar';
    $request_href->{start}     = $start;
    $request_href->{results}   = $results;
    
    my $response = $self->get_attribute( $request_href );
    $self->{similar} = $response->{artists}
        if $results == 15 and $start == 0 and not $kwargs_href;

    my @artists = map { WWW::EchoNest::Artist->new(fix_keys($_)) }
        @{ $response->{artists} };
    return \@artists;
}

sub get_songs {
    my($self, $args_href) = @_;

    my $cache      = $args_href->{cache}     // 1;
    my $start      = $args_href->{start}     // 0;
    my $results    = $args_href->{results}   // 15;
    my $cached_val = $self->{songs};

    # Possibly return the cached value
    return $cached_val
        if $cache and $cached_val and $start == 0 and $results == 15;

    # Get a new value for the attribute
    my $response = $self->get_attribute
        (
         {
          method    => 'songs',
          start     => $start,
          results   => $results,
         }
        );
    my @song_list = $response->{songs};
    for (@song_list) {
        $_->{artist_name} = $self->get_name();
        $_->{artist_id}   = $self->get_id();
    }
    my @songs = map { WWW::EchoNest::Song->new(fix_keys($_)) } @song_list;
    my $result_list = WWW::EchoNest::Result::List->new
        ( \@songs, start => 0, total => $response->{total} );

    # Cache the new value and return it
    $self->{songs} = $result_list;
    return $result_list;
}

sub get_terms {
    my($self, $args_href) = @_;
    my $cache       = $args_href->{cache}  // 1;
    my $sort        = $args_href->{sort}   // 'weight';
    my $cached_val  = $self->{terms};
    
    return $cached_val if $cache and $cached_val and $sort eq 'weight';
    my $response   = $self->get_attribute( { method => 'terms', sort => $sort } );
    my $new_value  = $response->{terms};
    $self->{terms} = $new_value if $sort eq 'weight';
    return $new_value;
}

sub get_urls {
    my($self, $args_href) = @_;
    my $cache      = $args_href->{cache} // 1;
    my $cached_val = $self->{urls};
    return $cached_val if $cache and $cached_val;
    my $response = $self->get_attribute( { method => 'urls' } );
    return $self->{urls} = $response->{urls};
}

sub get_video {
    return stupid_get_attr( $_[0], $_[1], 'video' );
}



########################################################################
#
# FUNCTIONS
#
sub _stringify {
    return q[<Artist - '] . $_[0]->get_name . q['>];
}

sub list_terms {
    my $result_href = call_api(
                               {
                                method => 'artist/list_terms',
                                params => { type => $_[0] // 'style' },
                               }
                              );
    return $result_href->{response}{terms};
}

sub similar {
    my %args                = %{ $_[0] };
    my $buckets             = $args{buckets}    // [];
    my $start               = $args{start}      // 0;
    my $results             = $args{results}    // 15;
    my $limit               = $args{limit}      // 0;

    $args{names} = [ $args{names} ] if ref($args{names}) ne 'ARRAY';
    $args{ids}   = [ $args{ids} ]   if ref($args{ids})   ne 'ARRAY';

    my $keep_if_defined = sub {
        my $keepers =
            [
             'max_familiarity',
             'min_familiarity',
             'max_hotttnesss',
             'min_hotttnesss',
             'seed_catalog',
            ];
        return keep( $_[0], sub { defined($_[0]) }, $keepers );
    };

    my $keep_if_true = sub {
        my $keepers = [ qw[ names ids results buckets start limit ] ];
        return keep( $_[0], sub { $_[0] }, $keepers );
    };
    my $request_href = $keep_if_defined->( $keep_if_true->( \%args ) );

    $request_href->{limit} = 'true' if $request_href->{limit};

    $request_href->{name}  = delete $request_href->{names}
        if $request_href->{names};

    $request_href->{id}  = delete $request_href->{ids}
        if $request_href->{ids};

    my $result_href = call_api(
                               {
                                method => 'artist/similar',
                                params => $request_href,
                               }
                              );

    my @artist_list = map { WWW::EchoNest::Artist->new(fix_keys($_)) }
        @{ $result_href->{response}{artists} };

    return \@artist_list;
}

sub search_artist {
    my %args               = %{ $_[0] };

    # Set defaults
    my $buckets            = $args{ 'buckets' }              // [];
    my $start              = $args{ 'start' }                // 0;
    my $results            = $args{ 'results' }              // 15;
    my $limit              = $args{ 'limit' }                // 0;
    my $fuzzy_match        = $args{ 'fuzzy_match' }          // 0;

    my $keep_if_defined = sub {
        my $keepers = [ qw( max_familiarity min_familiarity
                            max_hotttnesss  min_hotttnesss
                            test_new_things ) ];
        return keep( $_[0], sub { defined($_[0]) }, $keepers );
    };
    my $keep_if_true = sub {
        my $keepers = [ qw( name description style mood results start buckets
                            limit fuzzy_match sort rank_type ) ];
        return keep( $_[0], sub { $_[0] }, $keepers );
    };
    my $request_href = $keep_if_defined->( $keep_if_true->( \%args ) );
    
    $request_href->{limit}       = 'true' if $request_href->{limit};
    $request_href->{fuzzy_match} = 'true' if $request_href->{fuzzy_match};

    my $result_href = call_api(
                               {
                                method => 'artist/search',
                                params => $request_href,
                               }
                              );
    my @artist_list = map { WWW::EchoNest::Artist->new(fix_keys($_)) }
        @{ $result_href->{response}{artists} };
    return \@artist_list;
}

sub top_hottt {
    my %args          = %{ $_[0] };
    
    # Set defaults
    $args{buckets}  //= [];
    $args{limit}    //= 0;
    $args{start}    //= 0;
    $args{results}  //= 15;

    # Filter the args
    my $request_href = keep( \%args, sub { wantarray ? @_ : $_[0] },
                           [ qw( start results buckets limit ) ] );
    
    $request_href->{limit}  = 'true' if $request_href->{limit};
    $request_href->{bucket} = delete $request_href->{buckets}
        if $request_href->{buckets};
    
    my $result_href = call_api(
                               {
                                method => 'artist/top_hottt',
                                params => $request_href,
                               }
                              );
    my @artist_list = map {  WWW::EchoNest::Artist->new( fix_keys($_) )  }
        @{ $result_href->{'response'}{'artists'} };
    return \@artist_list;
}

sub top_terms {
    my($args_ref) = $_[0];
    my %request_args = ();
    $request_args{results}  = $args_ref->{results} if $args_ref->{results};
    my $result_hash_ref
        = call_api(
                   {
                    method     => 'artist/top_terms',
                    params     => \%request_args,
                   }
                  );
    
    return $result_hash_ref->{response}{terms};
}



1; # End of WWW::EchoNest::Artist

__END__

=head1 NAME

WWW::EchoNest::Artist - Class definition for artist objects.

=head1 SYNOPSIS
    
use WWW::EchoNest::Artist;

=head1 METHODS

=head2 new

  Returns a new WWW::EchoNest::Artist instance.

  NOTE:
    WWW::EchoNest also provides the artist() convenience method to create
    new instances of WWW::EchoNest::Artist.
  
  ARGUMENTS:
    id     => id of the new artist
    name   => name of the new artist
    
  RETURNS:
    A new WWW::EchoNest::Artist instance.

  EXAMPLE:
    use WWW::EchoNest::Artist;
    my $artist1 = WWW::EchoNest::Artist->new({ id   => 'ARH6W4X1187B99274F' });
    my $artist2 = WWW::EchoNest::Artist->new({ name => 'pink floyd' });

    # or...

    use WWW::EchoNest;
    my $artist1 = get_artist('ARH6W4X1187B99274F');
    my $artist2 = get_artist('pink floyd');


=head2 get_id

  Returns the id of a WWW::EchoNest::Artist instance.

  ARGUMENTS:
    none

  RETURNS:
    The id of a WWW::EchoNest::Artist instance.

  EXAMPLE:
    use WWW::EchoNest;
    my $ae = artist({ name => 'autechre' });
    print $ae->get_id(), "\n";

    # AR4GKTH1187FB4C8DE

=head2 get_name

  Returns the name of a WWW::EchoNest::Artist instance.

  ARGUMENTS:
    none

  RETURNS:
    The name of a WWW::EchoNest::Artist instance.

  EXAMPLE:
    use WWW::EchoNest;
    my $ae = artist({ id => 'AR4GKTH1187FB4C8DE' });
    print $ae->get_name(), "\n";

    # Autechre

=head2 get_audio

  Get a list of audio documents found on the web related to an artist.

  ARGUMENTS:
    cache   => A boolean indicating whether or not the cached value should be used (if available). Defaults to True.
    results => An integer number of results to return
    start   => An integer starting value for the result set

  RETURNS:
    A list of audio document hash refs.

  EXAMPLE:
    use WWW::EchoNest;
    my $ae          = artist({ name => 'autechre' });
    my @audio_docs  = $ae->get_audio();
    my %audio_doc   = %{ $audio_docs[0] };

    for (keys %audio_doc) {
        print $_, " : ", $audio_doc{$_}, "\n";
    }

    ######## Results may differ ########
    #
    # title : 01 - Gelk
    # url : http://www.nogenremusic.com/wp-content/uploads/2011/05/Gelk.mp3
    # artist : Autechre
    # date : 2011-05-14T21:29:48
    # length : 611.0
    # link : http://www.nogenremusic.com
    # release : Peel Session
    # id : 1942e901ba6a07f8674916e547b2e539

=head2 get_biographies

  Get a list of artist biographies.

  ARGUMENTS:
    cache   => A boolean indicating whether or not the cached value should be used (if available). Defaults to True.
    results => An integer number of results to return
    start   => An integer starting value for the result set
    license => A string specifying the desired license type

  RETURNS:
    A list of biography document hash refs.

  EXAMPLE:
    use WWW::EchoNest;
    my $ae             = artist({ name => 'autechre' });
    my @biography_docs = $ae->get_biographies();
    my %biography_doc  = %{ $biography_docs[0] };
    print $biography_doc{'url'}, "\n";

    ######## Results may differ ########
    #
    # url : http://www.last.fm/music/Autechre/+wiki

=head2 get_blogs

  Get a list of blog articles related to an artist.

  ARGUMENTS:
    cache             => A boolean indicating whether or not the cached value should be used (if available). Defaults to True.
    results           => An integer number of results to return
    start             => An ingteger starting value for the result set
    high_relevance    => If true only items that are highly relevant for this artist will be returned

  RETURNS:
    A list of blog document hash refs.

  EXAMPLE:
    use WWW::EchoNest;
    my $rdj            = artist({ name => 'aphex twin' });
    my @blog_docs      = $rdj->get_biographies();
    my %blog_doc       = %{ $blog_docs[0] };
    print 'url : ', $blog_doc{'url'}, "\n";

    ######## Results may differ ########
    #
    # url : http://www.idmforums.com/showthread.php?t=82056&goto=newpost

=head2 get_familiarity

  Get Echo Nest's estimation of how familiar a given artist currently is to the world.

  ARGUMENTS:
    cache    => A boolean indicating whether or not the cached value should be used (if available). Defaults to True.

  RETURNS:
    A float representing familiarity.

  EXAMPLE:
    use WWW::EchoNest;
    my $artist_name   = q{Daniel Johnston};
    my $dj            = artist({ name => $artist_name });
    print $artist_name, "'s familiarity = ", $dj->get_familiarity(), "\n";

    ######## Results may differ ########
    #
    # Daniel Johnston's familiarity = 0.72026911075927047

=head2 get_foreign_id

  Get an artist's id for a given id-space. Default is MusicBrainz.

  ARGUMENTS:
    idspace => A string indicating the idspace to fetch a foreign id for.

  RETURNS:
    A foreign id string.

  EXAMPLE:
    use WWW::EchoNest;
    my $artist_name   = q{Daniel Johnston};
    my $dj            = artist({ name => $artist_name });
    print $artist_name, "'s MusicBrainz id is ", $dj->get_foreign_id( q{musicbrainz} ), "\n";

    ######## Results may differ ########
    #
    # Daniel Johnston's MusicBrainz id is musicbrainz:artist:8a7ca8b0-d23c-4eff-8fe9-6220ba5c9c76

=head2 get_hotttnesss

  Get Echo Nest's numerical estimation of how hottt an artist is.

  ARGUMENTS:
    cache    => A boolean indicating whether or not the cached value should be used (if available). Defaults to True.

  RETURNS:
    A float representing the artist's hotttnesss.

  EXAMPLE:
    use WWW::EchoNest;
    my $artist_name   = q{Fred Frith};
    my $frith         = artist({ name => $artist_name });
    print $artist_name, "'s hotttnesss is ", $frith->get_hotttnesss(), "\n";

    ######## Results may differ ########
    #
    # Fred Frith's hotttnesss is 0.37745777314700002

=head2 get_images

  Get a list of artist images.

  ARGUMENTS:
    cache   => A boolean indicating whether or not the cached value should be used (if available). Defaults to True.
    results => An integer number of results to return
    start   => An integer starting value for the result set
    license => A string specifying the desired license type

  RETURNS:
    An array of image document hash refs.

  EXAMPLE:
    use WWW::EchoNest;
    my $artist_name   = q{Fred Frith};
    my $frith         = artist({ name => $artist_name });
    my @image_docs    = $frith->get_images();
    my %image_doc     = %{ $image_docs[0] };

    print 'url : ', $image_doc{ 'url' }, "\n";

    ######## Results may differ ########
    #
    # url : http://userserve-ak.last.fm/serve/_/278303.jpg

=head2 get_news

  Get a list of news articles on the web related to an artist.

  ARGUMENTS:
    cache   => A boolean indicating whether or not the cached value should be used (if available). Defaults to True.
    results => An integer number of results to return
    start   => An integer starting value for the result set

  RETURNS:
    An array of news document hash refs.

  EXAMPLE:
    use WWW::EchoNest;
    my $artist_name   = q{Sun Ra};
    my $ra            = artist({ name => $artist_name });
    my @news_docs     = $ra->get_news();
    my %news_doc      = %{ $news_docs[0] };

    print 'name : ', $news_doc{ 'name' }, "\n";

    ######## Results may differ ########
    #
    # name : This Week in Jazz Blogrolling

=head2 get_reviews

  Get reviews related to an artist's work.

  ARGUMENTS:
    cache   => A boolean indicating whether or not the cached value should be used (if available). Defaults to True.
    results => An integer number of results to return
    start   => An integer starting value for the result set

  RETURNS:
    An array of review document hash refs.

  EXAMPLE:
    use WWW::EchoNest;
    my $artist_name   = q{Autechre};
    my $ae            = artist({ name => $artist_name });
    my @review_docs   = $ae->get_reviews();
    my %review_doc    = %{ $reviews_docs[0] };

    print 'url : ', $review_doc{ 'url' }, "\n";

    ######## Results may differ ########
    #
    # url : http://www.ultimate-guitar.com/reviews/compact_discs/autechre/draft_730/index.html

=head2 get_similar

  Get similar artists.

  ARGUMENTS:
    cache           => A boolean indicating whether or not the cached value should be used (if available). Defaults to True.
    results         => An integer number of results to return
    start           => An integer starting value for the result set
    max_familiarity => A float specifying the max familiarity of artists to search for
    min_familiarity => A float specifying the min familiarity of artists to search for
    max_hotttnesss  => A float specifying the max hotttnesss of artists to search for
    min_hotttnesss  => A float specifying the max hotttnesss of artists to search for
    reverse         => A boolean indicating whether or not to return dissimilar artists (wrecommender). Defaults to False.
        
  RETURNS:
    An array of WWW::EchoNest::Artist instances.

  EXAMPLE:
    use WWW::EchoNest;
    my $artist_name       = q{Autechre};
    my $ae                = artist({ name => $artist_name });
    my @similar_artists   = $ae->get_similar();
    my $similar_artist    = $similar_artists[0];

    print 'name : ', $similar_artist->get_name() , "\n";

    ######## Results may differ ########
    #
    # name : Aphex Twin

=head2 get_songs

  Get the songs associated with an artist.

  ARGUMENTS:
    cache           => A boolean indicating whether or not the cached value should be used (if available). Defaults to True.
    results         => An integer number of results to return
    start           => An integer starting value for the result set
        
  RETURNS:
    An array of WWW::EchoNest::Song instances.

  EXAMPLE:
    use WWW::EchoNest;
    my $artist_name       = q{Autechre};
    my $ae                = artist({ name => $artist_name });
    my @ae_songs          = $ae->get_songs();
    my $ae_song           = $ae_songs[0];

    print "$artist_name song : ", $ae_song->get_title() , "\n";

    ######## Results may differ ########
    #
    # Autechre song : Steels

=head2 get_terms

  Get the terms associated with an artist.

  ARGUMENTS:
    cache    => A boolean indicating whether or not the cached value should be used (if available). Defaults to True.
    sort     => A string specifying the desired sorting type (weight or frequency)
        
  RETURNS:
    An array of term document hash refs.

  EXAMPLE:
    use WWW::EchoNest;
    my $artist_name       = q{Autechre};
    my $ae                = artist({ name => $artist_name });
    my @ae_terms          = $ae->terms();
    my %ae_term           = %{ $ae_terms[0] };

    foreach my $key (keys %ae_term) {
        print $key, ' : ', $ae_term{$key}, "\n";
    }

    ######## Results may differ ########
    #
    # frequency : 0.94989445652524185
    # name : glitch
    # weight : 1.0

=head2 get_urls

  Get the urls for an artist.

  ARGUMENTS:
    cache    => A boolean indicating whether or not the cached value should be used (if available). Defaults to True.
        
  RETURNS:
    A url document hash ref.

  EXAMPLE:
    use WWW::EchoNest;
    my $artist_name       = q{Autechre};
    my $ae                = artist({ name => $artist_name });
    my $ae_urls           = $ae->urls();

    print $artist_name, "'s wikipedia site is ", $ae_urls->{ q{wikipedia_url} }, "\n";

    ######## Results may differ ########
    #
    # Autechre's wikipedia site is http://en.wikipedia.org/wiki/Autechre

=head2 get_video

  Get a list of video documents found on the web related to an artist.

  ARGUMENTS:
    cache           => A boolean indicating whether or not the cached value should be used (if available). Defaults to True.
    results         => An integer number of results to return
    start           => An integer starting value for the result set
        
  RETURNS:
    An array of video document hash refs.

  EXAMPLE:
    use WWW::EchoNest;
    my $artist_name       = q{Autechre};
    my $ae                = artist({ name => $artist_name });
    my @ae_videos         = $ae->videos();
    my %ae_video          = %{ $ae_videos[0] };

    foreach my $key (keys %ae_video) {
        print $key, ' : ', $ae_video{$key}, "\n";
    }

    ######## Results may differ ########
    #
    # url : http://www.youtube.com/watch?v=as3jowB-2cM
    # date_found : 2011-05-25T02:56:31
    # title : DJ Freak - Autechre (Remix)
    # id : e18a600edd9616522d20219abf183243
    # site : youtube



=head1 FUNCTIONS

=head2 list_terms

  Get a list of best terms to use with search.

  ARGUMENTS:
    type => the type of terms to list; either 'mood' or 'style'

  RETURNS:
    An array of hash refs.

  EXAMPLE:
    use WWW::EchoNest::Artist qw{ list_terms };
    my @best_terms = list_terms( { type => q{mood} });
    for (@best_terms) {
        my %term_for = %{ $_ };
    }
    foreach my $k ( keys %term_for ) {
        print $k, " : ", %term_for{$k}, "\n";
    }

    ######## Results may differ ########
    #
    # name : aggressive
    # name : ambient
    # name : angry
    # name : angst-ridden
    # name : bouncy
    # name : calming
    # name : carefree



=head2 search_artist

  Search for artists by name, description, or constraint.

  ARGUMENTS:
    name            => The name of an artist
    description     => A string describing the artist
    style           => A string describing the style/genre of the artist
    mood            => A string describing the mood of the artist
    start           => An integer starting value for the result set
    results         => An integer number of results to return
    buckets         => A list of strings specifying which buckets to retrieve
    limit           => A boolean indicating whether or not to limit the results to one of the id spaces specified in buckets
    fuzzy_match     => A boolean indicating whether or not to search for similar sounding matches (only works with name)
    max_familiarity => A float specifying the max familiarity of artists to search for
    min_familiarity => A float specifying the min familiarity of artists to search for
    max_hotttnesss  => A float specifying the max hotttnesss of artists to search for
    min_hotttnesss  => A float specifying the max hotttnesss of artists to search for
    rank_type       => A string denoting the desired ranking for description searches, either 'relevance' or 'familiarity'

  RETURNS:
    An array of WWW::EchoNest::Artist instances.
  
  EXAMPLE:
    use WWW::EchoNest::Artist qw{ search };
    @results = search( { name => 't-pain' } );
    for (@results) {
        print $_->get_name(), "\n";
    }

    ######## Results may differ ########
    #
    # T-Pain
    # T-Pain & Lil Wayne
    # T-Pain & 2 Pistols


=head2 similar

  Return artists similar to this one.

  ARGUMENTS:
    ids              => An artist id or list of ids
    names            => An artist name or list of names
    results          => An integer number of results to return
    buckets          => A list of strings specifying which buckets to retrieve
    limit            => A boolean indicating whether or not to limit the results to one of the id spaces specified in buckets
    start            => An integer starting value for the result set
    max_familiarity  => A float specifying the max familiarity of artists to search for
    min_familiarity  => A float specifying the min familiarity of artists to search for
    max_hotttnesss   => A float specifying the max hotttnesss of artists to search for
    min_hotttnesss   => A float specifying the max hotttnesss of artists to search for
    seed_catalog     => A string specifying the catalog similar artists are restricted to

  RETURNS:
    An array of WWW::EchoNest::Artist instances.

  EXAMPLE:
    my @artist_list     = ( artist('weezer'), artist('radiohead') );
    my $id_list_ref     = map { $_->id() } @artist_list;
    my @similar_artists = similar( {
        ids             => $id_list_ref,
        results         => 5,
    } );

    for (@similar_artists) {
        print $_->get_name(), "\n";
    }

    ######## Results may differ ########
    # 
    # The Smashing Pumpkins
    # Biffy Clyro
    # Death Cab for Cutie
    # Jimmy Eat World
    # Nerf Herder



=head2 top_hottt

  Get the top hotttest artists, according to the Echo Nest
  
  ARGUMENTS:
    results   => An integer number of results to return
    start     => An integer starting value for the result set
    buckets   => A list of strings specifying which buckets to retrieve
    limit     => A boolean indicating whether or not to limit the results to one of the id spaces specified in buckets
  
  RETURNS:
    An array of blessed references to WWW::EchoNest::Artist objects.
  
  EXAMPLE:
    use WWW::EchoNest::Artist qw{ top_hottt };
    my @hotttest_artists = top_hottt();
    for (@hotttest_artists) {
        print $_->get_name(), "\n";
    }
    
    ######## Results may differ ########
    #
    # Lady Gaga
    # Rihanna
    # Jennifer Lopez
    # Adele
    # Bruno Mars
    # LMFAO
    # Pit Bull
    # Blake Shelton



=head2 top_terms

  Get a list of the top overall terms.

  ARGUMENTS:
    results => an integer number of results to return

  RETURNS:
    An array of hash refs

  EXAMPLE:
    use WWW::EchoNest::Artist qw{ top_terms };
    my @terms_list = top_terms({ results => 2 });
    for (@terms_list) {
        my %term_for = %{ $_ };
        foreach my $k (keys %term_for) {
            print $k, " : ", $term_for{$k}, "\n";
        }
        print "\n";
    }

    ######## Results may differ ########
    #
    # frequency : 1.0
    # name : rock
    #
    # frequency 0.98900693989606991
    # name : electronic



=head1 AUTHOR

Brian Sorahan, C<< <bsorahan@gmail.com> >>

=head1 SUPPORT

Join the Google group: <http://groups.google.com/group/www-echonest>

=head1 ACKNOWLEDGEMENTS

Thanks to all the folks at The Echo Nest for providing access to their
powerful API.

=head1 LICENSE

Copyright 2011 Brian Sorahan.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
