package Text::Categorize::Textrank;

use strict;
use warnings;
use Graph;
use Graph::Centrality::Pagerank;
use Data::Dump qw(dump);

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.51';
    @ISA         = qw(Exporter);
    @EXPORT      = qw(getTextrankOfListOfTokens);
    @EXPORT_OK   = qw(getTextrankOfListOfTokens);
    %EXPORT_TAGS = ();
}

#12345678901234567890123456789012345678901234
#Method to rank potential keywords of text.

=head1 NAME

C<Text::Categorize::Textrank> - Method to rank potential keywords of text.

=head1 SYNOPSIS

  use strict;
  use warnings;
  use Text::Categorize::Textrank;
  use Data::Dump qw(dump);
  my $listOfTokens = [ [qw(This is the first sentence)], [qw(Here is the second sentence)] ];
  my $hashOfTextrankValues = getTextrankOfListOfTokens(listOfTokens => $listOfTokens);
  dump $hashOfTextrankValues;

=head1 DESCRIPTION

C<Text::Categorize::Textrank> provides a routine for ranking the words in
text as potential keywords. It implements a version of the textrank algorithm
from the report I<TextRank: Bringing Order into Texts> by R. Mihalcea and P. Tarau.

=head1 ROUTINES

=head2 C<getTextrankOfListOfTokens>

The routine C<getTextrankOfListOfTokens> returns a hash reference containing the textrank value
for all the tokens in the lists provided; the textrank values sum to one. The textrank of a token
is its pagerank in the graph obtained by joining neighboring tokens with an edge, called the
token graph.

Usually, C<listOfTokens> should I<not> be applied to all the words of the text. The
complete textrank algorithm first filters the words in the text to only the nouns and adjectives.
See L<Text::Categorize::Textrank::En> to compute the textrank of English text.

=over

=item C<listOfTokens>

  listOfTokens => [[...], [...], ...[...]]

C<listOfTokens> is an array reference containing the list of tokens that are
to be ranked using textrank. Each list is also an array reference of tokens that should
correspond to the list of tokens in a sentence. For example,
C<[[qw(This is the first sentence)], [qw(Here is the second sentence)]]>.

=item C<edgeCreationSpan>

  edgeCreationSpan => 1

For each token in the C<listOfTokens>, C<edgeCreationSpan> is the number of successive
tokens used to make an edge in the token graph. For example, if
C<edgeCreationSpan> is two, then given the token sequence C<"apple orange pear">
the edges C<[apple, orange]> and C<[apple, pear]> will be added to the token
graph for the token C<apple>. The default is one.

Note that loop edges are ignored. For example,
if C<edgeCreationSpan> is two, then given the token sequence C<"daba daba doo">
the edge C<[daba, daba]> is disguarded but the edge C<[daba, doo]> is
added to the token graph.

=item C<directedGraph>

  directedGraph => 0

If C<directedGraph> is true, the textranks
are computed from the directed token graph, if false, they
are computed from the undirected version of the graph. The default is false.

=item C<dampeningFactor>

  dampeningFactor => 0.85

When computing the textranks of the token graph, the dampening factor
specified by C<dampeningFactor> will
be used; it should range from zero to one. The default is 0.85.

=begin html

The Wikipedia article on <a href="http://en.wikipedia.org/wiki/PageRank">pagerank</a> has a good explaination of the
<a href="http://en.wikipedia.org/wiki/PageRank#Damping_factor">dampening factor</a>.<br>&nbsp;

=end html

=item C<addEdgesSpanningLists>

  addEdgesSpanningLists => 1

If C<addEdgesSpanningLists> is true, then when building the token graph, links
between the tokens at the end of a list and the beginning of the next list
will be made. For example, for the lists C<[[qw(This is the first list)], [qw(Here is the second list)]]>
the edge C<[list, Here]> will be added to the token graph. The default is true.

=item C<tokenWeights>

  tokenWeights => {}

C<tokenWeights> is an optional hash reference that can provide a weight for a subset
of the tokens provided by C<listOfTokens>. If C<tokenWeights> is not defined for any token
in C<listOfTokens>, then each
token has a weight of one. If C<tokenWeights> is defined for
at least one node in the graph, then the default weight of any undefined
token is zero.

=back

=cut

sub getTextrankOfListOfTokens
{
  my %Parameters = @_;

  # if there are no lists, return undef.
  return undef unless exists $Parameters{listOfTokens};
  my $listOfTokens = $Parameters{listOfTokens};

  # edgeCreationSpan holds the number of sucessive tokens linked by an edge for each token.
  # for example, given tokens "apple orange pear", the edges [apple, orange] and [apple, pear]
  # will be created for token apple if $edgeCreationSpan is two.
  my $edgeCreationSpan = 1;
  $edgeCreationSpan = abs $Parameters{edgeCreationSpan} if (exists ($Parameters{edgeCreationSpan}));
  $edgeCreationSpan = 1 if ($edgeCreationSpan < 1);

  # set the type of graph built from the tokens to compute the textrank.
  $Parameters{undirected} = 1;
  $Parameters{undirected} = !$Parameters{directedGraph} if exists ($Parameters{directedGraph});

  # get the pagerank dampening factor.
  $Parameters{dampeningFactor} = 0.85 unless exists ($Parameters{dampeningFactor});
  $Parameters{dampeningFactor} = abs $Parameters{dampeningFactor};
  $Parameters{dampeningFactor} = 1 if ($Parameters{dampeningFactor} > 1);

  # set the addEdgesSpanningLists flag.
  my $addEdgesSpanningLists = 1;
  $addEdgesSpanningLists = $Parameters{addEdgesSpanningLists} if exists $Parameters{addEdgesSpanningLists};

  # build the graph of the links between tokens.
  my $graph = Graph->new(directed => !$Parameters{undirected});

  # if edges will span lists, make listOfTokens into just one list.
  if ($addEdgesSpanningLists)
  {
    my @allWords;
    foreach my $list (@$listOfTokens)
    {
      push @allWords, @$list;
    }
    $listOfTokens = [\@allWords];
  }

  # add all the edges to the graph.
  foreach my $list (@$listOfTokens)
  {
    # get the total tokens in the list.
    my $totalTokens = $#$list + 1;
    for (my $i = 0; $i < $totalTokens; $i++)
    {
      # since isolalted vertices are possible, add the vertex.
      # for example, if a list had only one token in it, it would
      # not be linked to any other token.
      $graph->add_vertex ($list->[0]);

      # get the index of the last token to link to the current token in
      # the list.
      my $lastToken = $i + $edgeCreationSpan + 1;
      $lastToken = $totalTokens if ($lastToken > $totalTokens);
      for (my $j = $i + 1; $j < $lastToken; $j++)
      {
        # skip loop edges.
        next if ($list->[$i] eq $list->[$j]);

        # create the edge.
        my @edge = ($list->[$i], $list->[$j]);

        # if the edge exists already, add to its weight.
        if ($graph->has_edge (@edge))
        {
          my $weight = $graph->get_edge_weight (@edge);
          $weight = 1 unless defined $weight;
          ++$weight;
          $graph->add_weighted_edge (@edge, $weight);
        }
        else
        {
          # edge does not exist, default edge weight is one.
          $graph->add_weighted_edge (@edge, 1);
        }
      }
    }
  }

  # get the pagerank computer.
  my $pageRankEngine = Graph::Centrality::Pagerank->new ();

  # set the parameter for inclusion of edge weights.
  $Parameters{useEdgeWeights} = 1;

  # set the node weights if provided.
  $Parameters{nodeWeights} = $Parameters{tokenWeights} if ((exists $Parameters{tokenWeights}) && (defined $Parameters{tokenWeights}));

  # compute and return the pagerank of the tokens.
  return $pageRankEngine->getPagerankOfNodes (%Parameters, graph => $graph);
}

=head1 INSTALLATION

To install the module run the following commands:

  perl Makefile.PL
  make
  make test
  make install

If you are on a windows box you should use 'nmake' rather than 'make'.

=head1 BUGS

Please email bugs reports or feature requests to C<bug-text-categorize-textrank@rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Categorize-Textrank>.  The author
will be notified and you can be automatically notified of progress on the bug fix or feature request.

=head1 AUTHOR

 Jeff Kubina<jeff.kubina@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2009 Jeff Kubina. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 KEYWORDS

categorize, keywords, keyphrases, nlp, pagerank, textrank

=head1 SEE ALSO

=begin html

This package implements the Textrank algorithm from the report
<a href="http://bit.ly/akSJok">TextRank: Bringing Order into Texts</a>
by <a href="http://www.cse.unt.edu/~rada/">Rada Mihalcea</a> and <a href="http://www.cse.unt.edu/~tarau/">Paul Tarau</a>;
which is related to <a href="http://en.wikipedia.org/wiki/PageRank">pagerank</a>.

=end html

L<Graph>, L<Graph::Centrality::Pagerank>, L<Log::Log4perl>, L<Text::Categorize::Textrank::En>

=cut

1;
# The preceding line will help the module return a true value
