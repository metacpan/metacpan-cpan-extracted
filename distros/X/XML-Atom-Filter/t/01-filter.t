#!/usr/bin/perl -w

use Test::More tests => 4;

use lib './lib';
use XML::Atom::Filter;


diag('Subclass invoked with class methods');
{
	package TestFilter;

	use base qw( XML::Atom::Filter );

	sub pre {
		my ($class, $feed) = @_;
		Test::More::isa_ok($feed, XML::Atom::Feed, 'Preprocessing an XML::Atom::Feed');
	}

	sub entry {
		my ($class, $entry) = @_;
		Test::More::isa_ok($entry, XML::Atom::Entry, 'Processing an XML::Atom::Entry');
		Test::More::is($entry->id, 'http://www.example.com/2005/04/07/example', 'Processed entry has correct id');
		$entry;
	}

	sub post {
		my ($class, $feed) = @_;
		Test::More::isa_ok($feed, XML::Atom::Feed, 'Postprocessing an XML::Atom::Feed');
	}


	package main;

	open my $fh, '<', 't/example.xml';
	TestFilter->filter($fh);
	close $fh;
};

