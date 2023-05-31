#!/usr/bin/env perl

use strict;
use warnings;

use WQS::SPARQL::Result;

my $result_hr = {
        'head' => {
                'vars' => ['item'],
        },
        'results' => {
                'bindings' => [{
                        'item' => {
                                'type' => 'uri',
                                'value' => 'http://www.wikidata.org/entity/Q27954834',
                        },
                }],
        },
};

my $obj = WQS::SPARQL::Result->new;
my @ret = $obj->result($result_hr, ['item']);

# Dump out.
foreach my $ret_hr (@ret) {
        print "{\n";
        foreach my $key (keys %{$ret_hr}) {
                print "  $key => ".$ret_hr->{$key}.",\n";
        }
        print "},\n";
}

# Output:
# {
#   item => Q27954834,
# },