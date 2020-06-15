#!/usr/bin/env perl
use strict;
use warnings;
use Tickit::DSL;
use Eval::WithLexicals;
use Try::Tiny;
use Data::Dumper;
my $eval = Eval::WithLexicals->with_plugins(
	"HintPersistence"
)->new(
	context => 'scalar',
);
vbox {
	my $scroller;
	widget {
		$scroller = scroller { };
	} expand => 1;
	entry {
		my ($self, $data) = @_;
		widget { scroller_text $data } parent => $scroller;
		try {
			my ($rslt) = $eval->eval($data);
			my $output = do {
				no warnings 'once';
				local $Data::Dumper::Terse = 1;
				local $Data::Dumper::Indent = 1;
				local $Data::Dumper::Useqq = 1;
				local $Data::Dumper::Deparse = 1;
				local $Data::Dumper::Sortkeys = 1;
				local $Data::Dumper::QuoteKeys = 0;
				Dumper($rslt)
			};
			widget { scroller_text $output } parent => $scroller
		} catch {
			my $err = $_;
			widget { scroller_text "Error: $err" } parent => $scroller
		}
	};
};
tickit->run;
