#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Spec;
use File::Temp qw(tempfile);

use WWW::Noss::FeedConfig;

use WWW::Noss::DB;

my $DB = do {
	my ($h, $p) = tempfile(UNLINK => 1);
	close $h;
	$p;
};

my $obj = WWW::Noss::DB->new($DB);

isa_ok($obj, 'WWW::Noss::DB');

is(
	$obj->load_feed(
		WWW::Noss::FeedConfig->new(
			name => 'atom',
			feed => 'https://phonysite.com',
			path => File::Spec->catfile(qw/t data atom.xml/),
		)
	),
	5,
	'loaded atom feed ok'
);

is(
	$obj->load_feed(
		WWW::Noss::FeedConfig->new(
			name => 'rss',
			feed => 'https://phonysite.com',
			path => File::Spec->catfile(qw/t data rss.xml/),
		)
	),
	3,
	'loaded rss feed ok'
);

subtest 'has_feed ok' => sub {
	ok($obj->has_feed('atom'), 'has_feed ok');
	ok($obj->has_feed('rss'),  'has_feed ok');
};

is_deeply(
	$obj->feed('atom', post_info => 1),
	{
		nossname    => 'atom',
		nosslink    => 'https://phonysite.com',
		title       => 'Test Atom Feed',
		link        => 'https://phonysite.com',
		description => 'An Atom feed for testing purposes',
		updated     => 1750010821,
		author      => 'samyoung12788 at gmail dot com (Samuel Young)',
		category    => [ qw(test sample phony) ],
		generator   => 'VIM 9.0',
		image       => '/logo.png',
		rights      => 'Copyright (C) 2025 Samuel Young (samyoung12788 at gmail dot com)',
		skiphours   => [],
		skipdays    => [],
		posts       => 5,
		unread      => 5,
	},
	'feed method ok'
);

is(scalar $obj->feeds, 2, 'feeds ok');

is_deeply(
	$obj->post('atom', 1),
	{
		nossid    => 1,
		status    => 'unread',
		feed      => 'atom',
		title     => 'Test post #1',
		link      => 'https://phonysite.com/a1',
		author    => 'samyoung12788 at gmail dot com (Samuel Young)',
		category  => [ qw(test sample phony) ],
		summary   => "<p>Just a plain-text post.</p>\n",
		published => 1750011361,
		updated   => 1750011361,
		uid       => 'a1',
	},
	'post ok'
);

ok($obj->first_unread('atom'), 'first_unread ok');

subtest 'largest_id ok' => sub {

	is($obj->largest_id, 5, 'largest_id with no feeds ok');
	is($obj->largest_id('rss'), 3, 'largest_id with feed ok');

};

subtest 'mark ok' => sub {

	is(
		$obj->mark('read', 'atom', 1, 2, 3),
		3,
		'mark ok'
	);

	is($obj->post('atom', 1)->{ status }, 'read',   'mark ok');
	is($obj->post('atom', 2)->{ status }, 'read',   'mark ok');
	is($obj->post('atom', 3)->{ status }, 'read',   'mark ok');
	is($obj->post('atom', 4)->{ status }, 'unread', 'mark ok');

	is(
		$obj->mark('unread', 'atom'),
		5,
		'mark ok'
	);

	is($obj->post('atom', 1)->{ status }, 'unread', 'mark ok');
	is($obj->post('atom', 2)->{ status }, 'unread', 'mark ok');
	is($obj->post('atom', 3)->{ status }, 'unread', 'mark ok');
	is($obj->post('atom', 4)->{ status }, 'unread', 'mark ok');

	$obj->mark('read', 'atom');

};

subtest 'look ok' => sub {

	is(
		$obj->look(),
		8,
		'no parameters ok'
	);

	is(
		$obj->look(title => qr/1/),
		2,
		'title ok'
	);

	is(
		$obj->look(feeds => [ qw(atom) ]),
		5,
		'feeds ok'
	);

	is(
		$obj->look(status => 'read'),
		5,
		'status ok'
	);

	is(
		$obj->look(tags => [ qw(test sample phony) ]),
		8,
		'tags ok'
	);

	is(
		$obj->look(content => [ qr/text/ ]),
		4,
		'content ok'
	);

	is(
		($obj->look(order => 'feed'))[0]->{ uid },
		'a1',
		'order by feed ok'
	);

	is(
		($obj->look(order => 'title'))[0]->{ uid },
		'a1',
		'order by title ok'
	);

	is(
		($obj->look(order => 'date'))[0]->{ uid },
		'a1',
		'order by date ok'
	);

	is(
		($obj->look(reverse => 1))[0]->{ uid },
		'r3',
		'reverse ok'
	);

	my $ids;

	is(
		$obj->look(callback => sub { $ids .= $_[0]->{ nossid } }),
		8,
		'look(callback => ...) return code ok'
	);

	is($ids, '12345123', 'look callback ok');

};

ok($obj->commit, 'commit ok');
ok($obj->vacuum, 'vacuum ok');
$obj->commit;

ok($obj->finish, 'finish ok');

subtest 'reading existing database ok' => sub {

	$obj = WWW::Noss::DB->new($DB);

	isa_ok($obj, 'WWW::Noss::DB');

	is($obj->look, 8,  'posts ok');
	is($obj->feeds, 2, 'feeds ok');

	$obj->finish;

};

done_testing;

# vim: expandtab shiftwidth=4
