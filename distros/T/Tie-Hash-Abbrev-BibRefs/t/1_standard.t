#!/usr/bin/perl -Tw

use strict;
use Test::More;

BEGIN { plan tests => 3 }

use constant MODULE => 'Tie::Hash::Abbrev::BibRefs';

BEGIN { use_ok MODULE }

my $tied = tie my(%hash), MODULE;
isa_ok $tied, MODULE, '$tied';
isa_ok tied %hash, MODULE, 'tied %hash';
