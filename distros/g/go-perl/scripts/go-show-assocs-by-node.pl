#!/usr/local/bin/perl

# POD docs at end of file

use strict;
use Getopt::Long;
use FileHandle;
use GO::Parser;
use Data::Stag;

$|=1;

my $opt = {};
GetOptions($opt,
	   "help|h",
           "format|p=s",
	   "err|e=s",
           "id=s@",
           "names",
           "use_cache",
           "count",
	  );

if ($opt->{help}) {
    system("perldoc $0");
    exit;
}

my $errf = $opt->{err};
my $errhandler = Data::Stag->getformathandler('xml');
if ($errf) {
    $errhandler->file($errf);
}
else {
    $errhandler->fh(\*STDERR);
}

my @ids = @{$opt->{id} || []};
if (!@ids) {
    print STDERR "specify id list with -id ID option\n";
    exit 1;
}

my $outer_parser = new GO::Parser({handler=>'obj'});
my $handler = $outer_parser->handler;
my @files = GO::Parser->new->normalize_files(@ARGV);
while (my $fn = shift @files) {
    my $fn = shift;
    my %h = %$opt;
    my $fmt;
    if ($fn =~ /\.obo/) {
        $fmt = 'obo_text';
    }
    if ($fn =~ /\gene_assoc/) {
        $fmt = 'go_assoc';
    }
    if ($fmt && !$h{format}) {
        $h{format} = $fmt;
    }
    my $parser = new GO::Parser(%h);
    $parser->handler($handler);
    #$parser->litemode(1);
    $parser->errhandler($errhandler);
    $parser->parse($fn);
}
my $g = $handler->graph;

foreach my $id (@ids) {
    if ($opt->{count}) {
        my $prods = $g->deep_product_list($id);
        printf STDERR "Count: %d\n", scalar(@$prods);
    } else {
        my $assocs = $g->deep_association_list($id);
        foreach my $assoc (@$assocs) {
            my $prod = $assoc->gene_product;
            my $evs = $assoc->evidence_list;
            my @codes = map {$_->code} @$evs;
            printf "%s %s %s\n", "@codes", $prod->xref->as_str, $prod->symbol;
        }
    }
}
$errhandler->finish;
exit 0;

__END__

=head1 NAME

go-show-assocs-by-node.pl - find association for a GO term

=head1 SYNOPSIS

  go-show-assocs-by-node.pl -id GO:0008021 gene_ontology.obo gene_associations.fb

=head1 DESCRIPTION


=head1 ARGUMENTS

=head3 -c

performs a count of gene products, rather than listing them

=head3 -e ERRFILE

writes parse errors in XML - defaults to STDERR
(there should be no parse errors in well formed files)

=head3 -p FORMAT

determines which parser to use; if left unspecified, will make a guess
based on file suffix. See below for formats

=head2 DOCUMENTATION

L<http://www.godatabase.org/dev>

=cut

