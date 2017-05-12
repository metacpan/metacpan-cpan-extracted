#!/usr/local/bin/perl -w

BEGIN {
    if (defined($ENV{GO_ROOT})) {
	use lib "$ENV{GO_ROOT}/perl-api";
    }
}
use strict;
use GO::AppHandle;

if (!@ARGV) {
    print usage();
    exit;
}

use Getopt::Long;

my $apph = GO::AppHandle->connect(\@ARGV);
my $h = {};
GetOptions($h,
           "help=s",
           "all",
           "acc|a=s@",
           "fullheader",
           "skipnogo",
           "withname",
           "filter=s%",
           "speciesdb=s@",
           "evcode|e=s@",
);

if ($h->{help}) {
    print usage();
    exit;
}

if ($h->{evcode}) {
    $apph->filters->{evcodes} = $h->{evcode};
}
if ($h->{speciesdb}) {
    $apph->filters->{speciesdbs} = $h->{speciesdb};
}

my $prods;
if ($h->{all}) {
    $prods = $apph->get_all_product_with_seq_ids;
    printf STDERR "GOT %d prods\n", scalar(@$prods);
}
else {
    my $accs = $h->{acc};
    if (!$accs) {
	$accs = [@ARGV];
    }
    $prods = [];
    foreach my $acc (@$accs) {
	my $term = $apph->get_term({acc=>$acc});
	printf STDERR "%s\n", $term->as_str;
	my $curr_prods = $term->deep_product_list;
	push(@$prods, @$curr_prods);
    }
}

my $time = localtime(time);
for (my $i=0; $i<@$prods; $i++) {
    my $prod = $prods->[$i];
    if (!ref($prod)) { # is an id
	$prod = $apph->get_product({id=>$prod});
    }
    if ($i && !int($prods->[$i-1])) {
	# clear memory
	%{$prods->[$i-1]} = ();
    }
    my $seqs = $prod->seq_list;
    
    # longest by default
    my $longest;
    foreach my $seq (@$seqs) {
        if (!defined($longest) || $seq->length > $longest->length) {
            $longest = $seq;
        }
    }
    next unless $longest;
    my $seq = $longest;
    my ($sptr) = grep {lc($_->xref_dbname) eq "sptr" } @{$seq->xref_list};
    my $hdr =
      sprintf("%s|%s %s symbol:%s%s %s ",
              uc($prod->xref->xref_dbname),
              $prod->xref->xref_key,
              $sptr ? $sptr->as_str : "-",
              $prod->symbol,
              $prod->full_name ? ' "'.$prod->full_name.'"' : "",
              $prod->species ? sprintf("species:%s \"%s\"", $prod->species->ncbi_taxa_id, $prod->species->binomial) : '-',
             );
    if ($h->{fullheader}) {
        # TODO: faster way of doing this
        my $terms = $apph->get_terms({product=>$prod});
        next if $h->{skipnogo} && !@$terms;
        my @h_elts = ();
        foreach my $term (@$terms) {
            my $al = $term->selected_association_list;
            my %codes = ();
            map { $codes{$_->code} = 1 } map { @{$_->evidence_list} } @$al;
            my $t_extra = "";
            if ($h->{withname}) {
                $t_extra = sprintf(' "%s"', $term->name);
            }
            push(@h_elts,
                 sprintf("[%s%s evidence=%s]",
                         $term->public_acc,
                         $t_extra,
                         join(";", keys %codes),
                        )
                );
        }
        $hdr .= join(" ", @h_elts);
    }
    $hdr.= " ".
      join(" ",
           map {$_->as_str} @{$seq->xref_list});
    #        $hdr .= sprintf(" --- Exported on $time");
    $seq->description($hdr);
    print $seq->to_fasta;
}

sub usage {
    print "get-seqs.pl  [-d dbname] [-h dbhost] [-fullheader] [-dbms dbms] [-evcode code] [-all] GO_ID\n";
    print <<EOM;

This script will produce a fasta file of sequences, for all gene
products that are annotated to the specified GO ID. gene products
annotated to children of the specified GO ID are also included.

If you want a dump of all GO sequences, use the -all switch (you
probably want to use this in conjunction with the -fullheader switch)

The default behaviour is for a header including just the sequence
ID. To produce a full header including the full annotation for the
product, use the -fullheader switch.

NOTE: you must specify the connection parameters (dbname, dbhost)
before the other parameters.

 Examples:

(the following examples assume your mysql go database is running on
your local machine. if you are connectiong to a different one, use the
-h option)

this gets all sequences for products annotated to DNA Binding (also
includes all children of DNA binding, eg DNA Repair):

get-seqs.pl -d go_seq GO:0003677

gets all DNA Binding seqs, but only includes the sequence if the
product was annotated using mutant phenotype or genetic interaction
evidence:

get-seqs.pl -d go_seq -evcode IMP -evcode IGI GO:0003677

gets all DNA Binding seqs, excluding any kind of computational
evidence (note that you need the backslash because ! has a specific
meaning in unix):

get-seqs.pl -d go_seq -evcode '\\!IEA' -evcode '\\!ISS' GO:0003677

dumps a fasta file for every product with sequence in GO, with the
exception of Compugen gene products
(As of writing the Compugens were all IEA)

get-seqs.pl -d go_seq -h sin.lbl.gov -fullheader -all -speciesdb \!Compugen


NOTE: the default behaviour is exclude all associations that were made
with IEA evidence. You can override this if you like, but it is highly
recommended you do not, for obvious reasons of transitive propagation
of bad annotations. If you use the evcode switch you should be sure to read
 http://www.geneontology.org/GO.evidence.html

Get all sequences in GO:

get-seqs.pl -d go_seq -all -fullheader > myfasta.fa

EOM
}
