package dtRdr::Search::Book;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;
use Carp;


use Regexp::PosIterator;

use dtRdr::Logger;

use constant {
  result_class => 'dtRdr::Search::Result::Book'
};

{
  package dtRdr::Search::Result::Book;
  use base 'dtRdr::Search::Result';
  use dtRdr::Accessor;
  dtRdr::Accessor->ro qw(
    start_node
    selection
    null
  );
}
# the null result object will never change, so we preconstruct it
use constant {
  NULL_RESULT => __PACKAGE__->result_class->new(null => 1)
};

use Class::Accessor::Classy;
ro qw(
  book
  quick_searcher
  find
  _finder
);
rw 'no_quick';
no  Class::Accessor::Classy;

=head1 NAME

dtRdr::Search::Book - Search a book

=head1 ABOUT

This class lets you setup a search for a given book and then churns out
results.

=head1 SYNOPSIS

  my $searcher = dtRdr::Search::Book->new(
    book => $book,
    find => qr/foo/i
  );

  while(my $res = $searcher->next) {
    # it might return null result
    $res->null and next;
    my $node = $res->start_node;
    my $sel = $res->selection;
    my $sel_node = $sel->node;
  }

=cut

=head1 Quick Search

The default behavior is to do a slow and careful search of the node
characters for each node returned by the book's C<visible_nodes()>
method.  Because this uses the book API, it is extremely generic, but
depending on the book, may also be extremely slow.

To speed-up the process, we have a quick-search scheme which allows the
book to eliminate all nodes which do not match.

If the book has a C<searcher()> method, it should return a subref (maybe
later we'll support and object there.)

The subref will be called again and again until it returns undef.  It
should return true or a dtRdr::TOC object until it is done.  The
thus-gathered TOC objects will be the only nodes searched more
thoroughly.

=head1 Constructor

=head2 new

  my $search = dtRdr::Search::Book->new(
    book => $book,
    find => qr/foo/i
  );

=cut

sub new {
  my $class = shift;
  ref($class) and croak("not an object method");
  my (@args) = @_;
  (@args % 2) and croak('odd number of elements in argument list');
  my %opts = @args;

  ($opts{find} and ((ref($opts{find}) || '') eq 'Regexp')) or
    croak('must have a find argument which is a Regexp');

  my $self = {%opts};
  bless($self, $class);
  $self->_init;
  return($self);
} # end subroutine new definition
########################################################################

=head2 new_result

XXX this, and the generation of the custom result class, should be
provided by the dtRdr::Search base class.

  my $result = $self->new_result(%args);

=cut

sub new_result {
  my $self = shift;
  return($self->result_class->new(@_));
} # end subroutine new_result definition
########################################################################

=head2 _init

  $self->_init;

=cut

sub _init {
  my $self = shift;

  $self->{_did_init} and croak('cannot init twice');

  my $book = $self->book or croak('cannot init without book');

  # get a list of searchable nodes
  my @search_nodes = $book->visible_nodes;

  # which need to be mapped to their real nodes
  my %node_map;
  foreach my $toc (@search_nodes) {
    my $switch = $book->find_toc($toc->id);
    if(exists($node_map{$switch})) {
      # maybe not so severe, but at least ick
      croak("book has two visible nodes with the same target");
    }
    $node_map{$switch} = $toc;
    $toc = $switch;
  }

  L->info('visible node list ', scalar(@search_nodes), ' nodes long');

  # TODO an option for the user to disable the quick search?
  # some books might be wrong about where there are or aren't hits
  if(! $self->no_quick and $book->can('searcher')) {
    $self->{quick_searcher} = $book->searcher($self->find);
    # we're only going to search what the book tells us to search
    # NOTE that the above mapping and planning are still
    $self->{_search_nodes} = [];
  }

  my @keepers;
  # now eliminate the descendants so we can put together a mandate
  # but only if we're not doing quick-search
  unless($self->quick_searcher) {
    my %skiplist;
    foreach my $node (@search_nodes) {
      $skiplist{$node} and next;
      #L->debug('examine ' . $node->id);
      # searching $node makes us hit all of these
      foreach my $d ($book->descendant_nodes($node)) {
        $skiplist{$d} = 1;
      }
      push(@keepers, $node);
    }
    L->info('got a search mandate ', scalar(@keepers), ' nodes long');
  }
  @search_nodes = @keepers;

  # this is our mandate of what to search
  $self->{_search_nodes} = \@search_nodes;

  # we'll need this to return start_node in results
  $self->{_node_map} = \%node_map;

  $self->{_did_init} = 1;
} # end subroutine _init definition
########################################################################

=head1 Methods

=head2 next

Perform the next search.

  my $result = $search->next;

Returns undef when done, and otherwise a dtRdr::Search::Result::Book
object.

If $result->null is true, then nothing was found, but the end of the
current node has been reached.  This gives you a chance to do something
else before diving into the next search.  (If we didn't do it this way,
searching a large book with no hits would block until it was completely
done.)

=cut

sub next {
  my $self = shift;

  # first finish quick search
  return($self->quick_next) if($self->quick_searcher);

  my $finder = $self->_finder;
  unless($finder) { # create one
    my $node = $self->_node;
    $node or return;


    my $find = $self->find;
    my $chars = $self->book->get_NC($node);
    # TODO skip
    unless(length($chars)) {
      L->debug("no characters for ", $node->id);
      delete($self->{_node});
      return($self->NULL_RESULT);
    }
    L->debug('look ' . $node->id . ' (' . length($chars) . ' characters)');
    #L->debug("search this: '$chars'");
    $finder =
      $self->{_finder} = Regexp::PosIterator->new($find, $chars);
  }

  # do the search
  if(my @match = $finder->match) {
    my $node = $self->_node;
    L->debug("match (@match) in ", $node->id);

    my $range = $self->book->reduce_word_scope($node, @match);
    # lookup the visible node
    my $orig_node = $self->result_node($range->node);

    # turn that into a selection object
    return($self->new_result(
      selection => dtRdr::Selection->claim($range),
      start_node => $orig_node,
    ));
  }
  else {
    # need to move on
    delete($self->{_node});
    delete($self->{_finder});
    return($self->NULL_RESULT);
  }
} # end subroutine next definition
########################################################################

=head2 quick_next

  $self->quick_next;

=cut

sub quick_next {
  my $self = shift;

  my $searcher = $self->{quick_searcher};
  my $res = $searcher->();
  if($res) {
    unless(eval {$res->isa('dtRdr::TOC')}) {
      # answer is true-but-not-a-node (e.g. the book wants to try again)
      0 and WARN 'hit nothing';
      return($self->NULL_RESULT);
    }
    # TODO this isn't forgiving enough, so I guess just let it through
    # unless($self->{_node_map}{$res}) {
    #   WARN "node ", $res->id, " isn't searchable";
    #   return($self->NULL_RESULT);
    # }
    push(@{$self->{_search_nodes}}, $res);
    # TODO return an "empty" result, which has a node name, but no
    # information -- this would allow the interface to start populating
    # a tree while we keep looking
    return($self->NULL_RESULT);
  }
  else {
    delete($self->{quick_searcher});
    # TODO $self->progress(0.1); ?
    0 and WARN 'quicksearch done (' ,
      scalar(@{$self->{_search_nodes}}), ' hits.)',
      (1 ?  ('  Hit',
        join("\n  ",
          '',
          map({$_->title . " (" . $_->id . ")"}
            @{$self->{_search_nodes}}
          )
        ), "\n  "
      ) : '');
    # now we need to plan the search to avoid redundancy
    {
      my %hit;
      my $book = $self->book;
      foreach my $node (@{$self->{_search_nodes}}) {
        $hit{$node} and next; # save a call
        $hit{$_} = 1 for($book->descendant_nodes($node));
      }
      # We have to run this whole list because a parent might have come
      # in after the child hit.
      # NOTE:  The quicksearch is allowed to return duplicate results,
      # so we need to whittle those too.
      $self->{_search_nodes} = [
        grep({!$hit{$_} ? ($hit{$_} = 1) : 0 }
          @{$self->{_search_nodes}}
        )
      ];
    }
    0 and WARN 'got a plan (' ,
      scalar(@{$self->{_search_nodes}}), ' hits.)',
      (1 ?  ('  Hit',
        join("\n  ",
          '',
          map({$_->title . " (" . $_->id . ")"}
            @{$self->{_search_nodes}}
          )
        ), "\n  "
      ) : '');
    return($self->NULL_RESULT);
  }
} # end subroutine quick_next definition
########################################################################

=head2 result_node

  my $orig_node = $self->result_node($range->node);

=cut

sub result_node {
  my $self = shift;
  my ($want_node) = @_;

  my $node = $want_node;

  my $map = $self->{_node_map};
  L->debug("lookup $node (", $node->id, ")");
  my $result = $map->{$node};
  # look at ancestor nodes
  unless($result) {
    foreach my $anc ($self->book->ancestor_nodes($node)) {
      last if($result = $map->{$anc});
    }
  }
  # and invalidate the result if we lose it.
  $result or
    die "all the way up and no hit for ", $want_node->id;
  return($result);
} # end subroutine result_node definition
########################################################################

=head2 _node

Returns the node which is currently being searched.

  my $node = $self->_node;

=cut

sub _node {
  my $self = shift;

  exists($self->{_node}) and return($self->{_node});

  my $nodes = $self->{_search_nodes};
  $nodes or Carp::confess('should have had nodes here');

  return($self->{_node} = shift(@$nodes));
} # end subroutine _node definition
########################################################################



=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 COPYRIGHT

Copyright (C) 2006 Eric L. Wilhelm and OSoft, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

The dotReader(TM) is OSI Certified Open Source Software licensed under
the GNU General Public License (GPL) Version 2, June 1991. Non-encrypted
and encrypted packages are usable in connection with the dotReader(TM).
The ability to create, edit, or otherwise modify content of such
encrypted packages is self-contained within the packages, and NOT
provided by the dotReader(TM), and is addressed in a separate commercial
license.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

=cut

# vi:ts=2:sw=2:et:sta
1;
