#!/usr/local/bin/perl

# Mark Wilkinson wrote this lovely little TK browser for GO

BEGIN {
    if (defined($ENV{GO_ROOT})) {
	use lib "$ENV{GO_ROOT}/perl-api";
    }
}

use strict;
use Carp;
use Tk;
use Tk::Label;
use Tk::Tree;
use Tk::ItemStyle;
use GO::AppHandle;

#my $leaf = ItemStyle->new(-foreground => "green");
#my $branch = ItemStyle->new(-foreground => "red");

sub usage {
    print "Usage: tkbrowser.pl [-d database name] [-h mysql host]\n";
    print "  e.g: tkbrowser.pl -d go -h sin.lbl.gov\n";
}

my $apph;	
eval {
    $apph = GO::AppHandle->connect(\@ARGV);
};
if ($@) {
    usage();
    exit 1;
}
	
my $fullroots = $apph->get_root_term;
my $hlist;
	
my $mw = MainWindow->new();
my $def_text = $mw->Scrolled("Text", -height => 3, -scrollbars => "s", -background => "darkblue", -foreground => "white");
	
$mw->ItemStyle('text', -stylename => 'leaf', -foreground => "darkgreen", -background => "white");
$mw->ItemStyle('text', -stylename => 'branch', -foreground => "red", -background => "white");
$hlist = $mw->Scrolled('Tree', 
                       -itemtype   => 'text',
                       -separator  => '|',
                       -selectmode => 'single',
                       -indicator => 1,
                       -height => 30,
                       -width => 70,
                       -background => "white",
                       -browsecmd => \&browsed, 
                       -opencmd  => \&clickedOpen,			
                      );
	
foreach (($fullroots)) {
    my $label = $_->name;
    $hlist->add($_->name, -text=>$label );
    $hlist->setmode($_->name, "close");
}

my $graph = $apph->get_graph_by_terms(-terms=>[$fullroots], -depth=>1, -template => {acc=>1, name=>1});

AddTreeNode($apph, $hlist, $graph);

$def_text->pack(-side => 'bottom', -fill => 'x');
$hlist->pack(-side => 'top', -expand => 1, -fill => "both");
	
MainLoop;

sub AddTreeNode {
    my ($apph, $hlist, $graph) = @_;
	
    my $leaf_terms = $graph->get_leaf_nodes;
    foreach my $term (@{$leaf_terms}) {
        my $children = $graph->n_children($term->acc);
        my $paths = $graph->paths_to_top($term->acc);
        foreach my $path (@{$paths}) {
            &_addPathToTree($apph, $hlist, $path, $term, $children);
        }
    }


}	

sub browsed {
    my ($path) = @_;
    return unless $path;
    my $name = ($path =~ /.*\|(.*)$/ && $1);
    unless ($name) {
        $path =~ /(Gene\_Ontology)/;
    }
    return unless $name;
    my $term = $apph->get_term({name => $name}, {acc=>1, definition=>1});
    return unless $term;
    $def_text->delete('1.0'	, 'end');
    $def_text->insert('end', ($term->definition));
}

sub clickedOpen {
    my ($path) = @_;
    if ($hlist->info('children', $path)) {
        foreach $path($hlist->info('children', $path)) {
            $hlist->show("entry", $path);
        }
        return;
    }	
    #print "$path\n";
    my $name = ($path =~ /.*\|(.*)$/ && $1);
    my $term = $apph->get_term({name => $name}, "shallow");
    my $graph = $apph->get_graph_by_terms(-terms=>[$term], -depth => 1, -template => {acc=>1, -name => 1});
    AddTreeNode($apph, $hlist, $graph);
}


sub _addPathToTree {
    # takes a $path object and converts it to a string that is
    # readable by the Tree widget (text delimited by |)
    my ($apph, $hlist, $path, $term, $children) = @_;
    my @revpath = reverse @{$path->term_list};
	
    my $termstring;
    foreach my $node (@revpath) {
        $termstring .= $node->name;
        unless ($hlist->info("exists", $termstring)){
            my $count = $apph->get_product_count({term=>$node});
            print "$count " . $node->name . "\n";
            $hlist->add($termstring, -text=>($node->name . " ($count)"));
            #$hlist->setmode($termstring, $oc);
        }
        ;
        $termstring .= "|";
    }
    $termstring .=  $term->name;	
    unless ($hlist->info("exists", $termstring)){
        my $count = $term->n_deep_products; 
        $hlist->add($termstring, -text => (($term->name) . " ($count) "));
        my $openclose = ($children)?"open":"close";
        $hlist->setmode($termstring, $openclose);
        if ($children) {
            $hlist->entryconfigure($termstring, -style=>'leaf')
        } else {
            $hlist->entryconfigure(
                                   $termstring, -style=>'branch');
            $hlist->indicator('delete', $termstring);
        }
        ;
    }
    $hlist->show("entry", $termstring);
}
