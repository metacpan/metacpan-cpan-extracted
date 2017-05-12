#!/usr/bin/perl -w
use strict;

use Test::More tests => 2;
use WWW::Mechanize::Link;

BEGIN {
  # Choose a nonannoying HTML displayer:
  $ENV{PERL_HTML_DISPLAY_CLASS} = 'HTML::Display::Dump';
  # Disable all ReadLine functionality
  $ENV{PERL_RL} = 0;
  use_ok('WWW::Mechanize::Shell');
};


my $s = WWW::Mechanize::Shell->new( 'test', rcfile => undef, warnings => undef );

# Now test
{ no warnings 'redefine';
	local *WWW::Mechanize::find_all_links = sub {
			return (WWW::Mechanize::Link->new("","foo","",""),WWW::Mechanize::Link->new("","bar","","")) };
	my @comps = $s->comp_open("fo","fo",0);
	is_deeply(\@comps,["foo"],"Completion works");
};


