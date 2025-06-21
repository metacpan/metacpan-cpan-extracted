#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Spec;

use WWW::Noss::FeedConfig;
use WWW::Noss::FeedReader qw(read_feed);

my $RSS = File::Spec->catfile(qw/t data rss.xml/);

my $feed = WWW::Noss::FeedConfig->new(
	name => 'feed',
	feed => 'https://phonysite.com',
	path => $RSS,
);

my ($channel, $entries) = read_feed($feed);

subtest 'RSS channel ok' => sub {

	is($channel->{ title }, 'Test RSS Feed', 'title ok');
	is($channel->{ link }, 'https://phonysite.com', 'link ok');
	is(
		$channel->{ description },
		'An RSS feed for testing purposes.',
		'description ok'
	);
	is(
		$channel->{ rights },
		'Copyright (C) 2025 Samuel Young (samyoung12788 at gmail dot com)',
		'rights ok'
	);
	is($channel->{ updated }, 1750017793, 'updated ok');
	is_deeply($channel->{ category }, [ qw(test sample phony) ], 'category ok');
	is($channel->{ generator }, 'VIM 9.0', 'generator ok');
	is($channel->{ image }, '/test.png', 'image ok');
	is_deeply(
		$channel->{ skiphours },
		[ 23, 0, 1, 2, 3, 4 ],
		'skiphours ok'
	);
	is_deeply(
		$channel->{ skipdays },
		[ qw(Saturday Sunday) ],
		'skipdays ok'
	);

};

subtest 'RSS entries ok' => sub {

	subtest 'entry 1 ok' => sub {

		my $e = $entries->[0];

		is($e->{ title }, 'Test post #1', 'title ok');
		is($e->{ link }, 'https://phonysite.com/r1', 'link ok');
		is($e->{ summary }, 'A text description.', 'summary ok');
		is(
			$e->{ author },
			'samyoung12788 at gmail dot com (Samuel Young)',
			'author ok'
		);
		is_deeply($e->{ category }, [ qw(test sample phony) ], 'category ok');
		is($e->{ uid }, 'r1', 'uid ok');
		is($e->{ published }, 1750018340, 'published ok');

	};

	subtest 'entry 2 ok' => sub {

		my $e = $entries->[1];

		is($e->{ title }, 'Test post #2', 'title ok');
		is($e->{ link }, 'https://phonysite.com/r2', 'link ok');
		is($e->{ summary }, '<p>Some HTML text.</p>', 'summary ok');
		is(
			$e->{ author },
			'samyoung12788 at gmail dot com (Samuel Young)',
			'author ok'
		);
		is_deeply($e->{ category }, [ qw(test sample phony) ], 'category ok');
		is($e->{ uid }, 'r2', 'uid ok');
		is($e->{ published }, 1750018393, 'published ok');

	};

	subtest 'entry 3 ok' => sub {

		my $e = $entries->[2];

		is($e->{ title }, 'Test post #3', 'title ok');
		is($e->{ link }, 'https://phonysite.com/r3', 'link ok');
		is($e->{ summary }, '<p>Some more HTML.</p>', 'summary ok');
		is(
			$e->{ author },
			'samyoung12788 at gmail dot com (Samuel Young)',
			'author ok'
		);
		is_deeply($e->{ category }, [ qw(test sample phony) ], 'category ok');
		is($e->{ uid }, 'r3', 'uid ok');
		is($e->{ published }, 1750018557, 'published ok');
	};

};

done_testing;

# vim: expandtab shiftwidth=4
