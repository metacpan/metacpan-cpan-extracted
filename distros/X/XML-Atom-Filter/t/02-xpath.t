#!/usr/bin/perl -w

use Test::More tests => 7;
use IO::Handle;

use lib './lib';

use XML::Atom::Filter;


# Have XML::Atom use XML::XPath, not XML::LibXML
BEGIN {
	if(eval { require XML::XPath; }) {
		no warnings 'redefine';
		*XML::Atom::LIBXML = sub() { 0; };
	} else {
		SKIP: { skip('No XML::XPath', 7); };
		exit;
	};
};
ok(!XML::Atom::LIBXML, 'Loaded XML::Atom in XML::XPath mode');


diag('Subclass invoked with class methods');
{
	package TestFilter;

	use base qw( XML::Atom::Filter );

	sub pre {
		my ($class, $feed) = @_;
		Test::More::isa_ok($feed, XML::Atom::Feed, 'Preprocessing an XML::Atom::Feed');
		$class->{__entry_count} = scalar($feed->entries);
		$class->{__feed} = $feed;
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
		Test::More::is($class->{__feed}, $feed, 'Got the same XML::Atom::Feed as I preprocessed');
		Test::More::is(scalar($feed->entries), $class->{__entry_count}, 'Had the same number of entries before as after');
	}


	package main;

	open my $fh, '<', 't/example.xml';
	TestFilter->filter($fh);
	close $fh;
};

