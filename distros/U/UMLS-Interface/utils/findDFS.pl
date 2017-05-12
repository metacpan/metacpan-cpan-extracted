#!/usr/bin/perl 

=head1 NAME

findDFS.pl - This program runs a dfs over a specified set of sources
and relations in the UMLS.

=head1 SYNOPSIS

This is a utility runs a dfs over a specified set of sources
and relations in the UMLS returning the depth, number of paths 
to the root, branching factor, leaf and node count.

=head1 USAGE

Usage: findDFS.pl CONFIGFILE [OPTIONS]

=head1 INPUT

=head2 Required Arguments: 

=head3 CONFIGFILE

Configuration file containing the set of sources and 
relations to use. The default uses MSH and the PAR/CHD 
relations.

The format of the configuration file is as follows:

SAB :: <include|exclude> <source1, source2, ... sourceN>

REL :: <include|exclude> <relation1, relation2, ... relationN>

RELA :: <include|exclude> <rela1, rela2, ... relaN>  (optional)

The SAB, REL and RELA are for specifing what sources and relations 
should be used when traversing the UMLS. For example, if we 
wanted to use the MSH vocabulary with only the RB/RN relations, 
the configuration file would be:

SAB :: include MSH
REL :: include RB, RN
RELA :: include isa, inverse_isa

or if we wanted to use MSH and use any relation except for PAR/CHD, 
the configuration would be:

SAB :: include MSH
REL :: exclude PAR, CHD

An example of the configuration file can be seen in the samples/ directory. 

=head2 Optional Arguments:

=head3 --debug

Sets the debug flag for testing

=head3 --username STRING

Username is required to access the umls database on MySql
unless it was specified in the my.cnf file at installation

=head3 --password STRING

Password is required to access the umls database on MySql
unless it was specified in the my.cnf file at installation

=head3 --hostname STRING

Hostname where mysql is located. DEFAULT: localhost

=head3 --socket STRING

The socket your mysql is using. DEFAULT: /tmp/mysql.sock

=head3 --database STRING        

Database contain UMLS DEFAULT: umls

=head3 --debugpath FILE

This option prints out the path information for debugging 
purposes. 

=head3 --depth NUMBER

Searches up to the specified depth. The default is to 
search the complete hierarchy

=head3 --root CUI

Starts the search at a specified CUI. The default starts 
the search at the UMLS root node

=head3 --level NUMBER

Returns the number of CUIs above and below this NUMBER

=head3 --help

Displays the quick summary of program options.

=head3 --version

Displays the version information.

=head1 OUTPUT

The program returns the following: 

    1. the maximum depth
    2. paths to root
    3. sources
    4. maximum branching factor
    5. average branching factor
    6. number of leaf nodes
    7. number of nodes
    8. root


=head1 SYSTEM REQUIREMENTS

=over

=item * Perl (version 5.8.5 or better) - http://www.perl.org

=back

=head1 AUTHOR

 Bridget T. McInnes, University of Minnesota

=head1 COPYRIGHT

Copyright (c) 2007-2009,

 Bridget T. McInnes, University of Minnesota
 bthomson at cs.umn.edu
    
 Ted Pedersen, University of Minnesota Duluth
 tpederse at d.umn.edu

 Siddharth Patwardhan, University of Utah, Salt Lake City
 sidd@cs.utah.edu
 
 Serguei Pakhomov, University of Minnesota Twin Cities
 pakh0002@umn.edu

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to:

 The Free Software Foundation, Inc.,
 59 Temple Place - Suite 330,
 Boston, MA  02111-1307, USA.

=cut

###############################################################################

#                               THE CODE STARTS HERE
###############################################################################

#                           ================================
#                            COMMAND LINE OPTIONS AND USAGE
#                           ================================


use UMLS::Interface;
use Getopt::Long;

eval(GetOptions( "version", "help", "username=s", "password=s", "hostname=s", "database=s", "socket=s", "depth=s", "root=s", "debugpath=s", "debug", "level=s")) or die ("Please check the above mentioned option(s).\n");



#  if help is defined, print out help
if( defined $opt_help ) {
    $opt_help = 1;
    &showHelp();
    exit;
}

#  if version is requested, show version
if( defined $opt_version ) {
    $opt_version = 1;
    &showVersion();
    exit;
}

# At least 1 term should be given on the command line.
if(scalar(@ARGV) < 1) {
    print STDERR "The config file was not specified on the command line\n";
    &minimalUsageNotes();
    exit;
}

my $config = shift;

my $umls = "";

my %option_hash = ();

$option_hash{"config"} = $config;

if(defined $opt_debug) {
    $option_hash{"debug"} = $opt_debug;
}

if(defined $opt_username) {
    $option_hash{"username"} = $opt_username;
}
if(defined $opt_driver) {
    $option_hash{"driver"}   = $opt_driver; 
}
if(defined $opt_database) {
    $option_hash{"database"} = $opt_database;
}
if(defined $opt_password) {
    $option_hash{"password"} = $opt_password;
}
if(defined $opt_hostname) {
    $option_hash{"hostname"} = $opt_hostname;
}
if(defined $opt_socket) {
    $option_hash{"socket"}   = $opt_socket;
}

$umls = UMLS::Interface->new(\%option_hash); 
die "Unable to create UMLS::Interface object.\n" if(!$umls);

#  get the relations from the configuration file
my $configrel = $umls->getRelString();
$configrel=~/(REL) (\:\:) (include|exclude) (.*?)$/;
my $relationstring = $4; 

#  check to make certain the configuration file only contains
#  heirarchical relations (PAR/CHD or RB/RN).
my @relations = split/\s*\,\s*/, $relationstring; 
foreach my $rel (@relations) { 
  if(! ($rel=~/(PAR|CHD|RB|RN)/) ) { 
    print STDERR "The findDFS.pl program only supports heirarchical relations (PAR/CHD or RB/RN).\n";
    &minimalUsageNotes();
    exit;
  } 
}

#  set the root
my $root = "C0000000";
if(defined $opt_root) {
    $root = $opt_root;
}

#  set paths to root counter;
my $paths_to_root = 0;

#  set branching variables
my $max_branch     = 0;
my $avg_branch     = 0;
my $branch_counter = 0;
my %branch_hash = ();

#  set leaf node counter
my %leafs = ();
my %nodes = ();
my %decendents = (); 

#  set max depth variable
my $max_depth = 0;

#  set the sources
my $sources = "";
open(CONFIG, $config) || die "Could not open config file: $config\n";
while(<CONFIG>) {
    if($_=~/SAB\s+\:\:\s+(include|exclude)\s+(.*)/) {
	$sources = $2;
    }
}

#  if the debugpath option is turned on open up the table file
if($opt_debugpath) {
    
    open(TABLEFILE, ">$opt_debugpath") || die "Could not open $opt_debugpath";
}

#  get the first set of children and start the dfs
my $children= $umls->getChildren($root); 

#  update the branching variables
$max_branch = $#{$children} + 1;
$branch_hash{$root} = $max_branch;

foreach my $child (@{$children}) {
    my @array = (); 
    push @array, $root;
    my $path  = \@array;
    my $d = 0;
    &_depthFirstSearch($child, $d, $path,*TABLEFILE);
}

#  set the node count for the root
if($#{$children} >= 0) { 
    $nodes{$root}++;
    $decendents{$root}++; 
}
else {
    $leafs{$root}++;
}

#  close the file and set the permissions
if($opt_debugpath) {
    close TABLEFILE;
    my $temp = chmod 0777, $tableFile;
}

#  calculate the max and average number of branches
foreach my $cui (sort keys %branch_hash) {
    if($branch_hash{$cui} > $max_branch) { $max_branch = $branch_hash{$cui}; }
    $avg_branch += $branch_hash{$cui};
    $branch_counter++;
}
$avg_branch = $avg_branch / $branch_counter;

#  set the node and leaf counts
my $leaf_count = keys %leafs;
my $node_count = keys %nodes;
my $decendent_count = keys %decendents;

my $total_count= $leaf_count + $node_count;

#  get the average depth
my $avg_leaf_depth = 0; my $avg_node_depth = 0;
foreach my $c (sort keys %leafs) { $avg_leaf_depth+=$leafs{$c}; }
foreach my $c (sort keys %nodes) { $avg_node_depth+=$nodes{$c}; }

my $avg_depth = ($avg_leaf_depth + $avg_node_depth) / $total_count;
if($leaf_count > 0) { 
    $avg_leaf_depth = $avg_leaf_depth / $leaf_count;
}
if($node_count > 0) { 
    $avg_node_depth = $avg_node_depth / $node_count;
}

#  get the standard deviation
my $avg_leaf_sd = 0; $avg_node_sd = 0;
foreach my $c (sort keys %leafs) { $avg_sd += ($leafs{$c}-$avg_depth)**2; }
foreach my $c (sort keys %nodes) { $avg_sd += ($nodes{$c}-$avg_depth)**2; }

$avg_sd = $avg_sd/$total_count;
$avg_sd = sqrt($avg_sd); 

#  get the mean depth of the leafs and nodes
#  also get the --level information if defined
my $leaf_mean = int($leaf_count / 2);
my $node_mean = int($node_count / 2);

my $leaf_mean_depth  = 0;
my $node_mean_depth  = 0;
my $level_leaf_above = 0;
my $level_leaf_below = 0;
my $level_node_above = 0;
my $level_node_below = 0;
my $counter          = 1;

$counter = 1;
foreach my $c (sort {$nodes{$b}<=>$nodes{$a}} keys %nodes) { 
    if($counter == $node_mean) { 
	$node_mean_depth = $nodes{$c};
    }
    if($nodes{$c} >= $opt_level) { $level_node_above++; }
    if($nodes{$c} <  $opt_level) { $level_node_below++; }
    $counter++; 
}
    
$subsumers = $leaf_count + $node_count;

#  print out the information
print "max_depth : $max_depth\n";
print "avg_depth : $avg_depth\n";
print "sd_depth  : $avg_sd\n";
print "paths_to_root : $paths_to_root\n";
print "sources : $sources\n";
print "max_branch : $max_branch\n";
print "avg_branch : $avg_branch\n";
print "leaf_count : $leaf_count\n";
print "node_count : $node_count\n";
print "decendents : $decendent_count\n";
print "avg_leaf_depth : $avg_leaf_depth\n";
print "avg_node_depth : $avg_node_depth\n";
print "mean_leaf_depth : $leaf_mean_depth\n";
print "mean_node_depth : $node_mean_depth\n";
print "root : $root\n"; 
if(defined $opt_level) { 
    print "nodes_above_level : $level_node_above\n";
    print "leafs_above_level : $level_leaf_above\n";
    print "nodes_below_level : $level_node_below\n";
    print "leafs_below_level : $level_leaf_below\n";
}

######################################################################### 
#  Depth First Search (DFS) 
######################################################################### 
sub _depthFirstSearch
{
    my $concept = shift;
    my $d       = shift;
    my $array   = shift;
    local(*F)   = shift;

    #  increment the depth
    $d++;

    #  if the depth option has been set and the depth 
    #  is now greater than the set depth just return 
    if(defined $opt_depth) {
	if($d > $opt_depth) { return; }
    }
    
    #  set the max depth
    if($d > $max_depth) { $max_depth = $d; }

    #  if concept is one of the following just return
    #C1274012|Ambiguous concept (inactive concept)
    if($concept=~/C1274012/) { return; }
    #C1274013|Duplicate concept (inactive concept)
    if($concept=~/C1274013/) { return; }
    #C1276325|Reason not stated concept (inactive concept)
    if($concept=~/C1276325/) { return; }
    #C1274014|Outdated concept (inactive concept)
    if($concept=~/C1274014/) { return; }
    #C1274015|Erroneous concept (inactive concept)
    if($concept=~/C1274015/) { return; }
    #C1274021|Moved elsewhere (inactive concept)
    if($concept=~/C1274021/) { return; }
    #C2733115|limited status concept
    if($concept=~/C2733115/) { return 1; }
    #C1443286|
    if($concept=~/C1443286/) { return; }

    if($concept=~/C0332280/) { return 1; }
    if($concept=~/C0458341/) { return 1; }
    if($concept=~/C0562418/) { return 1; }
    if($concept=~/C0588390/) { return 1; }
    if($concept=~/C1264758/) { return 1; }
    if($concept=~/C1273115/) { return 1; }
    if($concept=~/C1274012/) { return 1; }
    if($concept=~/C1274013/) { return 1; }
    if($concept=~/C1274014/) { return 1; }
    if($concept=~/C1274015/) { return 1; }
    if($concept=~/C1274021/) { return 1; }
    if($concept=~/C1276325/) { return 1; }
    if($concept=~/C1285556/) { return 1; }
    if($concept=~/C1285659/) { return 1; }
    if($concept=~/C1298232/) { return 1; }
    if($concept=~/C1299995/) { return 1; }
    if($concept=~/C2733115/) { return 1; }
    if($concept=~/C3645578/) { return 1; }
    if($concept=~/C3645611/) { return 1; }
    if($concept=~/C3645619/) { return 1; }
    
    #  set the new path
    my @path = @{$array};
    push @path, $concept;
    
    my $series = join " ", @path;
    
    #  print information into the file if debugpath option is set
    if($opt_debugpath) { print F "$concept\t$d\t$series\n"; }
    
    #  increment the number of paths
    $paths_to_root++;

    #  get all the children
    my $children = $umls->getChildren($concept);

    
    my $branches = 0;
    #  search through the children
    foreach my $child (@{$children}) {
	
	#  check if child cui has already in the path
	my $flag = 0;
	foreach my $cui (@path) {
	    if($cui eq $child) { 
		$flag = 1; 
	    }
	}

	#  if it isn't continue on with the depth first search
	if($flag == 0) {
	    &_depthFirstSearch($child, $d, \@path, *F);
	    $branches++;
	}
    }
 
    #  update the branching variables
    if($branches > 0) {
	$branch_hash{$concept} = $branches;
    }
    
    #  get the decendent and capture the max depth
    if(exists $decendents{$concept}) { 
	if($d > $decendents{$concept}) { 
	    $decendents{$concept} = $d; 
	} 
    } else { $decendents{$concept} = $d; }
    
    
    #  set the leaf count and capture the max depth
    if($branches == 0) { 
	if(exists $leafs{$concept}) { 
	    if($d > $leafs{$concept}) { 
		$leafs{$concept} = $d; 
	    } 
	} else { $leafs{$concept} = $d; }
    }
    else {
	if(exists $nodes{$concept}) { 
	    if($d > $nodes{$concept}) { 
		$nodex{$concept} = $d; }
	}
	else { $nodes{$concept} = $d; }
    }
}
##############################################################################
#  function to output minimal usage notes
##############################################################################
sub minimalUsageNotes {
    
    print "Usage: findDFS.pl CONFIGFILE [OPTIONS]\n";
    &askHelp();
    exit;
}

##############################################################################
#  function to output help messages for this program
##############################################################################
sub showHelp() {

        
    print "This is a utility runs a dfs over a specified set of sources\n";
    print "and relations in the UMLS returning the depth, number of paths\n";
    print "to the root, branching factor, leaf and node count.\n\n";
  
    print "Usage: findDFS.pl CONFIGFILE [OPTIONS]\n\n";

    print "Options:\n\n";

    print "--debug                  Sets the debug flag for testing\n\n";

    print "--username STRING        Username required to access mysql\n\n";

    print "--password STRING        Password required to access mysql\n\n";

    print "--hostname STRING        Hostname for mysql (DEFAULT: localhost)\n\n";

    print "--database STRING        Database contain UMLS (DEFAULT: umls)\n\n";
    
    print "--socket STRING          Socket used by mysql (DEFAULT: /tmp.mysql.sock)\n\n";

    print "--debugpath FILE         Stores path information in FILE\n\n";
    
    print "--depth NUMBER           Searches up to the specified depth\n";
    print "                         Default searches the complete taxonomy\n\n";

    print "--level NUMBER           Returns the number of CUIs above and \n";
    print "                         below this NUMBER.\n\n";

    print "--root CUI               Starts the search at a specified CUI\n";
    print "                         Default is the UMLS root\n\n";
    
    print "--version                Prints the version number\n\n";
 
    print "--help                   Prints this help message.\n\n";
}

##############################################################################
#  function to output the version number
##############################################################################
sub showVersion {
    print '$Id: findDFS.pl,v 1.26 2014/02/06 13:08:19 btmcinnes Exp $';
    print "\nCopyright (c) 2008, Ted Pedersen & Bridget McInnes\n";
}

##############################################################################
#  function to output "ask for help" message when user's goofed
##############################################################################
sub askHelp {
    print STDERR "Type findDFS.pl --help for help.\n";
}
    
