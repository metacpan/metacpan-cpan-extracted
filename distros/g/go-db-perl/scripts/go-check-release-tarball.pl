#!/usr/local/bin/perl

BEGIN {
    if (defined($ENV{GO_ROOT})) {
	# use lib "$ENV{GO_ROOT}/perl-api";
    }
}
use GO::Admin;
use Getopt::Long;
use strict;

my $dbname = 'go_tmp'; 
my $dbhost;
my $dbms;
my $dateopt;
my $data_root = $ENV{GODATA_ROOT};
my $interactive;
my $releasename;

my $suff = "godb";
my $load;
GetOptions("Date|D=s"=>\$dateopt,
	   "name|n=s"=>\$suff,
	   "dbname|d=s"=>\$dbname,
	   "host|h=s"=>\$dbhost,
	   "dbms|m=s"=>\$dbms,
	   "load|f=s"=>\$load,
	   "dataroot|r=s"=>\$data_root,
	   "releasename=s"=>\$releasename,
	   "interactive|i"=>\$interactive,

	  );

my $admin = GO::Admin->new;

if ($load) {
#    $pfile = $load;
    $admin->loadp($load);
}

$admin->dbname($dbname);
$admin->dbhost($dbhost);
$admin->dbms($dbms);
$admin->data_root($data_root);

if ($admin->dbname !~ /(test|tmp|temp)/) {
    die "$dbname => dbname must have test or tmp or temp in string to prevent accidental overwrites";
}

foreach (@ARGV) {
    check_tarball($_);
}
exit 0;

sub check_tarball {
    my $f = shift;
    print STDERR "File name => $f\n";
    my $r;
    if ($f =~ /(\S+)[\.\-](\w+)\-tables\.tar/) {
	$admin->newdb;
	$admin->build_from_file($f);
	$r = $admin->report($f);
    }
    elsif ($f =~ /(\S+)[\.\-](\w+)\-data/) {
	$admin->newdb;
	$admin->build_from_file($f);
	$r = $admin->report($f);
    }
    elsif ($f =~ /(\S+)[\.\-](\w+)\.fasta/) { 
	$r = $admin->check_fasta_rfile($f);
    }
    elsif ($f =~ /(\S+)[\.\-](\w+)\.rdf\-xml/) {
	$r = $admin->check_rdfxml_rfile($f);
    }
    else {
	print STDERR "UNRECOGNIZED:$f\n";
    }
    print "\n-------------\nReport for file:$f\n-------------\n";
    print $r, "\n";
      
}
