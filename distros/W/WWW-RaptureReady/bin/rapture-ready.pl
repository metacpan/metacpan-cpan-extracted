#!/usr/bin/env perl

use strict;
use WWW::RaptureReady 0.2;

my $rr = WWW::RaptureReady->new;
print "URL:           ", $rr->url,     "\n",
      "Current Index: ", $rr->index,   "\n",
      "Index Change:  ", $rr->change,  "\n",
      "Last Updated:  ", $rr->updated, "\n";
exit;

