#!/usr/local/bin/perl

use GO::Admin;
use Getopt::Long;
use strict;

my $pfile;
if (-f "go-manager.conf") {
    $pfile = "go-manager.conf";
}

my $dbname;
my $dbhost;
my $dbms;
my $dateopt;
my $data_root;
my $interactive;
my $releasename;
my $monthly;
my $weekly;
my $daily;
my @skip = ();
my $noupdatesp;
my $norefresh;
my $bulkload;
my $reasoner;

my $suff = "godb";

my $load;

if (!@ARGV) {
    system("perldoc $0");
    exit;    
}

GetOptions("Date=s"=>\$dateopt,
	   "name|n=s"=>\$suff,
	   "dbname|d=s"=>\$dbname,
	   "host|h=s"=>\$dbhost,
	   "help"=>sub{system("perldoc $0");exit},
	   "dbms|m=s"=>\$dbms,
	   "load|f=s"=>\$load,
	   "dataroot|r=s"=>\$data_root,
	   "releasename=s"=>\$releasename,
	   "reasoner=s"=>\$reasoner,
	   "interactive|i"=>\$interactive,
	   "monthly"=>\$monthly,
	   "weekly"=>\$weekly,
	   "daily"=>\$daily,
	   "skip=s@"=>\@skip,
	   "noupdatesp"=>\$noupdatesp,
	   "norefresh"=>\$norefresh,
	   "bulk"=>\$bulkload,
###	   "nocoderel"=>\$nocoderel,
	  );


$bulkload = 'bulk' if $bulkload;

my $time_started = localtime(time);

my $admin = GO::Admin->new;

$admin->data_root($ENV{GODATA_ROOT});

if ($load) {
    $pfile = $load;
    $admin->loadp($load);
}

# temporary; can be remove after all production versions of db have gene_product_count.species_id
$ENV{GO_HAS_COUNT_BY_SPECIES} = 1;

# call the check_environment method to check environmental variables like ??? 
#print "\nCalling check_environment method...\n";
#&check_environment($pfile);
# Don't need this?

# overwrite options
$admin->dbname($dbname) if $dbname;
$admin->dbhost($dbhost) if $dbhost;
$admin->dbms($dbms) if $dbms;
$admin->releasename($releasename) if $releasename;
$admin->data_root($data_root) if $data_root;

$admin->newdb();
$admin->load_schema();
my $fmt = 'obo_text';
foreach my $file (@ARGV) {
    $admin->load_go($fmt,$file,"-no_fill_path -no_optimize");
}

if ($reasoner) {
    $admin->run_reasoner($reasoner);
}

my $time_finished = localtime(time);

exit 0;

=head1 NAME 

 go-create-database-and-load.pl

=head1 SYNOPSIS

  go-create-database-and-load.pl -d mydbname -h myhost gene_ontology_edit.obo

=head1 DESCRIPTION

Loads a GO database from ontology files.

Note: to make a full release, use go-prepare-release.pl

=head1 PRERQUISITES

You need both go-perl and go-db-perl installed

=cut
