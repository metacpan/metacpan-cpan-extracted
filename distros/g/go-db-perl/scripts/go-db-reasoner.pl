#!/usr/bin/perl -w
use strict;
use DBI;
use FileHandle;
use GO::Reasoner;

my $d;
my $dbhost = '';
my $dump;
my $split;
my $delete;
my $limit = 50000;
my $source;
my %skip = (intersections=>1);
my $verbose = 0;
my %ruleconf = ();

my $reasoner = GO::Reasoner->new();
if (!@ARGV) {
    system("perldoc $0");
    exit(1);
}
while (@ARGV && $ARGV[0] =~ /^\-/) {
    my $opt = shift @ARGV;
    if ($opt eq '-d' || $opt eq '--database') {
        $d = shift @ARGV;
    }
    elsif ($opt eq '--dump') {
        $dump = 1;
    }
    elsif ($opt eq '--delete') {
        $delete = 1;
    }
    elsif ($opt eq '-v' || $opt eq '--verbose') {
        $verbose = 1;
    }
    elsif ($opt eq '-h' || $opt eq '--host') {
        $dbhost = shift @ARGV;
    }
    elsif ($opt eq '--split') {
        $split = shift @ARGV;
    }
    elsif ($opt eq '--source') {
        $source = shift @ARGV;
    }
    elsif ($opt eq '--skip') {
        $skip{shift @ARGV}=1;
    }
    elsif ($opt eq '--rule') {
        $ruleconf{shift @ARGV}=1;
    }
    elsif ($opt eq '-?' || $opt eq '-help') {
        system("perldoc $0");
        exit(0);
    }
    else {
        die $opt;
    }
}
if (!$d) {
    $d = shift @ARGV;
}
if ($dbhost) {
    $d  = "mysql:$d\@$dbhost";
}

$reasoner->skip(\%skip);
$reasoner->ruleconf(\%ruleconf);
$reasoner->verbose($verbose);

my $dbh;
if ($d =~ /^dbi:/) {
    $dbh = DBI->connect($d);
}
elsif ($d =~ /\@/) {
    require 'DBIx/DBStag.pm';
    $dbh = DBIx::DBStag->connect($d);
}
else {
    $dbh = DBI->connect("dbi:Pg:dbname=$d");
}

$reasoner->dbh($dbh);

if ($delete) {
    $reasoner->delete_inferred_links();
}

my $time_started = time;
$reasoner->run();
my $time_finished = time;

printf STDERR "Started: %d Finished: %d Duration: %d\n", $time_started, $time_finished, $time_finished - $time_started;

exit 0;


=head1 NAME

go-db-reasoner.pl

=head1 SYNOPSIS

  go-db-reasoner.pl -d mygo -h 127.0.0.1

=head1 DESCRIPTION

This script builds the "graph_path" table in the GO Database.

Previously, graph_path was constructed as a closure of the GO graph,
ignoring edge labels (relations)

This script takes into account the formal semantics of the properties
of relations. Pairs of relations are not traversed unless they
explictly compose together. This removes erroneous inferences.

This script works in two steps

=over

=item First a relation composition table is constructed

=item Then a forward chaining reasoner is executed, iteratively finding all inferred relations

=back

=head2 Completion of relation composition table

As a first step, the script completes the "relation_composition"
table. This table may already be pre-populated by normal GO loading if
the ontology contains "transitive_over" or "holds_over_chain_tags".

For example, in the Gene Ontology, the "regulates" relation has the
property of being transitive_over part_of. This means the
relation_composition table will be pre-populated with:

  R1        | R2       | INFERRED
  ----------+----------+----------
  regulates . part_of -> regulates

=head3 Transitivity

If R is_transitive, then the following composition is added:

  R . R -> R

=head3 Transitivity over and under is_a

If R is an all-some relation, then the following compositions are added:

  R . is_a -> R
  is_a . R -> R

=head3 Sub-relations

If Ra is a sub-relation (direct or transitive) of Rb then:

=over

=item  Add a composition Ra . R2 -> R for every composition Rb . R2 -> R

=item  Add a composition R1 . Ra -> R for every composition R1 . Rb -> R

=back

=head2 Forward chaining

After the relation_composition table is fully populated, the reasoner
will attempt to apply compositions to derived new inferred relations
(i.e. entries in graph_path). As a first step, the term2term table is
copied in to graph_path

For example, given the following asserted links in term2term:

 A regulates B
 B is_a C
 C is_a D
 D part_of E
 E regulates F

And the relation compositions:

 1. regulates . is_a -> regulates
 2. is_a . part_of -> part_of

The reasoner will infer a graph_path for "A" as follows:

=over

=item pass 1 (using regulates . is_a)

 A regulates B
 B is_a C
 ---
 A regulates C

=item pass 2 (using regulates . is_a)

 A regulates C
 C is_a D
 ---
 A regulates D
 
=item pass 2 (using regulates . part_of)

 A regulates D
 D part_of E
 ---
 A regulates E
 
=back

Note that in this example regulates is not declared transitive, so no path is inferred between A and F

Compositions are applied repeatedly until graph_path is saturated, and no new inferences can be made

=head2 Distances

Using the old population method "graph_path.distance" was a count of
the number of "hops" along the asserted graph the path takes. This
meaning is retained with go-db-reasoner.pl (note that now redundant
paths are not calculated)

Now, in addition there is a new table
"graph_path.relation_distance". This is the number of steps using the
specified relationship type. For example, in the example above, [A
regulates E] has distance=4 and relation_distance=1

=head1 SEE ALSO

http://wiki.geneontology.org/index.php/Transitive_closure

http://wiki.geneontology.org/index.php/Relation_composition

http://www.geneontology.org/GO.database.schema.shtml#go-optimisations.table.graph-path

=cut
