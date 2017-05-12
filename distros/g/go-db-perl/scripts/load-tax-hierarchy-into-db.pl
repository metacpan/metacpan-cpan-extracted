#!/usr/local/bin/perl -w

use strict;

use GO::Parser;
use GO::AppHandle;
use GO::SqlWrapper qw(:all);
use Getopt::Long;

# taxonomy must have already been loaded using load-tax-into-db.pl
# use the file nodes.dmp

# Get args

my $apph = GO::AppHandle->connect(\@ARGV);

my $noparent;
my $nowalk;
my $nowarn;
while (@ARGV && $ARGV[0] =~ /^\-/) {
    my $arg = shift @ARGV;
    if ($arg eq '--noparent') { 
        $noparent=1;
    }
    elsif ($arg eq '--nowalk') { 
        $nowalk=1;
    }
    elsif ($arg eq '--nowarn') { 
        $nowarn=1;
    }
    else {
        die "do not understand option: $arg";
    }
}

my $dbh = $apph->dbh;

# adapted from
# http://www.oreillynet.com/pub/a/network/2002/11/27/bioconf.html?page=1

my $rows = $dbh->selectall_arrayref("SELECT ncbi_taxa_id,id FROM species");
my %idh = ();
foreach (@$rows) {
    $idh{$_->[0]} = $_->[1];
}

my $fn = shift @ARGV || 'nodes.dmp';

print STDERR "reading $fn\n";
open(F,$fn) || die($fn);
my %parenth = ();
my %rankh = ();
while (<F>) {
    my ($node,$parent,$rank) = split(/\s*\|\s*/,$_);
    $parenth{$node} = $parent;
    $rankh{$node} = $rank;
}
close(F);
print STDERR "read $fn\n";

unless ($noparent) {

    my $setparent  = $dbh->prepare("UPDATE species
                              SET parent_id = ?
                              WHERE id = ?");
    foreach my $node (keys %parenth) {
        next if $node == 1;
        my $parent = $parenth{$node};
        my $node_id = $idh{$node};
        if (!$node_id) {
            print STDERR "tax: $node not in db\n" unless $nowarn;
            next;
        }
        my $parent_id = $idh{$parent};
        if (!$parent_id) {
            print STDERR "tax: $parent not in db\n" unless $nowarn;
            next;
        }
        $setparent->execute($parent_id,$node_id);    
    }

    print STDERR "done setting parents\n";
}

my $children = $dbh->prepare("SELECT id
                              FROM species
                              WHERE parent_id = ?");
my $setleft  = $dbh->prepare("UPDATE species
                              SET left_value = ?
                              WHERE id = ?");
my $setright = $dbh->prepare("UPDATE species
                              SET right_value = ?
                              WHERE id = ?");

my %childh = ();
my $ctr = 1;
#my $rootid = select_val($dbh,'species','ncbi_taxa_id=1','id');
my $rootid = 1;
unless ($nowalk) {
    foreach (keys %parenth) {
        next if $_ == 1;
        my $p = $parenth{$_};
        push(@{$childh{$p}},$_);
    }
    walktree($rootid);
}


$dbh->disconnect;
print STDERR "Done!\n";
exit 0;

sub walktree {
    my $id = shift;
    my $iid = $idh{$id};
    #print STDERR "id=$id $iid\n";
    if ($iid) {
        $setleft->execute($ctr, $iid);
    }
    else {
        print STDERR "tax $id not in db\n" unless $nowarn;
    }
    $ctr++;
    #$children->execute($id);
    #while(my ($id) = $children->fetchrow_array) {
    foreach my $cid (@{$childh{$id} || []}) {
        walktree($cid);
    }
    if ($iid) {
        $setright->execute($ctr, $iid);
    }
    $ctr++;
}

