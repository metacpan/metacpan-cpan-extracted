package obogaf::parser;

require 5.006;
our $VERSION= '0.001'; 
$VERSION= eval $VERSION;

use strict;
use warnings;
use Graph;

sub build_edges{
    my ($obofile)= @_;
    my ($namespace, $source, $destination, $pof, $res);
    if($obofile=~/.obo$/){ open IN, "$obofile" or die "cannot open $obofile"; }
    while(<IN>){
        chomp;
        next if $_=~/^\s*$/;
        if($_=~/^namespace:\s+(\D+)/){
            $namespace=$1;
        }elsif($_=~/^id:\s+(\D+\d+)/){
            $destination=$1;
        }elsif($_=~/^is_a:\s+(\D+\d+)/){
            $source=$1;
            if(defined $namespace){ $res .= "$namespace\t$source\t$destination\tis-a\n"; } else { $res .= "$source\t$destination\tis-a\n"; }
        }elsif($_=~/^relationship: part_of\s+(\D+\d+)/){
            $pof=$1;
            if(defined $namespace){ $res .= "$namespace\t$pof\t$destination\tpart-of\n"; } else { $res .= "$pof\t$destination\tpart-of\n"; }    
        }
    }
    close IN;
    return \$res;
}

sub build_subonto{
    my ($edgesfile, $namespace)= @_;
    my ($res);
    if($edgesfile=~/.gz$/){ open IN, "gunzip -c $edgesfile |" or die "cannot open $edgesfile";  } else { open IN, "$edgesfile" or die "cannot open $edgesfile"; }
    while(<IN>){
        next if $_=~/^\s*$/;
        my @vals= split(/\t/, $_);
        if($vals[0] eq $namespace){ $res .= join("\t", @vals[1..$#vals]); }
    }
    close IN;
    return \$res;
}

sub make_stat{
    my ($edgesfile, $parentIndex, $childIndex)= @_; 
    my (%indeg, %outdeg, %deg, $ed, $nd, $mindeg, $maxdeg, $medeg, $avgdeg, $den, $scc, $resdeg, $stat, $res);
    ## create graph
    my $g= Graph->new(directed => 1);
    open IN, $edgesfile;
    while(<IN>){
        chomp;
        my @vals= split(/\t/,$_);
        $g->add_edge($vals[$parentIndex], $vals[$childIndex]); 
    }
    close IN;
    ## compute indegree/outdegree/degree
    my @V= $g->vertices;
    foreach my $nd (@V){
        my $i= $g->in_degree($nd);
        my $o= $g->out_degree($nd);
        my $d= $i+$o;
        $indeg{$nd}=$i;
        $outdeg{$nd}=$o;
        $deg{$nd}=$d;
    }
    foreach my $node (sort{$deg{$b}<=>$deg{$a} or ($a cmp $b)} keys %deg){ $resdeg .= "$node\t$deg{$node}\t$indeg{$node}\t$outdeg{$node}\n"; }
    ## compute: median/max/min degree
    my @sortdeg= sort{$a<=>$b} values (%deg);
    my $len= $#sortdeg+1;
    my $mid = int $len/2;
    if($len % 2){ $medeg = $sortdeg[$mid]; }else{ $medeg = ( $sortdeg[$mid-1] + $sortdeg[$mid] ) / 2; }
    $medeg= sprintf("%.4f", $medeg);
    $mindeg= $sortdeg[0]; 
    $maxdeg= $sortdeg[$#sortdeg];
    ## compute number of nodes and edges
    $ed= $g->edges;
    $nd= $g->vertices; 
    ## compute average degree and density
    $avgdeg= $ed/$nd;
    $den= $ed / ( $nd * ($nd -1) );
    $avgdeg= sprintf("%.4f", $avgdeg);
    $den= sprintf("%.4e", $den);
    ## return stat
    $stat .= "nodes: $nd\nedges: $ed\nmax degree: $maxdeg\nmin degree: $mindeg\n";
    $stat .= "median degree: $medeg\naverage degree: $avgdeg\ndensity: $den\n";
    $res= "#oboterm <tab> degree <tab> indegree <tab> outdegree\n".$resdeg."\n"."~summary stat~\n".$stat;
    return $res;
}

sub gene2biofun{
    my ($annfile, $geneIndex, $classIndex)= @_;
    my (%gene2biofun, @genes, @biofun, $stat)= ();
    my ($sample, $oboterm)= (0)x2;
    if($annfile=~/.gz$/){ open IN, "gunzip -c $annfile |" or die "cannot open $annfile"; } else { open IN, "$annfile" or die "cannot open $annfile"; }
    while(<IN>){
        next if $_=~/^[!,#]|^\s*$/;
        chomp;  
        my @vals=split(/\t/,$_);
        push(@genes, $vals[$geneIndex]);
        push(@biofun, $vals[$classIndex]);
        $gene2biofun{$vals[$geneIndex]} .= $vals[$classIndex]."|";
    }
    close IN;
    foreach my $gene (keys %gene2biofun){ chop $gene2biofun{$gene}; }
    my %seen=();
    my @uniqgenes= grep{!$seen{$_}++} @genes;
    $sample= scalar(@uniqgenes); 
    undef %seen;
    my @uniqpbiofun= grep{!$seen{$_}++} @biofun;
    $oboterm= scalar(@uniqpbiofun);
    $stat .= "genes: $sample\nontology terms: $oboterm\n";
    return (\%gene2biofun, \$stat);
}

sub map_OBOterm_between_release{
    my ($obofile, $annfile, $classIndex)= @_;
    my (%altid, %oldclass, %old2new, $header, $id, $fln, $pair, $stat, $pstat); 
    my ($alt, $classes, $seen, $unseen)= (0)x4;
    ## step 0: pairing altid_2_id (key: alt_id) 
    if($obofile=~/.obo$/){ open IN, "$obofile" or die "cannot open $obofile"; }
    while (<IN>){
        chomp;
        next if $_=~/^\s*$/;
        if($_=~/^id:\s+(\D+\d+)/){ $id=$1; }
        if($_=~/^alt_id:\s+(\D+\d+)/){ $altid{$1}=$id; }
    }
    close IN;
    $alt= keys(%altid);
    # step 1: storing old ontology terms in a hash
    if($annfile=~/.gz$/){ open IN, "gunzip -c $annfile |" or die "cannot open $annfile"; } else { open IN, "$annfile" or die "cannot open $annfile"; }
    while(<IN>){
        chomp; 
        if($_=~/^[!,#]|^\s*$/){ $header .= "$_\n"; }
        next if $_=~/^[!,#]|^\s*$/;         
        my @vals=split(/\t/,$_); 
        $oldclass{$vals[$classIndex]}=$vals[$classIndex];
    }
    close IN;
    $classes= keys(%oldclass);
    ## step 2: mapping old GO terms to the new one using *alt_id* as key
    my $tmp= "";
    foreach my $k (sort{$a cmp $b} keys(%altid)){
        if($oldclass{$k}){
            $old2new{$k}=$altid{$oldclass{$k}};  ## pairing
            $seen++;
            $tmp= $altid{$oldclass{$k}};
        }else{
            $tmp= "unseen";
            $unseen++;
        }
        if($tmp ne "unseen"){
            $pair .= "$k\t$altid{$oldclass{$k}}\n";
        }
    }
    ## step 3: substitute ALT-ID with the updated ID, then the annotation file is returned.
    if($annfile=~/.gz$/){ open IN, "gunzip -c $annfile |" or die "cannot open $annfile"; } else { open IN, "$annfile" or die "cannot open $annfile"; }
    while(<IN>){
        chomp;
        next if $_=~/^[!,#]|^\s*$/;
        my @vals= split(/\t/, $_);
        my $oboterm= $vals[$classIndex];
        if($old2new{$oboterm}){
            $oboterm= $old2new{$oboterm};
            $_=~ s/$vals[$classIndex]/$oboterm/g;           
            $fln .= "$_\n";
        }else{
            $fln .= "$_\n";
        }
    }
    close IN;
    $fln = $header.$fln;
    ## print mapping stat
    $stat .= "Tot. ontology terms:\t$classes\nTot. altID:\t$alt\nTot. altID seen:\t$seen\nTot. altID unseen:\t$unseen\n";
    unless(not defined $pair){ 
        $pstat .= "#alt-id <tab> id\n$pair\n$stat"; 
        return (\$fln, \$pstat);
    }
    return (\$fln, \$stat);
}

1;

__END__

=pod

=encoding utf8

=head1 NAME
 
obogaf::parser

=head1 SYNOPSIS

use obogaf::parser;

my ($graph, $subonto, $stat, $res);
 
$graph= build_edges(obofile);

$subonto= build_subonto(edgesfile, namespace);

$stat= make_stat(edgesfile, parentIndex, childIndex);

($res, $stat)= gene2biofun(annfile, geneIndex, classIndex);

($res, $stat)= map_OBOterm_between_release(obofile, annfile, classIndex);

=head1 DESCRIPTION

B<obogaf::parser> is a perl5 module desinged to handle obo and gene association file. 

=over 2

=item 1. B<build_edges>: extract edges from an obo file. 
    
    my $graph= build_edges(obofile);

B<obofile>: any obo file listed in L<OBO foundry|http://www.obofoundry.org/>. The file extension must be ".obo".

B<output>: the graph is returned as tuple: C<subdomain E<lt>tabE<gt> source E<lt>tabE<gt> destination E<lt>tabE<gt> relationship>. This means that the graph is returned as a list of edges, where each edge is represented as a pair of vertices in the form C<source E<lt>tabE<gt> destination>. For each couple of nodes, the
subdomain (if any) and the relationships for which is safe group annotations (i.e. C<is_a> and C<part_of>) are returned as well. The graph is stored as an anonymous scalar.

=item 2. B<build_subonto>: extract edges of a specified sub-ontology domain.

    my $subonto= build_subonto(edgesfile, namespace);

B<edgesfile>: a graph in the form: C<subdomain E<lt>tabE<gt> source E<lt>tabE<gt> destination E<lt>tabE<gt> relationship>.
This file can be obtained by calling the subroutine C<build_edges>.

B<namespace>: name of the subontology for which the edges must be extracted.

B<output>: the graph is returned as a tuple>: C<source E<lt>tabE<gt> destination E<lt>tabE<gt> relationship>. In other words the graph is returned as a list of edges, where each edge is represented as a pair of vertices in the form C<source E<lt>tabE<gt> destination>. For each couple of nodes the relationships
C<is_a> and C<part_of> are also returned. The graph is stored as an anonymous scalar.

=item 3. B<make_stat>: make basic statistic on graph.

    my $stat= make_stat(edgesfile, parentIndex, childIndex);

B<edgesfile>: a graph represented as a list of edges, where each edge is stored as a pair of vertices E<lt>tabE<gt> separated. This file can be obtained by calling the subroutine C<build_edges>.

B<parentIndex>: index referring to the column containing the I<parent> (source) vertices in I<edgesfile> file.

B<childIndex>: index referring to the column containing the I<child> vertices (destination) in the I<edgesfile> file.

B<output>: statistics about the graph are printed on the shell. More precisely, for each vertex of the graph degree, in-degree and out-degree are printed. The vertex are sorted in a decreasing order on the basis of degree, from the higher degree to the smaller degree. Finally, the following
statistics are returned as well: 1) number of nodes and edges of the graph; 2) maximum and minimum degree; 3) average and median degree; 4) density of the graph.

=item 4. B<gene2biofun>: make annotations adjacency list.

    my ($res, $stat)= gene2biofun(annfile, geneIndex, classIndex);

B<annfile>: an annotations file. The file extension can be either plain format (".txt") or compressed (".gz"). An example of the format of this file can be taken from L<GOA website|ftp://ftp.ebi.ac.uk/pub/databases/GO/goa/> (file with ".gaf.gz" extension) or L<HPO website|http://compbio.charite.de/jenkins/job/hpo.annotations.monthly/lastSuccessfulBuild/artifact/annotation/ALL_SOURCES_ALL_FREQUENCIES_genes_to_phenotype.txt>.
More in general any file structured as those aforementioned can be used (basically a ".csv" file using <tab> as separator).

B<geneIndex>: index referring to the column containing the samples (genes/proteins).

B<classIndex>: index referring to the column containing the ontology terms. 

B<output>: a list of two anonymous references. The first is an anonymous hash storing for each gene (or protein) all the associated ontology terms (pipe separated). The second is an anonymous scalar containing basic statistics, such as the total unique number of genes/proteins and annotated ontology terms. 

=item 5. B<map_OBOterm_between_release>: map ontology terms between different releases.

    my ($res, $stat)= map_OBOterm_between_release(obofile, annfile, classIndex);

B<obofile>: an obo file (a new release). This file is used to make the C<alt_id - id> pairing, by using C<alt_id> as key. The file extension must be ".obo".

B<annfile>: an annotation file (an old release). The file extension can be either plain format (".txt") or compressed (".gz").

B<classIndex>: index referring to the column of the B<annfile> containing the ontology terms to be mapped.

B<output>: a list of two anonymous references. The first is an anonymous scalar storing the annotations file in the same format of the input file but with the obsolete ontology terms replaced with the I<updated> ones. The second reference is an anonymous scalar containing some basic statistics, such
as the total unique number of ontology terms and the total number of mapped and not mapped I<altID> ontology terms. Finally, all the found pairs C<alt_id - id> are returned (if any).

=back 

=head1 BUGS

Please report any bugs L<here|https://github.com/marconotaro/obogaf-parser/issues>.

=head1 COPYRIGHT

Copyright (C) 2019 Marco Notaro, all rights reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl 5 programming 
language system itself.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 AUTHOR

Marco Notaro (https://marconotaro.github.io)

=head1 SEE ALSO

A step-by-step tutorial showing how to apply B<obogaf::parser> to real case studies in Computational Biology and Precision Medicine is situated at the following link L<https://github.com/marconotaro/obogaf-parser>.

=cut

# yowza yowza yowza 
