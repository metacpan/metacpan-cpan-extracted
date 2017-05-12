=head1 NAME

Tree::Family - Represent and visualize a family tree.

=cut

=head1 SYNOPSIS

 use Tree::Family;

 my $tree = Tree::Family->new(filename => '/tmp/mytree.dmp');

 my $person = Tree::Family::Person->new(name => 'Fred');
 my $nother = Tree::Family::Person->new(name => 'Wilma');

 $person->spouse($nother);

 $tree->add_person($person);
 $tree->add_person($nother);

 for ($tree->people) {
     print $_->name;
 }

 my $dot_file = $tree->as_dot;

=head1 DESCRIPTION

Use this module to represent spousal and parental relationships
among a group of people, and generate a graphviz "dot"
file to visualize them.

=head1 FUNCTIONS

=cut

package Tree::Family;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1; # makes diffing easier
use warnings;
use strict;
use List::MoreUtils qw(first_index last_index uniq);
use Algorithm::Permute;
use Clone qw(clone);
use YAML::XS qw/Dump Load LoadFile/;

our $VERSION = '0.02';
our $urlBase = 'http://localhost/';
our $GraphHeader = <<'';
graph family { 
edge [ style=solid ];
node [ shape=box style=bold, color="black", fontsize="18", fontname="Times-Roman" ];
ranksep=2.0

our $GraphFooter = <<'';
}

our $bottomInvisibleEdges = ''; # populated and used below.
our $topInvisibleEdges = ''; # populated and used below.

sub debug($) {
     # print STDERR "@_";
}

=head2 new

my $tree = Tree::Family->new(filename => '/tmp/foobarfamily.dmp');

=cut

sub new {
    my ($class,%args) = @_;
    my $filename = $args{filename} or die "missing filename";
    return bless {
        filename => $filename,
    }, $class;
}

sub _init {
    my $self = shift;
    return if exists($self->{people});
    # $self->{people} will be a hash from ids to T:F:Person objects
    if (-e $self->{filename} && -s $self->{filename}) {
        my $filename = $self->{filename};
        $self->{people} = LoadFile $filename;
    } else {
        $self->{people} = {};
    }
    $self->{people} = { map { $_ => $self->{people}{$_}->Toast } keys %{ $self->{people} } };
    die "error reading $self->{filename}, got (".ref($self->{people}).") error: [$!] [$@]" unless ref($self->{people}) eq 'HASH';
}

#
# Assign numeric generations
#
sub _set_generations {
    my $self = shift;
    my %args = @_;
    our $haveSet;
    return if !$args{force} && $haveSet;
    $haveSet = 1;
    Tree::Family::Person->_clear_generations;
    for my $person (values %{ $self->{people} }) {
        next if $person->generation;
        $person->_set_all_generations(100);
    }
}

=head2 write

Write the family tree to a file

$tree->write

=cut

sub write {
    my $self = shift;
    $self->_init;
    $self->_set_generations;
    Tree::Family::Person->_clear_all_partners;
    Tree::Family::Person->_set_all_partners;
    my $filename = $self->{filename};
    my $tmpfile = $filename."-tmp-".$$.time.(rand 1);
    my %write = map { $_ => $self->{people}{$_}->Freeze } keys %{ $self->{people} };
    open FP, ">$tmpfile" or die "Couldn't write to $tmpfile : $!";
    print FP Dump( \%write );
    close FP;
    rename $tmpfile, $filename or die "Couldn't rename $tmpfile to $filename : $!";
    return 1;
}

=head2 add_person

Add a person to the tree

$tree->add_person($joe);

$joe should be a Tree::Family::Person object.

=cut

sub add_person {
    my $self = shift;
    $self->_init;
    my $person = shift;
    $self->{people}{$person->get('id')} = $person;
}

=head2 delete_person

Delete a person

$tree->delete_person($joe)

=cut

sub delete_person {
    my $self = shift;
    $self->_init;
    my $person = shift;
    $person->dad(undef);
    $person->mom(undef);
    $person->spouse(undef);
    for ($person->partners) {
        $person->_delete_partner($_);
    }
    for ($person->kids) {
        $person->delete_kid($_);
    }
    delete $self->{people}->{$person->id};
    $person->_delete_self;
}

=head2 people

Get a list of all the people in the tree

=cut

sub people {
    my $self = shift;
    $self->_init;
    return values %{ $self->{people} };
}

=head2 find

Find a person, specifying keys and values to search for.

$tree->find(id => 'sam');

$tree->find(first_name => 'joe', last_name => 'dimaggio');

=cut

sub find {
    my ($class,%args) = @_;
    shift->_init;
    Tree::Family::Person->find(%args);
}

=head2 min_generation

The numeric smallest generation.

=cut

sub min_generation {
    my $self = shift;
    $self->_init;
    $self->_set_generations;
    Tree::Family::Person->min_generation;
}

=head2 max_generation

The numeric highest generation.

=cut

sub max_generation {
    my $self = shift;
    $self->_init;
    $self->_set_generations;
    Tree::Family::Person->max_generation;
}

=head2 write_dotfile

Write out a .dot file (graphviz format).

$tree->write("output.dot");

=cut

sub write_dotfile {
    my ($self,$filename) = @_;
    die "missing filename" unless $filename;
    my $tmpfile = $filename."-tmp-".$$.time.(rand 1);
    open FP, ">$tmpfile" or die "Couldn't write to $tmpfile : $!";
    print FP $self->as_dot;
    close FP or die "couldn't close FP : $!";
    rename $tmpfile, $filename or die "Couldn't rename $tmpfile to $filename : $!";
    return 1;
}

#
# _add_person_and_all_ascendants
#
# Add a person and all their ascendants to the .dot output
#
sub _add_person_and_all_ascendants {
    my ($class,$person,$person2subgraph,$people_written,$subgraph_written,$all_subgraphs,$person2subgraphpeople) = @_;
    my $output = '';
    die "no person id " if defined($person) && !defined($person->id);
    return $output if $people_written->{$person->id};
    debug "adding person and all ascendants for ".$person->first_name."\n";

    # Find the subgraph containing dad (and hence mom), and then call ourself
    # recursively for every person in that subgraph.
    my $people;
    $people = $person2subgraphpeople->{ $person->mom->id } if $person->mom;
    $people ||= $person2subgraphpeople->{ $person->dad->id } if $person->dad;
    if ($people && @$people) {
        debug "Found subgraph for parents of ".$person->first_name." : ".
            (join ',', map $_->first_name, @$people)."\n" 
    } else {
        debug "No ascendants for ".$person->first_name."\n";
    }
    # annoying dot hacks to untangle the generation above us.
    if ($person->spouse() && 
            ($person->mom && $person->dad) &&
            ($person->spouse->mom && $person->spouse->dad)) {
        # TODO also for partners (not spouse?)
        my $parent_node = _kid_node($person->mom,$person->dad);
        my $edges;
        if (had_kids($person,$person->spouse)) {
            $edges = _kid_node($person,$person->spouse())." -- $parent_node [style=invis];\n";
        } else {
            $edges = $person->id." -- $parent_node [style=invis];\n";
            $edges .= $person->spouse()->id." -- $parent_node [style=invis];\n";
        }

        if ($person->mom->spouse() || $person->dad->spouse()) {
            $bottomInvisibleEdges .= $edges;
        } else {
            $topInvisibleEdges .= $edges;
        }
    }
    
    for (@{ $people || [] }) {
        $output .= $class->_add_person_and_all_ascendants($_,$person2subgraph,$people_written,$subgraph_written,$all_subgraphs,$person2subgraphpeople);
    }
    $output .= $class->_person_node($person)."\n";
    my $subgraph_index = $person2subgraph->{$person->id};
    $output .= $all_subgraphs->[$subgraph_index] unless $subgraph_written->{$subgraph_index};
    $subgraph_written->{$subgraph_index} = 1;
    $people_written->{$person->id} = 1;
    return $output;
}

=head2 as_dot

Return the text for a .dot graphviz file

print $tree->as_dot

=cut

sub as_dot {
    my $class = shift;
    debug "as dot called\n";
    $class->_init;
    my @people = sort { 
        warn "generation for $a or $b not set" unless defined($a->get('generation')) && defined($b->get('generation'));
        $a->get('generation') <=> $b->get('generation') } $class->people;
    my $output;

    # Make subgraphs for people with partners/spouses
    my %person2subgraph;  # map from person id to the dot text
    my @all_subgraphs;
    my %generation_subgraphs;   # keys are generations, values are arrays of arrays of people who are in a subgraph.
    my %person2subgraphpeople; # map from person id to an array of people in the subgraph
    for my $person (@people) {
        next if $person2subgraph{$person->get('id')};
        my @together = $class->_partner_and_marriage_group($person);
        debug "doing subgraph for : ".(join ',', map $_->first_name, @together)."\n";
        next unless @together > 0;
        $person2subgraph{$_->get('id')} = scalar(@all_subgraphs) for @together;
        push @all_subgraphs, $class->_partner_subgraph(\@together);
        debug "best ordering : ".(join ',', map $_->first_name, @together)."\n";
        $person2subgraphpeople{$_->get('id')} = \@together for @together;
    }
    
    # People
    my %people_written; # keeps track of people who have been written
    my %subgraph_written; # ids of subgraphs that have been written
    my %people_by_generation;
    for (@people) {
        push @{ $people_by_generation{$_->get('generation')} }, $_;
    }
    # starting with the bottom-most generation, do depth-first traversals to add
    # all ascendants and their partner subgraphs.
    # This also builds $bottomInvisibleEdges.   If this isn't on the
    # bottom of the graph, dot segfaults.
    # maybe on the top?  TODO 
    # if it isn't on the top, they're in the wrong place
    $bottomInvisibleEdges = '';
    for (sort {$b <=> $a } keys %people_by_generation) {
        my $this_generation = $people_by_generation{$_};
        next unless $this_generation;
        debug "adding generation $_\n";
        for my $person (@$this_generation) {
            debug "starting generation with person ".$person->first_name."\n";
            $output .= $class->_add_person_and_all_ascendants($person,\%person2subgraph,\%people_written,\%subgraph_written,\@all_subgraphs,\%person2subgraphpeople);
        }
    }
    die "unwritten subgraphs, should not happen" if grep {!$_} values %subgraph_written;

    # Parent edges
    for my $person (@people) {
        my $parent_key = join '_', map $_->get('id'), grep defined, ($person->dad,$person->mom);
        next unless $parent_key;
        $output .= "$parent_key -- ".$person->get('id')." // Parents of ".$person->get('id')."\n";
    }
    
    # Generations
    my $min_generation = $class->min_generation;
    my $max_generation = $class->max_generation;
    $output .= "/* generations : ".$min_generation." to ".$max_generation." */\n";
    my @generation_nodes;
    my $i = 0;
    for my $g ($min_generation .. $max_generation) {
        my $generation_node = "generation_".(++$i);
        push @generation_nodes, $generation_node;
        my @this = $class->find(generation => $g);
        my $which = $g==$min_generation ? 'source' : $g==$max_generation ? 'sink' : 'same';
        $output .= "{rank=$which; $generation_node ".
            (join ' ',map $_->get('id'), @this)."}\n";
    }
    # Now add an invisible edge between the first member of each generation.
    my $generation_edges;
    $generation_edges .= join "--", @generation_nodes;
    $generation_edges .= "[style=invis];\n";
    for (@generation_nodes) {
        $generation_edges .= qq{$_ [label="" style=invis];\n};
    }

    return join "\n",$GraphHeader,$topInvisibleEdges,$generation_edges,$output,$bottomInvisibleEdges,$GraphFooter;
}

# All people who are connected to a given person via marriage or partnership
# ...and all people connected to those people, etc.
sub _partner_and_marriage_group {
    my ($class, $person ) = @_;
    my @all = ($person);
    my @add_me = $person->partners_and_spouse;
    debug "partners and spouse for ".$person->id." : ".@add_me."\n";
    #debug (join ',',map $_->id, @add_me)."\n";
    while (@add_me) {
        push @all, @add_me;
        my @just_added = @add_me;
        @add_me = ();
        for (@just_added) {
            for my $p ($_->partners_and_spouse) {
                next if grep { $p eq $_ } @all;
                push @add_me, $p; 
            }
        }
    }   
    my %uniq = map { ( $_->get('id') => $_ ) } @all;
    return values %uniq; 
}

#
# _remove_duplicates
#
# Given a list of pairs of people, return a list of
# unique unordered pairs.  e.g. given
#    ( [a,b], [b,a], [c,d] )
#    return ( [a,b], [c,d] )
# where a,b,c,d are person objects.
#
sub _remove_duplicates {
    my @edges = @_;
    my @ret;
    my %h;
    for my $e (@edges) {
        next if $h{$e->[0]->id,$e->[1]->id}++;
        next if $h{$e->[1]->id,$e->[0]->id}++;
        push @ret, $e;
    }
    return @ret;
}

#
# _distance
#
# a metric on a list of ordered pairs :
#
# The sum of the difference between the first and last positions of each
# unique element, e.g.
#
# ( [a,b], [b,c], [c,d] ) == a -- b  b -- c  c -- d
#                            0    1  2    3  4    5
# 0-0 (a) + 2-1 (b) + 4-3 (c) + 5-5 (d) == 2
#
# ( [a,b], [c,d], [b,c] ) == a -- b  c -- d  b -- c
#                            0    1  2    3  4    5
# 0-0 (a) + (4-2) b + (5-2) c + 3-3 (d) = 5
#
# a,b,c,d are Tree::Family::Person objects
#
sub _distance {
    my @edges = @_;
    my @flattenned = map @$_, @edges;
    my %seen;
    my $distance = 0;
    for my $m (@flattenned) {
        next if $seen{$m->id}++;
        my $first = first_index { $_->id eq $m->id } @flattenned;
        my $last =  last_index  { $_->id eq $m->id } @flattenned;
        $distance += ($last - $first);
    }
    return $distance;
}

#
#_are_married
#
#_are_married($joe,$sue)
#
#returns true iff $joe and $sue are married
#
sub _are_married {
    my ($a,$b) = @_;
    return ($a->spouse() && $b->spouse() && $a->spouse->id eq $b->id);
}

#
# return --- or -+- for two people depending on whether they
# are married or not.
#
sub _ascii_pair {
    my ($a,$b) = @_;
    if (_are_married($a,$b)) {
        return join '-+-', $a->id, $b->id;
    } 
    return join '---', $a->id, $b->id;
}

#
# parameters : an array ref of pairs of people
# returns    : nothing, but puts 'em in a decent order, to minimize the
#              distance between elements of the pairs.
#
# e.g. given ( [d,c], [a,b], [b,c] )
# the best ordering would be one of
#            ( [a,b], [b,c], [c,d] )
#            ( [d,c], [c,b], [b,a] )
# since then they could appear like so:
#            a -- b -- c -- d
#
sub _find_best_ordering {
    my @pairs = @_;
    debug "-- finding best ordering of ".@pairs." marriages/partnerships\n";
    return @pairs unless @pairs > 1;
    my $min_distance;
    my @best = @pairs;
    my $i = Algorithm::Permute->new(\@pairs);
    my @m = $i->next;
    do {
        debug "-- starting with permutation : ".(join ' ', map _ascii_pair(@$_), @m)."\n";
        # flip the order of each possible edge
        for my $b (0..(2**(@m)-1)) {
            debug "-- b is $b\n";
            my $m = clone \@m;
            my $k = 0;
            for (@$m) {
                $_ = [$_->[1],$_->[0]] if $b & (1 << $k++);
            }
            my $d = _distance(@$m);
            debug " -- distance for ".(join ' ', map _ascii_pair(@$_), @$m)." : $d\n";
            if (!defined($min_distance) || $d < $min_distance) {
                $min_distance = $d;
                @best = @$m;
            }
        }
        @m = $i->next;
    } until (!@m);
    debug "-- best distance : $min_distance\n";
    return @best;
}

#
# make a subgraph of people who are partners (i.e. married or had kids together)
# also rearranges @people
#
sub _partner_subgraph {
    my ($class,$people) = @_;
    my @people = @$people;
    return '' if @$people==1;
    my @marriages;  
    my @parentships;  
    for my $p (@people) {
        push @marriages, [ $p, $p->spouse() ] if $p->spouse;
        push @parentships, [ $p, $_ ] for $p->partners;
    }
    my @cluster = (@marriages, @parentships);
    @cluster = _remove_duplicates(@cluster);
    @cluster = _find_best_ordering(@cluster);

    my $best = join ' ', map _ascii_pair(@$_), @cluster;
    debug "** best ordering : $best\n";

    my $graph_name = join '_and_', map $_->get('id'), @people;
    my $output = "subgraph cluster_$graph_name {\n /* $best */\ncolor=white;\n";

    for my $e (@cluster) {
        if (_are_married(@$e)) {
            $output .= $class->_marriage_subgraph(@$e);
        } else {
            $output .= $class->_parent_edge(@$e);
        }
    }

    return "" unless $output && $output =~ /\w/;
    return $output." } \n";
}

#
# intersect two array refs
#
sub _intersection {
   # probably a little slow compared to perldoc -q intersect, but can we use objects as hash keys?
   my ($a,$b) = @_;
   my @i;
   for my $x (@$b) {
     die "undefs in intersection" unless defined $x;
     push @i, $x if grep { $_ eq $x } @$a;
   }
   return @i;
}

#
# node from which a kid comes; a --+-- b
#                                  |
#                                 kid
# the "+" is the kid node.
#
sub _kid_node {
    my ($a,$b) = @_;
    die "no kid node for single parents" unless ($a && $b);
    ($a,$b) = ($b,$a) if $b->get('gender') eq 'm';
    return join '_',$a->get('id'),$b->get('id');
}

#
sub had_kids {
    my ($a,$b) = @_;
    my $x = [map $_->id, $a->kids ];
    my $y = [map $_->id, $b->kids ];
    debug "intersecting ".Dumper($x,$y);
    my @i = _intersection($x,$y);
    debug "number of kids shared by ".$a->id." and ".$b->id." is ".@i."\n";
    return (@i > 0);
}

sub _marriage_subgraph {
    my ($class,$x,$y) = @_;
    my ($one,$two) = map $_->get('id'), ($x,$y);
    my $graph;
    my %k;
    if (had_kids($x,$y)) {
        my $kid_node = _kid_node($x,$y);
        $graph = "$one -- $kid_node -- $two; rank=same;$one $two $kid_node;";
        $graph .= qq+\n$kid_node [label="",width=.01,height=.01]+;
    } else {
        $graph = "$one -- $two; rank=same;$one $two;";
    }
    return "subgraph marriage_${one}_${two} {\nedge [style=bold]; $graph }\n",
}

sub _parent_edge {
    # Draw an edge between two people who had a kid together
    my ($class,$x,$y) = @_;
    my ($one,$two) = map $_->get('id'), ($x,$y);
    my $kid_node = _kid_node($x,$y);
    return join "\n",
        "edge [style=dotted]; $one -- $kid_node -- $two { rank=same;$one $two $kid_node }",
        "$kid_node [ shape=point ]";
}

sub _person_node {
    my ($class, $person) = @_;
    our $urlBase;
    return $person->id . " ["
      . ($person->get('gender') eq 'm' ? 'color="#093AB5"' : 'color="#C666B8"')
      . ' label = "'
      . $class->_person_label($person)
      . qq|" href="$urlBase?id=|
      . $person->id . '"];';
}

sub _person_label {
    my ($class,$p) = @_;
    return join ' ', grep defined($_), $p->get('first_name'), $p->get('last_name');
}

sub DESTROY {
    %Tree::Family::Person::globalHash = ();
}

=head1 SEE ALSO

 Tree::Family::Person
 family.cgi (in this distribution)

=head1 AUTHOR

Brian Duggan, C<< <bduggan at matatu.org> >>

=head1 BUGS

graphviz uses a lot of heuristics to create a nice layout.  This package
attempts to micro-manage the contents of the dot file in order to produce
a nice layout, while still letting  graphviz do the brunt of the work.
This approach doesn't always produce optimal results.  Patches welcome.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Brian Duggan, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
