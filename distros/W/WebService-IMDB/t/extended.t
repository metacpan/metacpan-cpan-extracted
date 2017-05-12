#!/usr/bin/perl
# $Id: extended.t 6441 2011-06-09 19:10:32Z chris $

use strict;
use warnings;

use Data::Dumper qw(Dumper);

use Test::More;

BEGIN { use_ok('WebService::IMDB'); }

{
    my $ws = new_ok('WebService::IMDB' => ['cache_exp' => "3 months", "cache_root" => "/var/tmp"]);

    my $recurse = 1;
    my %seen;
    my @pending = (
#	["Title", "tconst", "tt0033467"],
#       ["Title", "tconst", "tt0081912"], # tv_series
#	["Title", "tconst", "tt0666576"], # tv_episode
	);

    foreach (@ARGV) {
	my $i;
	if (m/^\-/) {
	    if ($_ eq "--no-recursion") {
		$recurse = '';
	    } else {
		die "Unrecognised option $_";
	    }
	    next;

	} elsif (m/^tt\d+$/) {
	    $i = ["Title", "tconst", $_];
	} elsif (m/^nm\d+$/) {
	    $i = ["Name", "nconst", $_];
	} else {
	    die "Failed to parse $_";
	}

	push @pending, $i;

    }

    while (my $i = shift @pending) {

	diag($i->[2]);

	$seen{join(",", @$i)} = 1;

	my $o = $ws->search('type' => $i->[0], $i->[1] => $i->[2]);

	my @new;
	if ($i->[0] eq "Title") {
	    @new = check_Title($o, '$o');
	} elsif ($i->[0] eq "Name") {
	    @new = check_Name($o, '$o');
	}

	if ($recurse) {
	    foreach (@new) {
		if (!exists $seen{join(",", @$_)}) {
		    push @pending, $_;
		}
	    }
	}
    }
}

done_testing();


sub check_Birth {
    my $o = shift;
    my $n = shift;

    isa_ok($o, "WebService::IMDB::Birth", $n);
    if (defined $o->date()) { check_Date($o->date(), "${n}->date()"); }
    ok_or_undef($o->place(), "${n}->place()");

    return;
}

sub check_Char {
    my $o = shift;
    my $n = shift;
    my @n;

    if (ref $o && ref $o eq "WebService::IMDB::Name::Stub") {
	push @n, check_Name_Stub($o, $n);
	ok($o->char(1), "${n}->char(1)");
    } else {
	isa_ok($o, "WebService::IMDB::Char", $n);
	ok($o->char(), "${n}->char()");
    }

    return @n;
}

sub check_Certificate {
    my $o = shift;
    my $n = shift;

    isa_ok($o, "WebService::IMDB::Certificate", $n);
    ok_or_undef($o->attr(), "${n}->attr()");
    ok($o->certificate(), "${n}->certificate()");
    ok_or_undef($o->country(), "${n}->country()");

    return;
}

sub check_Credit {
    my $o = shift;
    my $n = shift;
    my @n;

    isa_ok($o, "WebService::IMDB::Credit", $n);
    push @n, check_Name_Stub($o->name(), "${n}->name()");
    ok_or_undef($o->attr(), "${n}->attr()");
    ok_or_undef($o->char(), "${n}->char()");
    ok_or_undef($o->job(), "${n}->job()");

    return @n;

}

sub check_CreditList {
    my $o = shift;
    my $n = shift;
    my @n;

    isa_ok($o, "WebService::IMDB::CreditList", $n);
    ok($o->label(), "${n}->label()");
    isa_ok($o->list(), "ARRAY", "${n}->list()");
    foreach (@{$o->list()}) {
	check_Credit($_, "${n}->list()->[]");
    }
    ok($o->token(), "${n}->token()");

    return @n;

}

sub check_Date {
    my $o = shift;
    my $n = shift;

    if (ref $o eq "") {
	# "1998 - Jan 1999" from nm0000255
	# TODO: References for other odd dates
	like($o, qr/^c\. \d{4}$|^\d{4}\-\d{4}$|^(?:[A-Z][a-z]{2} )?\d{4} - (?:[A-Z][a-z]{2} )?\d{4}|^\d{2}\?{2}$|^\d{3}\?{1}$/, $n);
    } else {
	isa_ok($o, "DateTime::Incomplete", $n);
    }

    return;
};

sub check_Death {
    my $o = shift;
    my $n = shift;

    isa_ok($o, "WebService::IMDB::Death", $n);
    ok_or_undef($o->cause(), "${n}->cause()");
    if (defined $o->date()) { check_Date($o->date(), "${n}->date()"); }
    ok_or_undef($o->place(), "${n}->place()");

    return;
}

sub check_Encoding {
    my $o = shift;
    my $n = shift;

    isa_ok($o, "WebService::IMDB::Encoding", $n);
    ok($o->url(), "${n}->url()");
    ok($o->format(), "${n}->format()");

    return;
}

sub check_Goof {
    my $o = shift;
    my $n = shift;

    isa_ok($o, "WebService::IMDB::Goof", $n);
    ok($o->text(), "${n}->text()");
    ok($o->type(), "${n}->type()");
    ok_bool($o->spoiler(), "${n}->spoiler()");

    return;
}

sub check_Image {
    my $o = shift;
    my $n = shift;

    isa_ok($o, "WebService::IMDB::Image", $n);
    ok($o->height(), "${n}->height()");
    ok($o->url(), "${n}->url()");
    ok($o->width(), "${n}->width()");

    return;
}

sub check_KnownFor {
    my $o = shift;
    my $n = shift;
    my @n;

    isa_ok($o, "WebService::IMDB::KnownFor", $n);
    push @n, check_Title_Stub($o->title(), "${n}->title()");
    ok($o->attr(), "${n}->attr()");

    return @n;
}

sub check_Name {
    my $o = shift;
    my $n = shift;
    my @n;

    isa_ok($o, "WebService::IMDB::Name", $n);

    ok($o->nconst(), "${n}->nconst()");

    isa_ok($o->aka(), "ARRAY", "${n}->aka()");
    foreach (@{$o->aka()}) {
	ok($_, "${n}->aka()->[]");
    }

    ok_or_undef($o->bio(), "${n}->bio()");

    if (defined $o->birth()) { check_Birth($o->birth(), "${n}->birth()"); }

    if (defined $o->death()) { check_Death($o->death(), "${n}->death()"); }

    if (defined $o->image()) { check_Image($o->image(), "${n}->image()"); }

    isa_ok($o->known_for(), "ARRAY", "${n}->known_for()");
    foreach (@{$o->known_for()}) {
	push @n, check_KnownFor($_, "${n}->known_for()->[]");
    }

    ok($o->name(), "${n}->name()");

    push @n, check_News($o->news(), "${n}->news()");

    isa_ok($o->photos(), "ARRAY", "${n}->photos()");
    foreach (@{$o->photos()}) {
	check_Photo($_, "${n}->photos()->[]");
    }

    isa_ok($o->quotes(), "ARRAY", "${n}->quotes()");
    foreach (@{$o->quotes()}) {
	ok($_, "${n}->quote()->[]");
    }

    ok_or_undef($o->real_name(), "${n}->real_name()");

    isa_ok($o->trivia(), "ARRAY", "${n}->trivia()");
    foreach (@{$o->trivia()}) {
	check_Trivium($_, "${n}->trivia()->[]");
    }

    isa_ok($o->where_now(), "ARRAY", "${n}->where_now()");
    foreach (@{$o->where_now()}) {
	check_WhereNow($_, "${n}->where_now()->[]");
    }

    is_deeply($o->_unparsed(), { map { $_ => {} } (1..5) }, "${n}->_unparsed()");
    if (0) { diag Dumper($o->_unparsed()); }

    return @n;
}

sub check_Name_Stub {
    my $o = shift;
    my $n = shift;
    my @n;

    isa_ok($o, "WebService::IMDB::Name::Stub", $n);
    ok($o->nconst(), "${n}->nconst()");
    ok_or_undef($o->char(1), "${n}->char(1)");
    if (defined $o->image(1)) { check_Image($o->image(1), "${n}->image(1)"); }
    ok_or_undef($o->name(1), "${n}->name(1)");
    ok($o->char(1) || $o->name(1), "${n}->char(1) || ${n}->name(1)");


    push @n, ["Name", 'nconst' => $o->nconst()];


    if (0) { # TODO: Option to control recursion
	check_Name($o, "${n}");
	check_Name($o->obj(), "${n}->obj()");
	is($o->nconst(), $o->obj()->nconst(), "${n}->nconst() eq ${n}->obj()->nconst()");
    }

    return @n;
}

sub check_News {
    my $o = shift;
    my $n = shift;
    my @n;

    isa_ok($o, "WebService::IMDB::News", $n);
    ok($o->limit(), "${n}->limit()");
    is($o->start(), 0, "${n}->start()");
    ok_or_zero($o->total(), "${n}->total()");

    ok($o->channel(), "${n}->channel()");
    isa_ok($o->items(), "ARRAY", "${n}->items()");
    foreach (@{$o->items()}) {
	push @n, check_NewsItem($_, "${n}->items()->[]");
    }
    ok($o->label(), "${n}->label()");
    ok($o->markup(), "${n}->markup()");
    isa_ok($o->sources(), "HASH", "${n}->items()");
    foreach (keys %{$o->sources()}) {
	check_NewsSource($o->sources()->{$_}, "${n}->sources()->{'$_'}");
    }
    ok($o->type(), "${n}->type()");

    return @n;
}

sub check_NewsItem {
    my $o = shift;
    my $n = shift;
    my @n;

    isa_ok($o, "WebService::IMDB::NewsItem", $n);
    ok($o->id(), "${n}->id()");
    ok($o->body(), "${n}->body()");
    isa_ok($o->datetime(), "DateTime", "${n}->datetime()");
    ok($o->head(), "${n}->head()");
    ok_or_undef($o->icon(), "${n}->icon()");
    ok_or_undef($o->link(), "${n}->link()");
    isa_ok($o->names(), "ARRAY", "${n}->names()");
    foreach (@{$o->names()}) {
	push @n, check_Name_Stub($_, "${n}->names()->[]");
    }
    check_NewsSource($o->source(), "${n}->source()");
    isa_ok($o->titles(), "ARRAY", "${n}->titles()");
    foreach (@{$o->titles()}) {
	push @n, check_Title_Stub($_, "${n}->titles()->[]");
    }

    return @n;
}

sub check_NewsSource {
    my $o = shift;
    my $n = shift;

    isa_ok($o, "WebService::IMDB::NewsSource", $n);
    ok($o->label(), "${n}->label()");
    ok_or_undef($o->logo(), "${n}->logo()");
    ok_or_undef($o->url(), "${n}->url()");

    return;
}

sub check_ParentalGuideItem {
    my $o = shift;
    my $n = shift;

    isa_ok($o, "WebService::IMDB::ParentalGuideItem", $n);
    ok($o->label(), "${n}->label()");
    ok($o->text(), "${n}->text()");

    return;
}

sub check_Photo {
    my $o = shift;
    my $n = shift;

    isa_ok($o, "WebService::IMDB::Photo", $n);
    ok_or_undef($o->caption(), "${n}->caption()");
    ok_or_undef($o->copyright(), "${n}->copyright()");
    check_Image($o->image(), "${n}->image()");

    return;
}

sub check_Plot {
    my $o = shift;
    my $n = shift;

    isa_ok($o, "WebService::IMDB::Plot", $n);
    ok_or_undef($o->author(), "${n}->author()");
    ok($o->text(), "${n}->text()");

    return;
}

sub check_Quote {
    my $o = shift;
    my $n = shift;
    my @n;

    isa_ok($o, "WebService::IMDB::Quote", $n);
    isa_ok($o->lines(), "ARRAY", "${n}->lines()");
    foreach (@{$o->lines()}) {
	push @n, check_QuoteLine($_, "${n}->lines()->[]");
    }
    ok($o->qconst(), "${n}->qconst()");

    return @n;
}

sub check_QuoteLine {
    my $o = shift;
    my $n = shift;
    my @n;

    isa_ok($o, "WebService::IMDB::QuoteLine", $n);
    isa_ok($o->chars(), "ARRAY", "${n}->chars()");
    foreach (@{$o->chars()}) {
	push @n, check_Char($_, "${n}->chars()->[]");
    }
    if (defined $o->quote()) { ok($o->quote(), "${n}->quote()"); }
    if (defined $o->stage()) { ok($o->stage(), "${n}->stage()"); }

    return @n;
}

sub check_Review {
    my $o = shift;
    my $n = shift;

    isa_ok($o, "WebService::IMDB::Review", $n);
    ok_or_undef($o->attr(), "${n}->attr()");
    ok_or_undef($o->label(), "${n}->label()");
    ok($o->url(), "${n}->url()");

    return;
}

sub check_Runtime {
    my $o = shift;
    my $n = shift;

    isa_ok($o, "DateTime::Duration", $n);

    return;
}

sub check_Season {
    my $o = shift;
    my $n = shift;
    my @n;

    isa_ok($o, "WebService::IMDB::Season", $n);
    ok($o->label(), "${n}->label()");
    isa_ok($o->list(), "ARRAY", "${n}->list()");
    foreach (@{$o->list()}) {
	check_Title_Stub($_, "${n}->list()->[]");
    }
    ok($o->token(), "${n}->token()");

    return @n;

}

sub check_Title {
    my $o = shift;
    my $n = shift;
    my @n;

    isa_ok($o, "WebService::IMDB::Title", $n);

    ok($o->tconst(), "${n}->tconst()");

    isa_ok($o->cast_summary(), "ARRAY", "${n}->cast_summary()");
    foreach (@{$o->cast_summary()}) {
	push @n, check_Credit($_, "${n}->cast_summary()->[]");
    }

    if (defined $o->certificate()) { check_Certificate($o->certificate(), "${n}->certificate()"); }

    isa_ok($o->creators(), "ARRAY", "${n}->creators()");
    foreach (@{$o->creators()}) {
	check_Credit($_, "${n}->creators()->[]");
    }

    isa_ok($o->credits(), "ARRAY", "${n}->credits()");
    foreach (@{$o->credits()}) {
	check_CreditList($_, "${n}->credits()->[]");
    }

    isa_ok($o->directors_summary(), "ARRAY", "${n}->directors_summary()");
    foreach (@{$o->directors_summary()}) {
	push @n, check_Credit($_, "${n}->directors_summary()->[]");
    }

    isa_ok($o->genres(), "ARRAY", "${n}->genres()");
    foreach (@{$o->genres()}) {
	ok($_, "${n}->genre()->[]");
    }

    ok_or_undef($o->goof(), "${n}->goof()");

    isa_ok($o->goofs(), "ARRAY", "${n}->goofs()");
    foreach (@{$o->goofs()}) {
	check_Goof($_, "${n}->goofs()->[]");
    }

    if (defined $o->image()) { check_Image($o->image(), "${n}->image()"); }

    if (defined $o->news()) { push @n, check_News($o->news(), "${n}->news()"); }

    ok_or_undef($o->num_votes(), "${n}->num_votes()");

    ok_or_undef($o->outline_plot, "${n}->outline_plot()");

    isa_ok($o->parental_guide(), "ARRAY", "parental_guide()");
    foreach (@{$o->parental_guide()}) {
	check_ParentalGuideItem($_, "parental_guide()->[]");
    }

    isa_ok($o->photos(), "ARRAY", "${n}->photos()");
    foreach (@{$o->photos()}) {
	check_Photo($_, "${n}->photos()->[]");
    }

    isa_ok($o->plots(), "ARRAY", "${n}->plots()");
    foreach (@{$o->plots()}) {
	check_Plot($_, "${n}->plots()->[]");
    }

    ok_or_undef($o->production_status(), "${n}->production_status()");

    if (defined $o->quote()) { push @n, check_Quote($o->quote(), "${n}->quote()"); }

    isa_ok($o->quotes(), "ARRAY", "${n}->quotes()");
    foreach (@{$o->quotes()}) {
	push @n, check_Quote($_, "${n}->quotes()->[]");
    }

    ok_or_undef($o->rating(), "${n}->rating()");

    if (defined $o->release_date()) { check_Date($o->release_date(), "${n}->release_date()"); }

    isa_ok($o->reviews(), "ARRAY", "${n}->reviews()");
    foreach (@{$o->reviews()}) {
	check_Review($_, "${n}->reviews()->[]");
    }

    if (defined $o->runtime()) { check_Runtime($o->runtime(), "${n}->runtime()"); }

    isa_ok($o->seasons(), "ARRAY", "${n}->seasons()");
    foreach (@{$o->seasons()}) {
	check_Season($_, "${n}->seasons()->[]");
    }

    if (defined $o->series()) { push @n, check_Title_Stub($o->series(), "${n}->series()"); }

    ok_or_undef($o->synopsis(), "${n}->synopsis()");

    ok_or_undef($o->tagline(), "${n}->tagline()");

    ok($o->title(), "${n}->title()");

    if (defined $o->trailer()) { check_Trailer($o->trailer(), "${n}->trailer()"); }

    isa_ok($o->trivia(), "ARRAY", "${n}->trivia()");
    foreach (@{$o->trivia()}) {
	check_Trivium($_, "${n}->trivia()->[]");
    }

    ok_or_undef($o->trivium(), "${n}->trivium()");

    ok($o->type(), "${n}->type()");

    if (defined $o->user_comment()) { check_UserComment($o->user_comment(), "${n}->user_comment()"); }

    isa_ok($o->user_comments(), "ARRAY", "${n}->user_comments()");
    foreach (@{$o->user_comments()}) {
	check_UserComment($_, "${n}->user_comments()->[]");
    }

    isa_ok($o->writers_summary(), "ARRAY", "${n}->writers_summary()");
    foreach (@{$o->writers_summary()}) {
	push @n, check_Credit($_, "${n}->writers_summary()->[]");
    }

    ok($o->year(), "${n}->year()");

    is_deeply($o->_unparsed(), { map { $_ => {} } (1..13) }, "${n}->_unparsed()");
    if (0) { diag Dumper($o->_unparsed()); }

    # TODO: These are probably subject to change.
    ok_or_undef($o->plot, "${n}->plot()");
    ok_or_undef($o->full_plot, "${n}->full_plot()");

    return @n;
}

sub check_Title_Stub {
    my $o = shift;
    my $n = shift;
    my @n;

    isa_ok($o, "WebService::IMDB::Title::Stub", $n);
    ok($o->tconst(), "${n}->tconst()");
    if (defined $o->release_date(1)) { check_Date($o->release_date(1), "${n}->release_date(1)"); }
    if (defined $o->image(1)) { check_Image($o->image(1), "${n}->image(1)"); }
    ok($o->title(1), "${n}->title(1)");
    ok($o->type(1), "${n}->type(1)");
    ok($o->year(1), "${n}->year(1)");

    push @n, ["Title", 'tconst' => $o->tconst()];


    if (0) { # TODO: Option to control recursion
	check_Title($o, "${n}");
	check_Title($o->obj(), "${n}->obj()");
	is($o->tconst(), $o->obj()->tconst(), "${n}->tconst() eq ${n}->obj()->tconst()");
    }

    return @n;
}

sub check_Trailer {
    my $o = shift;
    my $n = shift;

    isa_ok($o, "WebService::IMDB::Trailer", $n);
    ok($o->content_type(), "${n}->content_type()");
    ok($o->description(), "${n}->description()");
    isa_ok($o->duration(), "DateTime::Duration", "${n}->duration()");
    isa_ok($o->encodings(), "HASH", "${n}->encodings()");
    foreach (keys %{$o->encodings()}) {
	check_Encoding($o->encodings()->{$_}, "${n}->encodings()->{'$_'}");
    }
    isa_ok($o->slates(), "ARRAY", "${n}->slates()");
    foreach (@{$o->slates()}) {
	check_Image($_, "${n}->slates()->[]");
    }
    ok($o->title(), "${n}->title()");
    ok($o->type(), "${n}->type()");

    return;
}

sub check_Trivium {
    my $o = shift;
    my $n = shift;

    isa_ok($o, "WebService::IMDB::Trivium", $n);
    if (defined $o->date()) { check_Date($o->date(), "${n}->date()"); }
    ok($o->text(), "${n}->text()");
    if (defined $o->spoiler()) { ok_bool($o->spoiler(), "${n}->spoiler()"); }

    return;
}

sub check_UserComment {
    my $o = shift;
    my $n = shift;

    isa_ok($o, "WebService::IMDB::UserComment", $n);
    check_Date($o->date(), "${n}->date()");
    ok($o->status(), "${n}->status()");
    ok_or_undef($o->summary(), "${n}->summary()");
    ok($o->text(), "${n}->text()");
    ok_or_undef($o->user_location(), "${n}->user_location()");
    ok_or_undef($o->user_name(), "${n}->user_name()");
    ok_or_undef($o->user_rating(), "${n}->user_rating()");
    ok_or_undef($o->user_score(), "${n}->user_score()");
    ok_or_undef($o->user_score_count(), "${n}->user_score_count()");

    return;
}

sub check_WhereNow {
    my $o = shift;
    my $n = shift;

    isa_ok($o, "WebService::IMDB::WhereNow", $n);
    if (defined $o->date()) { check_Date($o->date(), "${n}->date()"); }
    ok($o->text(), "${n}->text()");

    return;
}


sub ok_or_undef {
    my $o = shift;
    my $n = shift;

    return ok(!defined $o || $o, $n);

}

sub ok_or_zero {
    my $o = shift;
    my $n = shift;

    if ($o == 0) {
	return is($o, 0, $n);
    } else {
	return ok($o, $n);
    }

}

sub ok_bool {
    my $o = shift;
    my $n = shift;

    # TODO: Something clever using B::svref_2object(\$o) to perform a better check.

    # like doesn't handle undef cleanly, it gets converted to "" (with a warning)
    # and then matches our regexp, hence passing the test.
    if (defined $o) {
	return like($o, qr/^1$|^$/, $n);
    } else {
	return is($o, "boolean", $n);
    }

}
