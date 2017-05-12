#!/usr/local/bin/perl

use GO::Admin;
use Getopt::Long;
use strict;

# usage 
# go-manager.pl -f go-manager.conf

my $pfile = "$ENV{HOME}/.go-manager.conf";
if (-f "go-manager.conf") {
    $pfile = "go-manager.conf";
}

my $dbname;
my $dbhost;
my $dbms;
my $dateopt;
my $data_root;
my $releasename;

my $suff = "godb";
my $load;
GetOptions("Date|D=s"=>\$dateopt,
	   "name|n=s"=>\$suff,
	   "dbname|d=s"=>\$dbname,
	   "host|s=s"=>\$dbhost,
	   "dbms|m=s"=>\$dbms,
	   "load|f=s"=>\$load,
	   "dataroot|r=s"=>\$data_root,
	   "releasename=s"=>\$releasename,
	  );


my $admin = GO::Admin->new;

$admin->data_root($ENV{GODATA_ROOT});

if ($load) {
    $pfile = $load;
    $admin->loadp($load);
}

# overwrite options
$admin->dbname($dbname) if $dbname;
$admin->dbhost($dbhost) if $dbhost;
$admin->dbms($dbms) if $dbms;
$admin->releasename($releasename) if $releasename;
$admin->data_root($data_root) if $data_root;

my @admins = ();

iloop();

no strict 'refs';

sub newadmin {
    push(@admins, $admin);
    $admin = GO::Admin->new;
}
my $reltype;

# interactive loop
sub iloop {
    my $quit = 0;
    while (!$quit) {
	showp();
	my @opts = menuopts();
	my $c = $admin->is_connected;
	printf "\nSTATUS: %s\n",
	  $c ? "** CONNECTED **" : "Not connected";
	if ($c) {
	    my $inst = $admin->apph->instance_data;
	    printf " DB - rtype: $inst->{release_type} rname: $inst->{release_name}\n";
	    $reltype = $admin->guess_release_type;
	    printf " GUESSED TYPE: $reltype\n";
	}
	my $lastsp = $admin->time_of_last_sp_update;
	if (!$lastsp) {
	    print "  YOU NEED TO UPDATE SWISSPROT\n";
	}
	else {
	    my $pp = localtime($lastsp);
	    print "  Last SP proteome file update: $pp\n";
	    my $t = time;
	    if ($t - $lastsp > 60 * 60 * 24 * 30) {
		print " MORE THAN A MONTH OLD\n";
	    }
	}
	print "\nMENU:\n";
	for (my $i=0; $i<@opts; $i++) {
	    printf "%2d: $opts[$i]->[1]\n", $i+1;
	}
	print "\n\nEnter option no:";
	my $n = getinput() -1;
	if ($n < 0 || $n >= @opts) {
	    print "INVALID\n";
	}
	else {
	    my $opt = $opts[$n]->[0];
	    print "Calling: $opt\n";
	    eval {
		&{$opt}();
	    };
	    if ($@) {
		errm($@);
	    }
	}
    }
}


sub showp {
    my @p = $admin->_valid_params;
    print "\nPARAMETERS:\n";
    foreach (@p) {
	printf "%-20s: %s\n",
	  $_, $admin->$_();
    }
}

sub checkp {
    if (!$admin->dbname || !$admin->releasename) {
	setp();
    }
}

sub setp {
    my $p = shift;
    if (!$p) {
	my @p = $admin->_valid_params;
	foreach (@p) {
	    setp($_);
	}
	showp();
	print "\nIs this OK?\n";
	my $yn = getinput();
	if ($yn !~ /^y/i) {
	    setp();
	}
	$admin->savep(".go-manager.autosaved.conf");
	$admin->apph(undef);
    }
    else {
	printf "ENTER VALUE FOR $p [current:%s]\n: ", $admin->$p();
	my $v = getinput();
	$admin->$p($v) if $v;
	printf "[new val:%s]\n", $admin->$p();
    }
}

sub newdb {
    my $yes = getinput("Are you SURE? ");
    $admin->newdb() if $yes;
}


sub load_schema {
    $admin->load_schema();
}

sub load_assocdb {
    $admin->load_assocdb;
}

sub load_termdb {
    $admin->load_termdb;
}

sub refresh_data_root {
    $admin->refresh_data_root;
}

sub errm {
    print STDERR "@_\n";
}

sub loadp {
    my $f = getinput("Enter file name [$pfile]: ");
    if (!$f) {
	$f = $pfile;
    }
    if (-f $f) {
	newadmin();
	$admin->loadp($f);
	print "loaded!\n";
	showp();
    }
    else {
	errm("No such file!");
    }
}

sub savep {
    my $f = getinput("Enter file name [$pfile]: ");
    if (!$f) {
	$f = $pfile;
    }
    if (-f $f && $f ne $pfile) {
	my $yes = sayyes("Overwrite existing $f?\n");
	if (!$yes) {
	    print "untouched!\n";
	    return;
	}
    }
    else {
	$admin->savep($f);
	print "saved!\n";
    }
}

sub seq_count_by_species {
    checkp();
    mysql('select species.*, count(*) as c from species, gene_product_seq gps, gene_product gp where gp.id = gene_product_id and species_id = species.id group by species.id order by c');
}

sub mysql {
    checkp();
    my $c = shift;
    $c = $c ? "-e '$c'" : "";
    system("mysql ".$admin->mysqlargs. " $c");
}

sub dumprdfxml {
    checkp();
    $admin->dumprdfxml;
}

sub dumpseq {
    checkp();
    $admin->dumpseq;
}

sub load_seqs {
    checkp();
    $admin->load_seqs;
}

sub load_species {
    checkp();
    $admin->load_species;
}

sub load_refg {
    checkp();
    $admin->load_refg;
}

sub updatesp {
    $admin->updatesp;
}

sub update_speciesdir {
    $admin->update_speciesdir;
}

sub stats {
    checkp();
    print $admin->report;
}

sub remove_iea {
    checkp();
    $admin->remove_iea();
}

sub releasedb {
    checkp();
    my $suff = getinput("Enter release type (eg assocdb, termdb): ", $admin->guess_release_type);
    my $f = $admin->releasename . '-' .$admin->guess_release_type . '.tar.gz';
    if (-f $f) {
	my $yes = sayyes("overwrite existing $f?\n");
	return unless $yes;
    }
    $admin->makedist($suff);
}

sub releasecode {
    checkp();
    my $D = getinput("Enter cvs -D option [to sync code and db]");
    $admin->makecoderelease($D);
}

sub showrel {
    my @f = $admin->released_files;
    foreach (@f) {
	printf "$_\n    %s\n", `ls -alt $_`;
    }
}

# check a release file
sub checkrelf {
    showrel();
    my $f = getinput("Which release file?\n");
    my $tmpadmin = GO::Admin->new;
    foreach ($admin->_valid_params) {
	$tmpadmin->$_($admin->$_());
    }
    $tmpadmin->dbname("go_tmp");
    $tmpadmin->newdb;
    $tmpadmin->build_from_file($f);
    print "\n\nLoaded!\n\n";
    $tmpadmin->tcount;
    print "\n\nDone!\n\n";
}

# check a release file
sub loadrelf {
    showrel();
    print "** WARNING ** this will overwrite current db\n\n";
    my $f = getinput("Which release file?\n");
    if ($f && -f $f) {
	$admin->newdb;
	$admin->build_from_file($f);
	print "\n\nLoaded!\n\n";
    }
    else {
	print "Not loaded - no such file as $f\n";
    }
}

sub tcount {
    checkp();
    $admin->tcount();
}

sub sayyes {
    my $answer;
    while (!$answer) {
	$answer = getinput(@_); 
	chomp $answer;
    }
    return $answer =~ /^y/i;
}

sub getinput {
    my $m = shift;
    my $def = shift;
    print $m if $m;
    if (defined $def) {
	print " [$def] ";
    }
    my $i = <STDIN>;
    chomp $i;
    if (!$i && defined($def)) {
	$i = $def;
    }
    return $i;
}


sub menuopts {
    return 
      (
       [loadp      => "Load DB Parameters"],
       [savep      => "Save DB Parameters"],
       [setp       => "Set DB Parameters (dbname, host, etc)"],
       [newdb      => "Create a new Database"],
       [load_schema      => "Load GO Schema"],
       [load_termdb        => "Load Ontology"],
       [load_assocdb      => "Load Associations"],
       [dumprdfxml    => "Dump RDF-XML from this DB"],
       [dumpseq    => "Dump FASTA sequence from this DB"],
       [releasedb  => "Make release tarball from this data"],
       [releasecode  => "Prepare go-dev code release"],
       [remove_iea => "Remove IEA associations"],
       [mysql      => "Use MySQL interpreter"],
       [stats      => "Stats"],
       [tcount     => "Table count"],
       [updatesp   => "Refresh/download SP proteomes sequence files"],
       [update_speciesdir   => "Refresh/download NCBI Taxdump files"],
       [refresh_data_root   => "Refresh data root (cvs update from src)"],
       [load_seqs  => "Load SP proteomes sequence files"],
       [load_species  => "Load Species from ncbi taxonomy dump"],
       [load_refg  => "Load reference genomes"],
       [showrel    => "Show released files"],
       [checkrelf  => "Check a released tarball"],
       [loadrelf   => "Load from a released tarball"],
       [seq_count_by_species   => "Count of sequences (by species)"],
      );
}

