#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 33;

use_ok('WWW::TV::Series');
use LWP::UserAgent;

{ # MASH via id =>
    diag('Testing by ID using series: 119 (M*A*S*H)') unless $ENV{HARNESS_ACTIVE};
    isa_ok(my $series = WWW::TV::Series->new(id => 119), 'WWW::TV::Series');
    is($series->name, 'M*A*S*H', 'series name is: M*A*S*H');
    is(
        $series->url,
        'http://www.tv.com/show/119/summary.html',
        'summary url matches'
    );
    is(
        $series->genres,
        'Comedy, Drama',
        'genres (scalar context) are: Comedy, Drama'
    );

    my @all_eps = $series->episodes;
    is(scalar(@all_eps), 251, 'total episode count');

    my @all_eps0 = $series->episodes( season => 0 );
    is(scalar(@all_eps0), 251, 'total episode count (using season 0)');

    my @season1_eps = $series->episodes( season => 1 );
    is(scalar(@season1_eps), 24, 'season 1 episode count');

    my @season2_eps = $series->episodes( season => 9 );
    is(scalar(@season2_eps), 20, 'season 9 episode count');

    my @genres = $series->genres;
    is(scalar(@genres), 2, 'genres (array context)');
}

{ # Prison Break via name =>
    diag('Testing by name using series: Prison Break') unless $ENV{HARNESS_ACTIVE};
    isa_ok(
        my $series = WWW::TV::Series->new(name => 'Prison Break'),
        'WWW::TV::Series',
    );
    is($series->id, 31635, 'series ID is 31635');
    ok($series->summary =~ /fox river/i, 'summary includes "fox river"');
    ok(
        $series->cast =~ /Wentworth Miller/,
        'cast (scalar context) includes Wentworth Miller'
    );
    my @cast = $series->cast;
    is(scalar(@cast), 5, 'cast (array context)');
    ok($series->image =~ /\.jpg$/, 'series image uri includes .jpg');
}

{ # Joey via id =>, and check episodes from both season 1 and 2
    diag("Testing by ID using series: Joey") unless $ENV{HARNESS_ACTIVE};
    isa_ok(my $series = WWW::TV::Series->new(id => 20952), 'WWW::TV::Series');
    is($series->name, 'Joey', 'series name is: Joey');
    isa_ok(
        my $episode_1 = ($series->episodes)[1], # Skip pilot episode
        'WWW::TV::Episode',
    );
    is(
        $episode_1->name,
        'Joey and the Student',
        'season 1 episode 1 is: Joey and the Student'
    );
    is($episode_1->season_number, 1, 'episode 1 is season 1');
    isa_ok(
        my $episode_27 = ($series->episodes)[26], # From season 2
        'WWW::TV::Episode',
    );

    is(
        $episode_27->name,
        'Joey and the Spanking',
        'episode 27 name is: Joey and the Spanking'
    );
    is($episode_27->season_number, 2, 'episode 27 is season 2');
    isa_ok($episode_27->series, 'WWW::TV::Series');
    is($episode_27->series->name, 'Joey', 'episode series is: Joey');
    
    # Verify site() accessor/mutator
    is($series->site, 'www', 'site defaults to: www');
    $series->site('us');
    is($series->site, 'us', 'changed site to: us');
    $series->site('bogus');
    is($series->site, 'us', 'ignored change to invalid site');
    $series->site('');
    is($series->site, 'www', 'reset site back to default'); 

    # Verify agent() accessor/mutator  
    is($series->agent, LWP::UserAgent::_agent, 'agent');
    $series->agent('Egg Scrambler 1.0');
    is($series->agent, 'Egg Scrambler 1.0', 'set custom user agent');
    $series->agent('');
    is($series->agent, LWP::UserAgent::_agent, 'reset agent to default');    

}

exit 0;
