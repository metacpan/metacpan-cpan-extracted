#!/usr/bin/perl
# $Id: flixster.t 6395 2011-06-08 23:02:21Z chris $

use strict;
use warnings;

use Data::Dumper qw(Dumper);

use Test::More tests => 44;

BEGIN { use_ok('WebService::Flixster'); }

my $ws = new_ok('WebService::Flixster');

# Check fetching by a numeric imdbid
{
    my $m = $ws->search('type' => "Movie", 'imdbid' => "33467");
    isa_ok($m, "WebService::Flixster::Movie");
    is($m->id(), "10074", "id");
}

# Check fetching by a correctly formated imdbib using imdbid key
{
    my $m = $ws->search('type' => "Movie", 'imdbid' => "tt0033467");
    isa_ok($m, "WebService::Flixster::Movie");
    is($m->id(), "10074", "id");
}

# Extended checks, using the more correct tconst key
{
    my $m = $ws->search('type' => "Movie", 'id' => "10074");
    isa_ok($m, "WebService::Flixster::Movie");

    is($m->id(), "10074", "id");

    isa_ok($m->actors(), "ARRAY");
    isa_ok($m->actors()->[0], "WebService::Flixster::Actor::Stub");
    isa_ok($m->actors()->[0], "WebService::Flixster::Actor");
    is($m->actors()->[0]->name(), $m->actors()->[0]->obj()->name(), "name");

    ok($m->boxOffice() || 1, "boxOffice"); # TODO: Check more carefully + find a movie with this set

    isa_ok($m->dvdReleaseDate(), "DateTime::Incomplete");

    isa_ok($m->directors(), "ARRAY");
    isa_ok($m->directors()->[0], "WebService::Flixster::Director");

    ok($m->mpaa(), "mpaa");

    isa_ok($m->photos(), "ARRAY");
    isa_ok($m->photos()->[0], "WebService::Flixster::Photo");

    ok(defined $m->playing(), "playing");

    isa_ok($m->poster(), "WebService::Flixster::Poster");

    isa_ok($m->reviews(), "WebService::Flixster::Reviews");
    isa_ok($m->reviews()->critics(), "ARRAY");
    isa_ok($m->reviews()->critics()->[0], "WebService::Flixster::Review::Critic");
    isa_ok($m->reviews()->flixster(), "WebService::Flixster::Review::Flixster");
    isa_ok($m->reviews()->rottenTomatoes(), "WebService::Flixster::Review::RottenTomatoes");
    isa_ok($m->reviews()->recent(), "ARRAY");
    isa_ok($m->reviews()->recent()->[0], "WebService::Flixster::Review::User");

    isa_ok($m->runningTime(), "DateTime::Duration");

    ok($m->status(), "status");

    ok($m->synopsis(), "synopsis");

    isa_ok($m->tags(), "ARRAY");

    isa_ok($m->theaterReleaseDate(), "DateTime::Incomplete");

    ok($m->thumbnail(), "thumbnail");

    isa_ok($m->trailer(), "WebService::Flixster::Trailer");

    is($m->title(), "Citizen Kane", "title");

    ok($m->url(), "url");

    isa_ok($m->urls(), "ARRAY");
    isa_ok($m->urls()->[0], "WebService::Flixster::URL");

    if (0) {
	diag Dumper($m->_unparsed($_));
    }
}

# Extended checks, using the more correct tconst key
{
    my $a = $ws->search('type' => "Actor", 'id' => "162655785");
    isa_ok($a, "WebService::Flixster::Actor");

    is($a->id(), "162655785", "id");

    isa_ok($a->dob(), "DateTime::Incomplete");

    ok($a->name(), "name");

    ok($a->pob(), "pob");

    if (0) {
	diag Dumper($a->_unparsed($_));
    }
}

