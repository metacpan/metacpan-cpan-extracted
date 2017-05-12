#!/usr/bin/env perl

use lib::abs '../lib';
use XML::Declare;

	my $doc = doc {
		element feed => sub {
			attr xmlns => 'http://www.w3.org/2005/Atom';
			comment "generated using XML::Declare v$XML::Declare::VERSION";
			for (1..3) {
				element entry => sub {
					element title     => 'Title', type => 'text';
					element content   => sub {
						attr type => 'text';
						cdata 'Desc';
					};
					element published => '123123-1231-123-123';
					element author => sub {
						element name => 'Mons';
					}
				};
			}
		};
	} '1.0','utf-8';

	print $doc;
