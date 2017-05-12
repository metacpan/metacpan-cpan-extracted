#!/usr/local/bin/perl -w

use strict;

use GO::Parser;
use GO::AppHandle;
use GO::SqlWrapper qw(:all);
use Getopt::Long;

# Get args

my $apph = GO::AppHandle->connect(\@ARGV);
my $dbh = $apph->dbh;
my $subset = "reference_genome";
my @bad = ();
my $num_loaded = 0;
my $f = shift;
open(F,$f) || die "cannot open $f";
my %id_by_acc = ();
my $sth = $dbh->prepare("INSERT INTO graph_path (term1_id,term2_id,relationship_type_id) VALUES (?,?,?)");
my $rows = $dbh->selectall_arrayref("SELECT acc,id FROM term");
foreach my $row (@$rows) {
  $id_by_acc{$row->[0]} = $row->[1];
}
printf STDERR "indexed %s terms\n", scalar(keys %id_by_acc);
while (<F>) {
    chomp;
    if (/^subject/) {
        next;
    }
    my ($subj,$rel,$obj,$type,$rtype) = split(/\t/,$_);
    my $rtype_id = lookup($rel);
    my $term2_id = lookup($subj);
    my $term1_id = lookup($obj);
    $sth->execute($term1_id,$term2_id,$rtype_id)
      if defined $rtype_id;
}
close(F);


#$dbh->disconnect;
print STDERR "Done!\n";
exit 0;

sub lookup {
    my $acc=shift;
    my $id = $id_by_acc{$acc};
    if (defined $id) {
        return $id;
    }
    if ($acc =~ /^OBO_REL:(.*)/) {
        return lookup($1);
    }
    #die "cannot find $acc";
    return undef;
}
