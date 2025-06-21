#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Spec;

use WWW::Noss::FeedConfig;
use WWW::Noss::FeedReader qw(read_feed);

my $ATOM = File::Spec->catfile(qw/t data atom.xml/);

my %DEFAULT = (
	name => 'feed',
	feed => 'https://phonysite.com',
	path => $ATOM,
);

subtest 'title filters ok' => sub {

	my $feed = WWW::Noss::FeedConfig->new(
		%DEFAULT,
		include_title => [ qr/Test/, qr/#/, qr/[123]/ ],
	);

	my ($channel, $entries) = read_feed($feed);

	is(scalar @$entries, 3, 'include_title ok');

	$feed = WWW::Noss::FeedConfig->new(
		%DEFAULT,
		exclude_title => [ qr/1/, qr/2/, qr/3/ ],
	);

	($channel, $entries) = read_feed($feed);

	is(scalar @$entries, 2, 'exclude_title ok');

	$feed = WWW::Noss::FeedConfig->new(
		%DEFAULT,
		include_title => [ qr/Test/, qr/#/, qr/[123]/ ],
		exclude_title => [ qr/2/, qr/3/ ],
	);

	($channel, $entries) = read_feed($feed);

	is(scalar @$entries, 1, 'include_title + exclude_title ok');

};

subtest 'content filters ok' => sub {

	my $feed = WWW::Noss::FeedConfig->new(
		%DEFAULT,
		include_content => [ qr/post/i, qr/\s/, qr/HTML/ ],
	);

	my ($channel, $entries) = read_feed($feed);

	is(scalar @$entries, 2, 'include_content ok');

	$feed = WWW::Noss::FeedConfig->new(
		%DEFAULT,
		exclude_content => [ qr/HTML/, qr/<div>/ ]
	);

	($channel, $entries) = read_feed($feed);

	is(scalar @$entries, 2, 'exclude_content ok');

	$feed = WWW::Noss::FeedConfig->new(
		%DEFAULT,
		include_content => [ qr/post/i, qr/with/ ],
		exclude_content => [ qr/HTML/, qr/<div>/ ],
	);

	($channel, $entries) = read_feed($feed);

	is(scalar @$entries, 1, 'include_content + exclude_content ok');

};

subtest 'tag filters ok' => sub {

	my $feed = WWW::Noss::FeedConfig->new(
		%DEFAULT,
		include_tags => [ qw(bonus) ],
	);

	my ($channel, $entries) = read_feed($feed);

	is(scalar @$entries, 1, 'include_tags ok');

	$feed = WWW::Noss::FeedConfig->new(
		%DEFAULT,
		exclude_tags => [ qw(extra bonus) ],
	);

	($channel, $entries) = read_feed($feed);

	is(scalar @$entries, 3, 'exclude_tags ok');

	$feed = WWW::Noss::FeedConfig->new(
		%DEFAULT,
		include_tags => [ qw(sample phony test bonus) ],
		exclude_tags => [ qw(extra) ],
	);

	($channel, $entries) = read_feed($feed);

	is(scalar @$entries, 1, 'include_tags + exclude_tags ok');

};

subtest 'limit ok' => sub {

	my $feed = WWW::Noss::FeedConfig->new(
		%DEFAULT,
		limit => 2,
	);

	my ($channel, $entries) = read_feed($feed);

	is(scalar @$entries, 2, 'limit ok');

};

done_testing;

# vim: expandtab shiftwidth=4
