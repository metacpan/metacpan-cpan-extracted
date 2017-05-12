#!/usr/bin/perl

use XML::Atom::OWL;
use RDF::TrineShortcuts;

my $p = XML::Atom::OWL->new(undef, 'http://identi.ca/api/statuses/user_timeline/36737.atom');
print rdf_string($p->graph => 'Turtle');
