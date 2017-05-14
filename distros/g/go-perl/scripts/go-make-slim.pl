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
           "min|m=s",
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
my $subg = GO::Model::Graph->new;

my $min = $opt->{min} || 1;
my %ok = ();
foreach my $term (@{$g->get_all_terms}) {
    my $id = $term->acc;
    my $n = scalar(@{$g->deep_product_list($id)});
    if ($n >= $min) {
        #print STDERR "OK: $id [c=$n]\n";
        $ok{$id} = 1;
    }
}
foreach my $term (@{$g->get_all_terms}) {
    my $id = $term->acc;

    if($ok{$id}) {
    }
    else {
        #print STDERR "XX: $id\n";
        $g->delete_node($id);
    }
}
$g->export({format=>$opt->{to} || 'obo'});

$errhandler->finish;
exit 0;

__END__

=head1 NAME

go-make-slim.pl - generates a slim file based on association file

=head1 SYNOPSIS

  go-show-assocs-by-node.pl gene_ontology.obo gene_associations.fb

=head1 DESCRIPTION



=head1 ARGUMENTS

=head3 -m

minimum number of distinct gene products a node must have attached
at-or-below that node for it to be included in the slim

=head3 -e ERRFILE

writes parse errors in XML - defaults to STDERR
(there should be no parse errors in well formed files)

=head2 DOCUMENTATION

L<http://www.godatabase.org/dev>

=cut

