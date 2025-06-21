#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use WWW::Noss::BaseConfig;
use WWW::Noss::FeedConfig;
use WWW::Noss::GroupConfig;

my %BASE_PARAM = (
	limit           => 100,
	respect_skip    => 1,
	include_title   => [ qw(1 2 3) ],
	exclude_title   => [ qw(4 5 6) ],
	include_content => [ qw(7 8 9) ],
	exclude_content => [ qw(10 11 12) ],
	include_tags    => [ qw(13 14 15) ],
	exclude_tags    => [ qw(16 17 18) ],
	autoread        => 1,
	default_update  => 0,
	hidden          => 1,
);

my $DEFAULT = WWW::Noss::GroupConfig->new(
	name            => ':ALL',
	limit           => 50,
	respect_skip    => 0,
	include_title   => [ qw(-1) ],
	exclude_title   => [ qw(0)  ],
	include_content => [ qw(-1) ],
	exclude_content => [ qw(0)  ],
	include_tags    => [ qw(-1) ],
	exclude_tags    => [ qw(0)  ],
	autoread        => 1,
	default_update  => 0,
	hidden          => 1,
);

sub base_ok {

	my ($base) = @_;

	isa_ok($base, 'WWW::Noss::BaseConfig');

	is($base->limit, 100, 'limit ok');
	ok($base->respect_skip, 'respect_skip ok');

	is_deeply($base->include_title,   [ qw(1  2  3 ) ], 'include_title ok');
	is_deeply($base->exclude_title,   [ qw(4  5  6 ) ], 'exclude_title ok');
	is_deeply($base->include_content, [ qw(7  8  9 ) ], 'include_content ok');
	is_deeply($base->exclude_content, [ qw(10 11 12) ], 'exclude_content ok');
	is_deeply($base->include_tags,    [ qw(13 14 15) ], 'include_tags ok');
	is_deeply($base->exclude_tags,    [ qw(16 17 18) ], 'exclude_tags ok');

	ok( $base->title_ok('123' ), 'title_ok ok');
	ok(!$base->title_ok('1234'), 'title_ok ok');

	ok( $base->content_ok('789'  ), 'content_ok ok');
	ok(!$base->content_ok('78910'), 'content_ok ok');

	ok( $base->tags_ok([ qw(13 14 15)    ] ), 'tags_ok ok');
	ok(!$base->tags_ok([ qw(13 14 15 16) ] ), 'tags_ok ok');

	ok($base->autoread, 'autoread ok');

	ok(!$base->default_update, 'default_update ok');

	ok($base->hidden, 'hidden ok');

}

subtest 'BaseConfig ok' => sub {

	my $o = WWW::Noss::BaseConfig->new(
		%BASE_PARAM
	);

	base_ok($o);

};

subtest 'GroupConfig ok' => sub {

	my $o = WWW::Noss::GroupConfig->new(
		name => 'Group_Name',
		feeds => [ qw(feed1 feed2 feed3) ],
		%BASE_PARAM
	);

	isa_ok($o, 'WWW::Noss::GroupConfig');

	is($o->name, 'Group_Name', 'name ok');
	is_deeply($o->feeds, [ qw(feed1 feed2 feed3) ], 'feeds ok');

	for my $f (qw(feed1 feed2 feed3)) {
		ok($o->has_feed($f), 'has_feed ok');
	}

	base_ok($o);

};

subtest 'FeedConfig ok' => sub {

	my $o = WWW::Noss::FeedConfig->new(
		name => 'Feed_Name',
		feed => 'https://feed.rss',
		path => 'feed.xml',
		etag => 'feed.etag',
		default => $DEFAULT,
		groups => [
			WWW::Noss::GroupConfig->new(
				name => 'g1',
				feeds => [ 'Feed_Name' ],
				limit => 1,
				respect_skip => 1,
				include_title => [ 1 ],
				exclude_title => [ 2 ],
				include_content => [ 1 ],
				exclude_content => [ 2 ],
				include_tags => [ 1 ],
				exclude_tags => [ 2 ],
				autoread => 1,
				default_update => 1,
				hidden => 1,
			),
			WWW::Noss::GroupConfig->new(
				name => 'g2',
				feeds => [ 'Feed_Name' ],
				limit => 2,
				respect_skip => 0,
				include_title => [ 3 ],
				exclude_title => [ 4 ],
				include_content => [ 3 ],
				exclude_content => [ 4 ],
				include_tags => [ 3 ],
				exclude_tags => [ 4 ],
				autoread => 0,
				default_update => 0,
				hidden => 0,
			),
			WWW::Noss::GroupConfig->new(
				name => 'g3',
				feeds => [ 'Feed_Name' ],
				limit => 3,
				respect_skip => 0,
				include_title => [ 5 ],
				exclude_title => [ 6 ],
				include_content => [ 5 ],
				exclude_content => [ 6 ],
				include_tags => [ 5 ],
				exclude_tags => [ 6 ],
				autoread => 0,
				default_update => 0,
				hidden => 0,
			),
		],
		limit => 4,
		include_title => [ 7 ],
		exclude_title => [ 8 ],
		include_content => [ 7 ],
		exclude_content => [ 8 ],
		include_tags => [ 7 ],
		exclude_tags => [ 8 ],
		autoread => 0,
		default_update => 1,
		hidden => 1,
	);

	isa_ok($o, 'WWW::Noss::FeedConfig');

	is($o->name, 'Feed_Name', 'name ok');
	is($o->feed, 'https://feed.rss', 'feed ok');

	is(@{ $o->groups }, 3, 'groups ok');
	for my $g (qw(g1 g2 g3)) {
		ok($o->has_group($g), 'has_group ok');
	}

	is($o->path, 'feed.xml',  'path ok');
	is($o->etag, 'feed.etag', 'etag ok');

	is($o->limit, 4, 'limit ok');

	ok($o->respect_skip, 'respect_skip ok');

	is_deeply(
		$o->include_title,
		[ -1, 1, 3, 5 , 7 ],
		'include_title ok'
	);
	is_deeply(
		$o->exclude_title,
		[ 0, 2, 4, 6, 8 ],
		'exclude_title ok'
	);
	is_deeply(
		$o->include_content,
		[ -1, 1, 3, 5, 7 ],
		'include_content ok'
	);
	is_deeply(
		$o->exclude_content,
		[ 0, 2, 4, 6, 8 ],
		'exlucde_content ok'
	);
	is_deeply(
		$o->include_tags,
		[ -1, 1, 3, 5, 7 ],
		'include_tags ok'
	);
	is_deeply(
		$o->exclude_tags,
		[ 0, 2, 4, 6, 8 ],
		'exclude_tags ok'
	);

	ok(!$o->autoread, 'autoread ok');

	ok($o->default_update, 'default_update ok');

	ok($o->hidden, 'hidden ok');

};

done_testing;

# vim: expandtab shiftwidth=4
