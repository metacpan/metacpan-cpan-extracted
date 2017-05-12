#!/usr/local/bin/perl -w

use strict;

use GO::AppHandle;  
use GO::IO::XML;
use GO::IO::ObanOwl;

# Get args
$0 =~ /^(.*\/|)([^\/]*)/;
my ($progdir, $progname) = ($1, $2);

my $apph = GO::AppHandle->connect(\@ARGV);
## We love IEAs now.
#$apph->filters({evcodes=>["!IEA"]});

my $user = {person=>'auto'};

my $writer = new GO::IO::ObanOwl;


my $terms = $apph->get_terms('*', {acc=>1});

$writer->start_document(scalar(localtime($apph->timestamp)));
foreach my $term(@{$terms}) {
    next unless $term->acc;
    next unless ($term->acc =~ /GO:/ || $term->acc eq 'all');
    my $graph = $apph->get_node_graph(-acc=>$term->acc, -depth=>0);
    $writer->draw_term(-term=>$graph->get_term($term->acc), 
                       -graph=>$graph,
                       -show_associations=>'yes');
}

$writer->end_document;








