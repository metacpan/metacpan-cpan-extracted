#!/usr/bin/perl -w
use strict;
use Test::More tests => 11;

use Voting::Condorcet::RankedPairs;

my $rp = Voting::Condorcet::RankedPairs->new;

eval { $rp->add("Foo","Bar"); };
ok($@,"Number of arguments test");

eval { $rp->add("Foo","Bar",-0.5); };
ok($@, "Negative strength test");

eval { $rp->add("Foo","Bar",1.5); };
ok($@, "Super strengtht test");

eval { $rp->add("Foo","Bar",1.0); };	# Shouldn't die.
ok(! $@, "Full strength test");	

eval { $rp->add("Bar","Baz",0.0); };	# Shouldn't die.
ok(! $@, "No strength test");	

eval { $rp->winner; 1; };
ok($@, "Void context: winner");

eval { $rp->strict_winners; 1; };
ok($@, "Void context: strict_winners");

eval { $rp->better_than("Foo"); 1; };
ok($@, "Void context: better_than");

eval { $rp->worse_than("Foo"); 1; };
ok($@, "Void context: worse_than");

eval { $rp->rankings(); 1; };
ok($@, "Void context: rankings");

eval { $rp->strict_rankings(); 1; };
ok($@, "Void context: strict_rankings");
