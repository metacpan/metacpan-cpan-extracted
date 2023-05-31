#!/usr/bin/env perl

use strict;
use warnings;

package Foo;

use base qw(Wikidata::Reconcilation);

use WQS::SPARQL;
use WQS::SPARQL::Query::Select;

sub _reconcile {
        my ($self, $reconcilation_rules_hr) = @_;

        # Reconcilation process.
        my @sparql;
        if (exists $reconcilation_rules_hr->{'identifiers'}->{'given_name_qids'}
                && exists $reconcilation_rules_hr->{'identifiers'}->{'surname_qid'}) {

                my $sparql = <<'END';
SELECT ?item WHERE {
  ?item wdt:P31 wd:Q5.
END
                foreach my $given_name_qid (@{$reconcilation_rules_hr->{'identifiers'}->{'given_name_qids'}}) {
                        $sparql .= '  ?item wdt:P735 wd:'.$given_name_qid.".\n";
                }
                $sparql .= '  ?item wdt:P734 wd:'.
                        $reconcilation_rules_hr->{'identifiers'}->{'surname_qid'}.".\n";
                $sparql .= "}\n";
                push @sparql, $sparql;
        } elsif (exists $reconcilation_rules_hr->{'identifiers'}->{'surname_qid'}) {
                push @sparql, WQS::SPARQL::Query::Select->new->select_value({
                        'P31' => 'Q5',
                        'P734' => $reconcilation_rules_hr->{'identifiers'}->{'surname_qid'},
                });
        }

        return @sparql;
}

package main;

# Object.
my $obj = Foo->new('verbose' => 1);

# Save cached value.
my @qids = $obj->reconcile({
        'identifiers' => {
                 'given_name_qids' => ['Q18563993', 'Q15730712'], # 'Michal', 'Josef'
                 'surname_qid' => 'Q16883641', # 'Špaček'
        },
});

# Output is defined by 'verbose' => 1

# Output like:
# SPARQL queries:
# SELECT ?item WHERE {
#   ?item wdt:P31 wd:Q5.
#   ?item wdt:P735 wd:Q18563993.
#   ?item wdt:P735 wd:Q15730712.
#   ?item wdt:P734 wd:Q16883641.
# }
# 
# {
#     head      {
#         vars   [
#             [0] "item"
#         ]
#     },
#     results   {
#         bindings   [
#             [0] {
#                     item   {
#                         type    "uri",
#                         value   "http://www.wikidata.org/entity/Q27954834"
#                     }
#                 }
#         ]
#     }
# }
# Results:
# - Q27954834: 1