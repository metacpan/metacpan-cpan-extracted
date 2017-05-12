#!/usr/bin/perl
# $Id: imdb.t 7352 2011-12-28 20:16:30Z chris $

use strict;
use warnings;

use Data::Dumper qw(Dumper);

use Test::More tests => 119;

BEGIN { use_ok('WebService::IMDB'); }

my $ws = new_ok('WebService::IMDB', ['agent' => "WebService::IMDB::Test/0.1"]);

diag("IMDB copyright statement: " . $ws->copyright());

# Check fetching by a numeric imdbid
{
    my $tt = $ws->search('type' => "Title", 'imdbid' => "33467");
    isa_ok($tt, "WebService::IMDB::Title");
    is($tt->tconst(), "tt0033467", "tconst()");
}

# Check fetching by a correctly formated imdbib using imdbid key
{
    my $tt = $ws->search('type' => "Title", 'imdbid' => "tt0033467");
    isa_ok($tt, "WebService::IMDB::Title");
    is($tt->tconst(), "tt0033467", "tconst()");
}

# Check fetching by a numeric imdbid
{
    my $nm = $ws->search('type' => "Name", 'imdbid' => "154");
    isa_ok($nm, "WebService::IMDB::Name");
    is($nm->nconst(), "nm0000154", "nconst()");
}

# Check fetching by a correctly formated imdbib using imdbid key
{
    my $nm = $ws->search('type' => "Name", 'imdbid' => "nm0000154");
    isa_ok($nm, "WebService::IMDB::Name");
    is($nm->nconst(), "nm0000154", "nconst()");
}

# Extended checks, using the more correct tconst key
{
    my $tt = $ws->search('type' => "Title", 'tconst' => "tt0033467");
    isa_ok($tt, "WebService::IMDB::Title");

    is($tt->tconst(), "tt0033467", "tconst()");

    isa_ok($tt->cast_summary(), "ARRAY", "cast_summary()");
    isa_ok($tt->cast_summary()->[0], "WebService::IMDB::Credit", "cast_summary->[0]");

    isa_ok($tt->cast_summary()->[0]->name(), "WebService::IMDB::Name::Stub", "cast_summary()->[0]->name()");
    isa_ok($tt->cast_summary()->[0]->name(), "WebService::IMDB::Name", "cast_summary()->[0]->name()");
    isa_ok($tt->cast_summary()->[0]->name()->image(), "WebService::IMDB::Image", "cast_summary()->[0]->name()->image()");
    is($tt->cast_summary()->[0]->name()->name(), $tt->cast_summary()->[0]->name()->obj()->name(), "name()");

    isa_ok($tt->certificate(), "WebService::IMDB::Certificate", "certificate()");

    # TODO: Credits

    isa_ok($tt->directors_summary(), "ARRAY", "directors_summary()");
    isa_ok($tt->directors_summary()->[0], "WebService::IMDB::Credit", "directors_summary()->[0]");

    isa_ok($tt->genres(), "ARRAY", "genres()");
    ok($tt->genres()->[0], "genres->[0]");

    ok($tt->goof(), "goof()");

    isa_ok($tt->goofs(), "ARRAY");
    isa_ok($tt->goofs()->[0], "WebService::IMDB::Goof", "goofs()->[0]");

    isa_ok($tt->image(), "WebService::IMDB::Image", "image()");

    # TODO: More throrough checking of news
    isa_ok($tt->news(), "WebService::IMDB::News", "news()");
    isa_ok($tt->news()->items(), "ARRAY", "news()->items()");
    isa_ok($tt->news()->items()->[0], "WebService::IMDB::NewsItem", "news()->items()->[0]");

    ok($tt->num_votes(), "num_votes()");

    ok($tt->outline_plot, "outline_plot()");

    isa_ok($tt->parental_guide(), "ARRAY", "parental_guide()");
    isa_ok($tt->parental_guide()->[0], "WebService::IMDB::ParentalGuideItem", "parental_guide()->[0]");

    isa_ok($tt->photos(), "ARRAY", "photos()");
    isa_ok($tt->photos()->[0], "WebService::IMDB::Photo", "photos()->[0]");

    isa_ok($tt->plots(), "ARRAY", "plots()");
    isa_ok($tt->plots()->[0], "WebService::IMDB::Plot", "plots()->[0]");

    isa_ok($tt->quote(), "WebService::IMDB::Quote", "quote()");

    isa_ok($tt->quotes(), "ARRAY", "quotes()");
    isa_ok($tt->quotes()->[0], "WebService::IMDB::Quote", "quotes()->[0]");

    ok($tt->rating(), "rating()");

    isa_ok($tt->release_date(), "DateTime::Incomplete", "release_date()");

    isa_ok($tt->reviews(), "ARRAY", "reviews()");
    isa_ok($tt->reviews()->[0], "WebService::IMDB::Review", "reviews()->[0]");

    isa_ok($tt->runtime(), "DateTime::Duration", "runtime()");

    ok($tt->synopsis(), "synopsis()");

    like($tt->tagline(), qr/[a-zA-Z ]+/, "tagline()");

    is($tt->title(), "Citizen Kane", "title()");

    isa_ok($tt->trailer(), "WebService::IMDB::Trailer", "trailer()");

    isa_ok($tt->trivia(), "ARRAY", "trivia()");
    isa_ok($tt->trivia()->[0], "WebService::IMDB::Trivium", "trivia()->[0]");

    ok($tt->trivium(), "trivium()");

    is($tt->type(), "feature", "type()");

    isa_ok($tt->user_comment(), "WebService::IMDB::UserComment", "user_comment()");

    isa_ok($tt->user_comments(), "ARRAY", "user_comments()");
    isa_ok($tt->user_comments()->[0], "WebService::IMDB::UserComment", "user_comments()->[0]");

    isa_ok($tt->writers_summary(), "ARRAY", "writers_summary()");
    isa_ok($tt->writers_summary()->[0], "WebService::IMDB::Credit", "writers_summary()->[0]");

    ok($tt->year(), "year()");


    ok($tt->plot, "plot()");
    ok($tt->full_plot, "full_plot()");

    if (0) {
	diag Dumper($tt->_unparsed($_));
    }
}

{
    my $tt = $ws->search('type' => "Title", 'tconst' => "tt0081912");
    isa_ok($tt, "WebService::IMDB::Title");
    is($tt->tconst(), "tt0081912", "tconst()");
    is($tt->title(), "Only Fools and Horses....", "title()");
    is($tt->type(), "tv_series", "type()");

    isa_ok($tt->creators(), "ARRAY", "creators()");
    isa_ok($tt->creators()->[0], "WebService::IMDB::Credit", "creators()->[0]");

    isa_ok($tt->seasons(), "ARRAY", "seasons()");
    isa_ok($tt->seasons()->[0], "WebService::IMDB::Season", "seasons()->[0]");
    is($tt->tconst(), $tt->seasons()->[0]->list->[0]->series()->tconst(), "tconst() eq seasons()->[0]->list->[0]->series()->tconst()");

    if (0) {
	diag Dumper($tt->_unparsed($_));
    }
}

{
    my $tt = $ws->search('type' => "Title", 'tconst' => "tt0666576");
    isa_ok($tt, "WebService::IMDB::Title");
    is($tt->tconst(), "tt0666576", "tconst()");
    is($tt->title(), "The Jolly Boys\' Outing", "title()");
    is($tt->type(), "tv_episode", "type()");

    isa_ok($tt->series(), "WebService::IMDB::Title");
    is($tt->series()->tconst(), "tt0081912", "series()");

    if (0) {
	diag Dumper($tt->_unparsed($_));
    }
}

{
    my $tt = $ws->search('type' => "Title", 'tconst' => "tt0386676");
    isa_ok($tt, "WebService::IMDB::Title");
    is($tt->tconst(), "tt0386676", "tconst()");

    ok($tt->production_status(), "production_status()");

    if (0) {
	diag Dumper($tt->_unparsed($_));
    }
}


# Extended checks, using the more correct nconst key
{
    my $nm = $ws->search('type' => "Name", 'nconst' => "nm0000154");
    isa_ok($nm, "WebService::IMDB::Name");
    is($nm->nconst(), "nm0000154", "nconst()");

    ok($nm->bio(), "bio()");

    isa_ok($nm->birth(), "WebService::IMDB::Birth", "birth()");
    isa_ok($nm->birth()->date(), "DateTime::Incomplete", "birth()->date()");
    ok($nm->birth()->place(), "birth()->place()");

    isa_ok($nm->image(), "WebService::IMDB::Image", "image()");

    isa_ok($nm->known_for(), "ARRAY", "known_for()");
    isa_ok($nm->known_for()->[0], "WebService::IMDB::KnownFor", "known_for()->[0]");

    isa_ok($nm->known_for()->[0]->title(), "WebService::IMDB::Title::Stub", "known_for()->[0]->title()");
    isa_ok($nm->known_for()->[0]->title(), "WebService::IMDB::Title", "known_for()->[0]->title()");
    isa_ok($nm->known_for()->[0]->title()->image(), "WebService::IMDB::Image", "known_for()->[0]->title()->image()");
    is($nm->known_for()->[0]->title()->title(), $nm->known_for()->[0]->title()->obj()->title(),
       "known_for()->[0]->title()->title() eq known_for()->[0]->title()->obj()->title()");

    is($nm->name(), "Mel Gibson", "name()");

    # TODO: More throrough checking of news
    isa_ok($nm->news(), "WebService::IMDB::News", "news()");
    isa_ok($nm->news()->items(), "ARRAY", "news()->items()");
    isa_ok($nm->news()->items()->[0], "WebService::IMDB::NewsItem", "news()->items()->[0]");

    isa_ok($nm->photos(), "ARRAY", "photos()");
    isa_ok($nm->photos()->[0], "WebService::IMDB::Photo", "photos()->[0]");
    isa_ok($nm->photos()->[0]->image(), "WebService::IMDB::Image", "photos()->[0]->image()");

    isa_ok($nm->quotes(), "ARRAY", "quotes()");

    is($nm->real_name(), "Mel Columcille Gerard Gibson", "real_name()");

    isa_ok($nm->trivia(), "ARRAY", "trivia()");
    isa_ok($nm->trivia()->[0], "WebService::IMDB::Trivium", "trivia()->[0]");

    if (0) {
	diag Dumper($nm->_unparsed($_));
    }
}

# Fields not available for Mel Gibson
{
    my $nm = $ws->search('type' => "Name", 'nconst' => "nm0000080");
    isa_ok($nm, "WebService::IMDB::Name");
    is($nm->nconst(), "nm0000080", "nconst()");

    isa_ok($nm->aka(), "ARRAY", "aka()");

    is($nm->aka()->[0], "O.W. Jeeves", "aka()->[0]");

    is($nm->name(), "Orson Welles", "name()");

    isa_ok($nm->death(), "WebService::IMDB::Death", "death()");
    ok($nm->death()->cause(), "death()->cause()");
    isa_ok($nm->death()->date(), "DateTime::Incomplete", "death()->date()");
    ok($nm->death()->place(), "death()->place()");

    if (0) {
	diag Dumper($nm->_unparsed($_));
    }
}

{
    my $nm = $ws->search('type' => "Name", 'nconst' => "nm0000032");
    isa_ok($nm, "WebService::IMDB::Name");
    is($nm->nconst(), "nm0000032", "nconst()");

    isa_ok($nm->aka(), "ARRAY", "where_now()");

    isa_ok($nm->where_now()->[0], "WebService::IMDB::WhereNow", "where_now()->[0]");
    isa_ok($nm->where_now()->[0]->date(), "DateTime::Incomplete", "where_now()->[0]->date()");
    ok($nm->where_now()->[0]->text(), "where_now()->[0]->text()");

    if (0) {
	diag Dumper($nm->_unparsed($_));
    }
}
