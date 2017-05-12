#!/usr/bin/perl
# $Id: extended.t 7365 2012-04-09 00:57:24Z chris $

use strict;
use warnings;

use Data::Dumper qw(Dumper);

use Test::More;

BEGIN { use_ok('WebService::Flixster'); }

{
    my $ws = new_ok('WebService::Flixster' => ['cache_exp' => "3 months", "cache_root" => "/var/tmp"]);

    my $recurse = 1;
    my %seen;
    my @pending = (
	);

    foreach (@ARGV) {
	    my $i;

	    if (m/^tt\d+$/) {
		$i = ["Movie", 'imdbid' => $_]
	    } else {
		die "Failed to parse $i";
	    }

	push @pending, $i;

    }

    while (my $i = shift @pending) {

	diag($i->[2]);

	$seen{join(",", @$i)} = 1;

	my $o = $ws->search('type' => $i->[0], $i->[1] => $i->[2]);

	my @new;
	if ($i->[0] eq "Movie") {
	    @new = check_Movie($o, '$o');
	} elsif ($i->[0] eq "Actor") {
	    @new = check_Actor($o, '$o');
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


sub check_Actor {
    my $o = shift;
    my $n = shift;

    isa_ok($o, "WebService::Flixster::Actor", $n);
    ok($o->id(), "${n}->id()");
    check_Date($o->dob(), "${n}->dob()");
    foreach (@{$o->movies()}) {
      check_Movie_Stub($_, "${n}->movies()->[]");
    }
    ok($o->name(), "${n}->name()");
    ok_or_undef($o->pob(), "${n}->pob()");

    is_deeply($o->_unparsed(), { map {$_ => {} } (1 .. 2) }, "${n}->_unparsed()");
    if (0) { diag Dumper($o->_unparsed()); }

    return;
}

sub check_Actor_Stub {
    my $o = shift;
    my $n = shift;
    my @n;

    isa_ok($o, "WebService::Flixster::Actor::Stub", $n);
    ok($o->id(), "${n}->id()");
    # TODO:
    if (defined $o->character(1)) { ok($o->character(1), "${n}->character(1)"); }
    if (defined $o->name(1)) { ok($o->name(1), "${n}->name(1)"); }
    if (defined $o->photo(1)) { ok($o->photo(1), "${n}->photo(1)"); }

    push @n, ["Actor", 'id' => $o->id()];

    if (0) {
	check_Actor($o, "${n}");
	check_Actor($o, "${n}->obj()");
	is($o->id(), $o->obj()->id(), "${n}->id() == ${n}->obj()->id()");
    }

    return @n;
}

sub check_Currency {
    my $o = shift;
    my $n = shift;

    isa_ok($o, "Math::Currency", $n);

    return;
}

sub check_Date {
    my $o = shift;
    my $n = shift;

    isa_ok($o, "DateTime::Incomplete", $n);

    return;
}

sub check_Director {
    my $o = shift;
    my $n = shift;
    my @n;

    isa_ok($o, "WebService::Flixster::Director", $n);
    if (defined $o->photo()) { check_Photo($o->photo(), "${n}->photo()"); }
    ok($o->name(), "${n}->name()");
    ok($o->id(), "${n}->id()");
    # TODO: photo will become a full object, and there may be a linked Actor entity from id.

    return @n;
}

sub check_Movie {
    my $o = shift;
    my $n = shift;
    my @n;

    isa_ok($o, "WebService::Flixster::Movie", $n);

    ok($o->id(), "${n}->id()");

    isa_ok($o->actors(), "ARRAY", "${n}->actors()");
    foreach (@{$o->actors()}) {
	push @n, check_Actor_Stub($_, "${n}->actors()->[]");
    }

    if (defined $o->boxOffice()) { check_Currency($o->boxOffice(), "${n}->boxOffice()"); }

    check_Date($o->dvdReleaseDate(), "${n}->dvdReleaseDate()");

    isa_ok($o->directors(), "ARRAY", "${n}->directors()");
    foreach (@{$o->directors()}) {
	push @n, check_Director($_, "${n}->directors()->[]");
    }

    ok($o->mpaa(), "${n}->mpaa()");

    isa_ok($o->photos(), "ARRAY", "${n}->photos()");
    foreach (@{$o->photos()}) {
	check_Photo($_, "${n}->photos()->[]");
    }

    ok_bool($o->playing(), "${n}->playing()");

    check_Poster($o->poster(), "${n}->poster()");

    isa_ok($o->products(), "ARRAY", "${n}->products()");
    foreach (@{$o->products()}) {
	check_URL($_, "${n}->products()->[]");
    }

    check_Reviews($o->reviews(), "${n}->reviews()");

    check_RunningTime($o->runningTime(), "${n}->runningTime()");

    ok($o->status(), "${n}->status()");

    ok($o->synopsis(), "${n}->synopsis()");

    isa_ok($o->tags(), "ARRAY", "${n}->tags()");
    foreach (@{$o->tags()}) {
	ok($_, "${n}->tags()->[]");
    }

    check_Date($o->theaterReleaseDate(), "${n}->theaterReleaseDate()");

    ok($o->thumbnail(), "${n}->thumbnail");
    ok($o->title(), "${n}->title()");

    check_Trailer($o->trailer(), "${n}->trailer()");

    ok($o->url(), "${n}->url()");

    isa_ok($o->urls(), "ARRAY", "${n}->urls()");
    foreach (@{$o->urls()}) {
	ok($_, "${n}->urls()->[]");
    }

    is_deeply($o->_unparsed(), { map {$_ => {} } (1 .. 3) }, "${n}->_unparsed()");
    if (0) { diag Dumper($o->_unparsed()); }

    return @n;
}

sub check_Movie_Stub {
    my $o = shift;
    my $n = shift;
    my @n;

    isa_ok($o, "WebService::Flixster::Movie::Stub", $n);
    ok($o->id(), "${n}->id()");

    push @n, ["Movie", 'id' => $o->id()];

    if (0) {
	check_Movie($o, "${n}");
	check_Movie($o, "${n}->obj()");
	is($o->id(), $o->obj()->id(), "${n}->id() == ${n}->obj()->id()");
    }

    return @n;
}

sub check_Photo {
    my $o = shift;
    my $n = shift;

    isa_ok($o, "WebService::Flixster::Photo", $n);
    ok_or_undef($o->lthumbnail(), "${n}->lthumbnail()");
    ok_or_undef($o->thumbnail(), "${n}->thumbnail()");
    ok_or_undef($o->type(), "${n}->type()");
    ok_or_undef($o->url(), "${n}->url()");
    ok($o->lthumbnail() || $o->thumbnail() || $o->url(), "${n}->lthumbnail() || ${n}->thumbnail() || ${n}->url()");

    return;
}

sub check_Poster {
    my $o = shift;
    my $n = shift;

    isa_ok($o, "WebService::Flixster::Poster", $n);
    ok($o->detailed(), "${n}->detailed()");
    ok($o->original(), "${n}->original()");
    ok($o->profile(), "${n}->profile()");
    ok($o->thumbnail(), "${n}->thumbnail()");

    return;
}

sub check_Reviews {
    my $o = shift;
    my $n = shift;

    isa_ok($o, "WebService::Flixster::Reviews", $n);
    #TODO:
    $o->critics();
    $o->flixster();
    $o->recent();
    $o->rottenTomatoes();

    return;
}

sub check_RunningTime {
    my $o = shift;
    my $n = shift;

    isa_ok($o, "DateTime::Duration", $n);

    return;
}

sub check_Trailer {
    my $o = shift;
    my $n = shift;

    isa_ok($o, "WebService::Flixster::Trailer", $n);
    ok_or_undef($o->high(), "${n}->high()");
    ok_or_undef($o->iPhone(), "${n}->iPhone()");
    ok_or_undef($o->low(), "${n}->low()");
    ok_or_undef($o->wifi(), "${n}->wifi()");

    return;
}

sub check_URL {
    my $o = shift;
    my $n = shift;

    isa_ok($o, "WebService::Flixster::URL", $n);
    ok_or_undef($o->type(), "${n}->type()");
    ok_or_undef($o->url(), "${n}->url()");

    return;
}


sub ok_or_undef {
    my $o = shift;
    my $n = shift;

    return ok(!defined $o || $o, $n);

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
