#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Spec;
use File::Temp qw(tempfile);

use WWW::Noss::OPML;

my $OPML = File::Spec->catfile(qw/t data opml.xml/);

subtest 'from_perl ok' => sub {

	my @test_feeds = (
		{
			title    => 'Feed #1',
			xml_url  => 'https://phonysite.com/feed1.rss',
			text     => 'Text #1',
			html_url => 'https://phonysite.com/feed1.html',
			groups   => [ qw(a) ],
		},
		{
			title    => 'Feed #2',
			xml_url  => 'https://phonysite.com/feed2.rss',
			text     => 'Text #2',
			html_url => 'https://phonysite.com/feed2.html',
			groups   => [ qw(a b) ],
		},
		{
			title    => 'Feed #3',
			xml_url  => 'https://phonysite.com/feed3.rss',
			text     => 'Text #3',
			html_url => 'https://phonysite.com/feed3.html',
			groups   => [ qw(a b c) ],
		},
	);

	my $obj = WWW::Noss::OPML->from_perl(
		title => 'Test OPML',
		feeds => \@test_feeds,
	);

	isa_ok($obj, 'WWW::Noss::OPML');

	is($obj->title, 'Test OPML', 'title ok');

	is_deeply($obj->feeds, \@test_feeds, 'feeds ok');

};

subtest 'from_xml ok' => sub {

	my $obj = WWW::Noss::OPML->from_xml($OPML);

	isa_ok($obj, 'WWW::Noss::OPML');

	is($obj->title, 'Test feed list', 'title ok');

	is_deeply(
		$obj->feeds,
		[
			{
				title    => 'Feed1',
				xml_url  => 'https://phonysite.com/f1.xml',
				text     => 'Feed1',
				html_url => undef,
				groups   => [ qw(Folder1) ],
			},
			{
				title    => 'Feed2',
				xml_url  => 'https://phonysite.com/f2.xml',
				text     => 'Feed2',
				html_url => undef,
				groups   => [ qw(Folder1) ],
			},
			{
				title    => 'Feed3',
				xml_url  => 'https://phonysite.com/f3.xml',
				text     => 'Feed3',
				html_url => undef,
				groups   => [ qw(Folder2) ],
			},
			{
				title    => 'Feed4',
				xml_url  => 'https://phonysite.com/f4.xml',
				text     => 'Feed4',
				html_url => undef,
				groups   => [ qw(Folder2) ],
			},
		],
		'feeds ok'
	);

};

subtest 'to_xml ok' => sub {

	my $obj = WWW::Noss::OPML->from_xml($OPML);

	my $temp = do {
		my ($h, $p) = tempfile(UNLINK => 1);
		close $h;
		$p;
	};

	ok($obj->to_file($temp), 'to_file ok');
	ok(eval { WWW::Noss::OPML->from_xml($temp) }, 'to_file creates valid OPML');

	like($obj->to_xml, qr/type="folder"/, 'to_xml creates folders');
	unlike($obj->to_xml(folders => 0), qr/type="folder"/, 'to_xml can not create folders');

};

done_testing;

# vim: expandtab shiftwidth=4
