#!/usr/local/bin/perl

# POD docs at end of file

use strict;
use Getopt::Long;
use FileHandle;
use GO::AppHandle;

$|=1;


if (!@ARGV) {
    system("perldoc $0");
    exit 1;
}

use Getopt::Long;

my $apph = GO::AppHandle->connect(\@ARGV);
my $opt = {
           field=>"acc",
           cutoff=>0.1,
           min_gps=>2,
          };
GetOptions($opt,
	   "help|h",
           "input|i=s",
           "term_acc=s",
           "field=s",
           "filter=s%",
           "min_gps=s",
           "query=s",
           "cutoff=s",
           "speciesdb=s@",
           "evcode|e=s@",
	  );

$apph->filters($opt->{filter} || {});
if ($opt->{evcode}) {
    $apph->filters->{evcodes} = $opt->{evcode};
}
if ($opt->{speciesdb}) {
    $apph->filters->{speciesdbs} = $opt->{speciesdb};
}


if ($opt->{help}) {
    system("perldoc $0");
    exit;
}

my @ids = @ARGV;
my $input = $opt->{input};
if ($input) {
    open(F,$input);
    while(<F>) {
      s/^[\r\s]+//;
      s/[\r\s]+$//;
      s/[\r\s]+/\n/g;
      chomp;
      push(@ids,$_);
    }
    close(F);
}
my $field = $opt->{field};

my %exclude_term_by_acc = ();
my $term_acc = $opt->{term_acc};
if ($term_acc) {
    # co-enrichment
    my $gps =
      $apph->get_deep_products({term=>{acc=>$term_acc}},{product_only=>1});
    @ids = map {$_->id} @$gps;
    $field = 'id';
    my $g = $apph->get_graph_by_acc($term_acc);
    my $terms_in_graph = $g->get_all_terms;
    my $term = $g->get_term($term_acc);
    $exclude_term_by_acc{$_->acc}=1 foreach @$terms_in_graph;
    printf "Term: %s \"%s\" num_gps: %d\n",
      $term_acc, $term->name, scalar(@$gps);
}

my @constraints = map { {$field=>$_} } @ids;
if ($opt->{query}) {
    @constraints = eval $opt->{query};
}
my $eh = $apph->get_enriched_term_hash(\@constraints);
my @erows =
  sort {
      $a->{p_value} <=> $b->{p_value}
  } values %$eh;

if (!@erows) {
    print STDERR "No enriched terms found.\n";
    exit 0;
}
foreach (@erows) {
    next unless $_->{p_value} <= $opt->{cutoff};
    next if $_->{n_gps_in_sample_annotated} < $opt->{min_gps};

    if ($exclude_term_by_acc{$_->{term}->acc}) {
        print '*';
    }
    printf("%s %s \"%s\" sample:%d/%d background:%d/%d P-value:%s Corrected:%s Genes: %s\n",
           $_->{term}->acc,
           ont2code($_->{term}->term_type),
           $_->{term}->name,
           $_->{n_gps_in_sample_annotated},
           $_->{n_gps_in_sample},
           $_->{n_gps_in_background_annotated},
           $_->{n_gps_in_background},
           $_->{p_value},
           $_->{corrected_p_value},
           join('; ',map {sprintf("%s[%s:%s]", $_->symbol, $_->xref->xref_dbname, $_->acc)} @{$_->{gps_in_sample_annotated}}))
}
exit 0;

sub ont2code {
    my $ont = shift;
    return 'F' if $ont =~ /function/i;
    return 'P' if $ont =~ /process/i;
    return 'C' if $ont =~ /component/i;
}

__END__

=head1 NAME

go-find-enriched-terms.pl

=head1 SYNOPSIS

  go-find-enriched-terms.pl -d go -h localhost -field synonym YNL116W YNL030W YNL126W

  go-find-enriched-terms.pl -d go -h localhost -field acc -i gene-ids.txt

=head1 DESCRIPTION

Performs a term enrichment analysis. Uses hypergeometric distribution,
takes entire DAG into account.

First the database will be queried for matching gene products. Any
filters in place will be applied (or you can pass in a list of gene
products previously fetched, eg using $apph->get_products).

The matching products count as the *sample*. This is compared against
the gene products in the database that match any pre-set filters
(statistics may be more meaningful when a filter is set to a
particular taxon or speciesdb-source).

We then examine terms that have been used to annotate these gene
products. Filters are taken into account (ie if !IEA is set, then no
IEA associations will count). The DAG is also taken into account - so
anything annotated to a process will count as being annotated to
biological_process. This means the fake root "all" will always have
p-val=1. Currently the entire DAG is traversed, relationship types are
ignored (in future it may be possible to specify deduction rules -
this will be useful when the number of relations in GO progresses
beyond 2, or when this code is used with other ontologies)

Results are returned as a hash-of-hashes, outer hash keyed by term
acc, inner hash specifying the fields:


=head1 ARGUMENTS

Arguments are either connection arguments, generic to all go-db-perl
scripts, and arguments specific to this script

=head2 CONNECTION ARGUMENTS

Specify db connect arguments first; these are:

=over

=item -dbname [or -d]

name of database; usually "go" but you may want point at a test/dvlp database

=item -dbuser 

name of user to connect to database as; optional

=item -dbauth

password to connect to database with; optional

=item -dbhost [or -h]

name of server where the database server lives; see
http://www.godatabase.org/dev/database for details of which servers
are active. or you can just specify "localhost" if you have go-mysql
installed locally

=back

=head2 SCRIPT ARGUMENTS

=over

=item -field FIELDNAME

May be: acc, name, synonym

=item -input [or -i] FILE

a file of ids or symbols to search with; newline separated

=item -filter FILTER=VAL

see L<GO::AppHandle> for explanation of filters

multiple args can be passed:

  -filter taxid=7227 -filter 'evcode=!IEA'

Only associations which match the filter will be counted

=item -speciesdb SPECIESDB

filter by source database

multiple args can be passed

  -speciesdb SGD -speciesdb FB

=item -evcode [or -e] EVCODE

filter by evidence code

negative arguments can be passed

  -e '!IEA'

this opt can be passed multiple times:

  -e ISS -s IDA -e IMP

=item -cutoff P-VAL

p-value report threshold

=item -term_acc GO_ID

if this option is used, the gene product list is created by issuing a (transitive) query on this GO_ID.

For example:

  go-find-enriched-terms.pl -d go -term_acc GO:0006914

This will find terms that are correlated with "autophagy" (indirectly,
via finding terms enriched in the set of gene products annoated to
"autophagy")

=item -query PERL

See L<GO::AppHandle>

For example

  -query "{speciesdb=>'FB'}"

This will select all gene products from FlyBase, and look for statistical enrichment of associated terms against the entire database

(may take a while)

The following query will explicitly perform the analysis on Drosophila melanogaster, no matter what the data source:

  -query "{taxid=>7227}"

As you might expect, insect-specific terms are enriched:

  GO:0009993 sample:463/10045 database:468/186759 P-value:0 Corrected:0 "oogenesis (sensu Insecta)" 
  GO:0007456 sample:332/10045 database:338/186759 P-value:0 Corrected:0 "eye development (sensu Endopterygota)" 
  GO:0002165 sample:540/10045 database:555/186759 P-value:0 Corrected:0 "larval or pupal development (sensu Insecta)" 
  GO:0007455 sample:291/10045 database:295/186759 P-value:0 Corrected:0 "eye-antennal disc morphogenesis" 
  GO:0007560 sample:431/10045 database:440/186759 P-value:0 Corrected:0 "imaginal disc morphogenesis" 
  GO:0007292 sample:494/10045 database:627/186759 P-value:0 Corrected:0 "female gamete generation" 
  GO:0007444 sample:512/10045 database:527/186759 P-value:0 Corrected:0 "imaginal disc development" 
  GO:0048749 sample:278/10045 database:282/186759 P-value:0 Corrected:0 "compound eye development (sensu Endopterygota)" 
  GO:0048477 sample:484/10045 database:558/186759 P-value:0 Corrected:0 "oogenesis" 
  GO:0035214 sample:312/10045 database:316/186759 P-value:0 Corrected:0 "eye-antennal disc development" 

A more complex example:

  -query "{evcodes=>['IDA']}" -e '!IEA' -speciesdb FB

this will see if fly genes annotated via direct assay lead to enrichment of terms, considered against a background of all fly genes, excluding IEAs

(will take a long time)

=back

=head1 OUTPUT

The default output produces tab-delimited rows with the following data:

=head1 EXAMPLES


YBR009C
YKR010C
YGR099W
YDR224C

=head2 SEE ALSO

L<http://www.godatabase.org/dev>

L<GO::AppHandle>

=cut

