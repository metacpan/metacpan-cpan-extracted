#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use WQS::SPARQL;
use WQS::SPARQL::Query::Count;

if (@ARGV < 1) {
        print STDERR "Usage: $0 ccnb\n";
        exit 1;
}
my $ccnb = $ARGV[0];

my $q = WQS::SPARQL->new;
my $sparql = WQS::SPARQL::Query::Count->new->count_simple('P3184',
        $ccnb);
my $ret_hr = $q->query($sparql);

# Dump structure to output.
p $ret_hr;

# Output for cnb002826100:
# \ {
#     head      {
#         vars   [
#             [0] "count"
#         ]
#     },
#     results   {
#         bindings   [
#             [0] {
#                 count   {
#                     datatype   "http://www.w3.org/2001/XMLSchema#integer",
#                     type       "literal",
#                     value      1
#                 }
#             }
#         ]
#     }
# }