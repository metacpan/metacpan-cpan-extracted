#!/usr/local/bin/perl

use strict;
use GO::Basic;
use GO::Dotty::Dotty;

use Getopt::Long;

my $w = 'text';
my $use_cache;
my $fmt;
GetOptions("write|w=s"=>\$w,
           "use_cache"=>\$use_cache,
           "format|parser|p=s"=>\$fmt,
           "help|h"=>sub{system("perldoc $0");exit 0},
          );

my $graph = parse({format=>$fmt,
                   use_cache=>$use_cache},shift @ARGV);
my $subgraph = $graph->subgraph({@ARGV});
unless ($subgraph->term_count) {
    print STDERR "No matching terms for: @ARGV\n";
    exit 1;
}

if ($w eq 'text') {
    $subgraph->to_text_output;
}
elsif ($w eq 'obo') {
    $subgraph->to_obo;
}
else {
    my $graphviz =
      GO::Dotty::Dotty::go_graph_to_graphviz( $subgraph,
                                              {node => {shape => 'box'},
                                              });
    print $graphviz->as_png;
}

exit 0;

__END__

=head1 NAME

go-export-graph.pl

=head1 SYNOPSIS

  go-export-graph.pl -w png ontology/gene_ontology.obo | display -

  go-export-graph.pl ontology/gene_ontology.obo 'acc' GO:0007610

  go-export-graph.pl ontology/so.obo 'name' 'protein'

=head1 DESCRIPTION

exports a graph as an indented ascii tree, PNG or OBO file

=head1 ARGUMENTS

after the file name you can optionally specify query constraint pairs; eg

 acc GO:0007610
 name 'cysteine biosynthesis'

=head1 OPTIONS

=head3 -w EXPORT_FORMAT

one of B<text>, B<obo> or B<png>

=head2 -use_cache

If this switch is specified, then caching mode is turned on.

With caching mode, the first time you parse a file, then an additional
file will be exported in a special format that is fast to parse. This
file will have the same filename as the original file, except it will
have the ".cache" suffix.

The next time you parse the file, this program will automatically
check for the existence of the ".cache" file. If it exists, and is
more recent than the file you specified, this is parsed instead. If it
does not exist, it is rebuilt.

=head2 DOCUMENTATION

L<http://www.godatabase.org/dev>

=head2 SEE ALSO

L<go2fmt.pl>

=cut

