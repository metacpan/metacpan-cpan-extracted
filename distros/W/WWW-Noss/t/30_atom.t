#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Spec;

use WWW::Noss::FeedConfig;
use WWW::Noss::FeedReader qw(read_feed);

my $ATOM = File::Spec->catfile(qw/t data atom.xml/);

my $feed = WWW::Noss::FeedConfig->new(
	name => 'feed',
	feed => 'https://phonysite.com',
	path => $ATOM,
);

my ($channel, $entries) = read_feed($feed);

subtest 'Atom channel ok' => sub {

	is($channel->{ nossname }, 'feed', 'nossname ok');
	is($channel->{ nosslink }, 'https://phonysite.com', 'nosslink ok');
	is($channel->{ title }, 'Test Atom Feed', 'title ok');
	is($channel->{ link }, 'https://phonysite.com', 'link ok');
	is(
		$channel->{ description },
		'An Atom feed for testing purposes',
		'description ok'
	);
	is($channel->{ updated }, 1750010821, 'updated ok');
	is(
		$channel->{ author },
		'samyoung12788 at gmail dot com (Samuel Young)',
		'author ok'
	);
	is_deeply($channel->{ category }, [ qw(test sample phony) ], 'category ok');
	is($channel->{ generator }, 'VIM 9.0', 'generator ok');
	is($channel->{ image }, '/logo.png', 'image ok');
	is(
		$channel->{ rights },
		'Copyright (C) 2025 Samuel Young (samyoung12788 at gmail dot com)',
		'rights ok'
	);
	is($channel->{ skiphours }, undef, 'skiphours ok');
	is($channel->{ skipdays }, undef, 'skipdays ok');

};

subtest 'Atom entries ok' => sub {

	subtest 'entry 1 ok' => sub {

		my $e = $entries->[0];

		is($e->{ uid }, 'a1', 'uid ok');
		is($e->{ title }, 'Test post #1', 'title ok');
		is($e->{ updated }, 1750011361, 'updated ok');
		is(
			$e->{ author },
			'samyoung12788 at gmail dot com (Samuel Young)',
			'author ok'
		);
		like(
			$e->{ summary },
			qr/<p>Just a plain-text post\.<\/p>/,
			'summary ok'
		);
		is($e->{ link }, 'https://phonysite.com/a1', 'link ok');
		is_deeply($e->{ category }, [ qw(test sample phony) ], 'category ok');
		is($e->{ published }, 1750011361, 'published ok');

	};

	subtest 'entry 2 ok' => sub {

		my $e = $entries->[1];

		is($e->{ uid }, 'a2', 'uid ok');
		is($e->{ title }, 'Test post #2', 'title ok');
		is($e->{ published }, 1750011661, 'published ok');
		is($e->{ updated }, 1750011661, 'updated ok');
		is(
			$e->{ author },
			'samyoung12788 at gmail dot com (Samuel Young)',
			'author ok'
		);
		is($e->{ summary }, '<p>Post with HTML content.</p>', 'content ok');
		is($e->{ link }, 'https://phonysite.com/a2', 'link ok');
		is_deeply($e->{ category }, [ qw(test sample phony) ], 'category ok');

	};

	subtest 'entry 3 ok' => sub {

		my $e = $entries->[2];

		is($e->{ uid }, 'a3', 'uid ok');
		is($e->{ title }, 'Test post #3', 'title ok');
		is($e->{ published }, 1750016941, 'published ok');
		is($e->{ updated }, 1750016941, 'updated ok');
		is(
			$e->{ author },
			'samyoung12788 at gmail dot com (Samuel Young)',
			'author ok'
		);
		is(
			$e->{ summary },
			'<div><p>Post with XHTML content.</p></div>',
			'summary ok'
		);
		is($e->{ link }, 'https://phonysite.com/a3', 'link ok');
		is_deeply($e->{ category }, [ qw(test sample phony) ], 'category ok');

	};

	subtest 'entry 4 ok' => sub {

		my $e = $entries->[3];

		is($e->{ uid }, 'a4', 'uid ok');
		is($e->{ title }, 'Test post #4', 'title ok');
		is($e->{ published }, 1750017241, 'published ok');
		is($e->{ updated }, 1750017241, 'updated ok');
		is(
			$e->{ author },
			'samyoung12788 at gmail dot com (Samuel Young)',
			'author ok'
		);
		is(
			$e->{ summary },
			'<div><p>Post with XML content.</p></div>',
			'summary ok'
		);
		is($e->{ link }, 'https://phonysite.com/a4', 'link ok');
		is_deeply($e->{ category }, [ qw(test sample phony bonus) ], 'category ok');

	};

	subtest 'entry 5 ok' => sub {

		my $e = $entries->[4];

		is($e->{ uid }, 'a5', 'uid ok');
		is($e->{ title }, 'Test post #5', 'title ok');
		is($e->{ published }, 1750017301, 'published ok');
		is($e->{ updated }, 1750017301, 'updated ok');
		is(
			$e->{ author },
			'samyoung12788 at gmail dot com (Samuel Young)',
			'author ok'
		);
		like(
			$e->{ summary },
			qr/<p>Post with some more text content\.<\/p>/,
			'summary ok'
		);
		is($e->{ link }, 'https://phonysite.com/a5', 'link ok');
		is_deeply($e->{ category }, [ qw(test sample phony extra) ], 'category ok');

	};
};

done_testing;

# vim: expandtab shiftwidth=4
