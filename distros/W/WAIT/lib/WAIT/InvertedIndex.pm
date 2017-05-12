#                              -*- Mode: Perl -*- 
# $Basename: InvertedIndex.pm $
# $Revision: 1.30 $
# Author          : Ulrich Pfeifer
# Created On      : Thu Aug  8 13:05:10 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Tue May  9 08:33:28 2000
# Language        : CPerl
# 
# (C) Copyright 1996-2000, Ulrich Pfeifer
# 

package WAIT::InvertedIndex;
use strict;
use DB_File;
use Fcntl;
use WAIT::Filter;
use Carp;
use vars qw(%FUNC);

my $O = pack('C', 0xff)."o";                  # occurances (document ferquency)

# The document frequency is the number of documents a term occurs
# in. The idea is that a term occuring in a significant part of the
# documents is not too significant.

my $M = pack('C', 0xff)."m";                  # maxtf (term frequency)

# The maximum term frequency of a document is the frequency of the
# most frequent term in the document.  It is related to the document
# length obviously.  A document in which the most frequnet term occurs
# 100 times is probably much longer than a document whichs most
# frequent term occurs five time.

sub new {
  my $type = shift;
  my %parm = @_;
  my $self = {};

  $self->{file}     = $parm{file}     or croak "No file specified";
  $self->{attr}     = $parm{attr}     or croak "No attributes specified";
  $self->{filter}   = $parm{filter};
  $self->{'name'}   = $parm{'name'};
  $self->{records}  = 0;
  for (qw(intervall prefix)) {
    if (exists $parm{$_}) {
      if (ref $parm{$_}) {
        $self->{$_} = [@{$parm{$_}}] # clone
      } else {
        $self->{$_} = $parm{$_}
      }
    }
  }
  bless $self, ref($type) || $type;
}

sub name {$_[0]->{'name'}}

sub _split_pos {
  my ($text, $pos) = @{$_[0]};
  my @result;

  $text =~ s/(^\s+)// and $pos += length($1);
  while ($text =~ s/(^\S+)//) {
    my $word = $1;
    push @result, [$word, $pos];
    $pos += length($word);
    $text =~ s/(^\s+)// and $pos += length($1);
  }
  @result;
}

sub _xfiltergen {
  my $filter = pop @_;

# Oops, we cannot overrule the user's choice. Other filters may kill
# stopwords, such as isotr clobbers "isn't" to "isnt".

#  if ($filter eq 'stop') {      # avoid the slow stopword elimination
#    return _xfiltergen(@_);            # it's cheaper to look them up afterwards
#  }
  if (@_) {
    if ($filter =~ /^split(\d*)/) {
      if ($1) {
        "grep(length(\$_->[0])>=$1, map(&WAIT::Filter::split_pos(\$_), " . _xfiltergen(@_) .'))' ;
      } else {
        "map(&WAIT::Filter::split_pos(\$_), " . _xfiltergen(@_) .')' ;
      }
    } else {
      "map ([&WAIT::Filter::$filter(\$_->[0]), \$_->[1]]," ._xfiltergen(@_) .')';
    }
  } else {
    if ($filter =~ /^split(\d*)/) {
      if ($1) {
        "grep(length(\$_->[0])>=$1, map(&WAIT::Filter::split_pos(\$_), [\$_[0], 0]))" ;
      } else {
        "map(&WAIT::Filter::split_pos(\$_), [\$_[0], 0])" ;
      }
    } else {
      "map ([&WAIT::Filter::$filter(\$_->[0]), \$_->[1]], [\$_[0], 0])";
    }
  }
}

sub parse_pos {
  my $self = shift;

  unless (exists $self->{xfunc}) {
    $self->{xfunc}     =
      eval sprintf("sub {%s}", _xfiltergen(@{$self->{filter}}));
    #printf "\nsub{%s}$@\n", _xfiltergen(@{$self->{filter}});
  }
  &{$self->{xfunc}}($_[0]);
}

sub _filtergen {
  my $filter = pop @_;

  if (@_) {
    "map(&WAIT::Filter::$filter(\$_), " . _filtergen(@_) . ')';
  } else {
    "map(&WAIT::Filter::$filter(\$_), \@_)";
  }
}

sub drop {
  my $self = shift;
  if ((caller)[0] eq 'WAIT::Table') { # Table knows about this
    my $file = $self->{file};

    ! (!-e $file or unlink $file);
  } else {                              # notify our database
    croak ref($self)."::drop called directly";
  }
}

sub open {
  my $self = shift;
  my $file = $self->{file};

  if (defined $self->{dbh}) {
    $self->{dbh};
  } else {
    $self->{func}     =
      eval sprintf("sub {grep /./, %s}", _filtergen(@{$self->{filter}}));
    $self->{dbh} = tie(%{$self->{db}}, 'DB_File', $file,
                       $self->{mode}, 0664, $DB_BTREE);
    $self->{cache} = {}
      if $self->{mode} & O_RDWR;
    $self->{cdict} = {}
      if $self->{mode} & O_RDWR;
    $self->{cached} = 0;
  }
}

sub insert {
  my $self  = shift;
  my $key   = shift;
  my %occ;

  defined $self->{db} or $self->open;
  grep $occ{$_}++, &{$self->{func}}(@_);
  my ($word, $noc);
  $self->{records}++;
  while (($word, $noc) = each %occ) {
    if (defined $self->{cache}->{$word}) {
      $self->{cdict}->{$O,$word}++;
      $self->{cache}->{$word} .= pack 'w2', $key, $noc;
    } else {
      $self->{cdict}->{$O,$word} = 1;
      $self->{cache}->{$word}  = pack 'w2', $key, $noc;
    }
    $self->{cached}++;
  }
  # This cache limit should be configurable
  $self->sync if $self->{cached} > 100_000;
  my $maxtf = 0;
  for (values %occ) {
    $maxtf = $_ if $_ > $maxtf;
  }
  $self->{db}->{$M, $key} = $maxtf;
}

# We sort postings by increasing max term frequency (~ by increasing
# document length.  This reduces the quality degradation if we process
# only the first part of a posting list.

sub sort_postings {
  my $self = shift;
  my $post = shift;             # reference to a hash or packed string

  if (ref $post) {
    # we skip the sort part, if the index is not sorted
    return pack('w*', %$post) unless $self->{reorg};
  } else {
    $post = { unpack 'w*', $post };
  }

  my $r = '';

  # Sort posting list by increasing ratio of maximum term frequency (~
  # "document length") and term frequency. This rati multipied by the
  # inverse document frequence gives the score for a term.  This sort
  # order can be exploited for tuning of single term queries.

  for my $did (sort {    $post->{$b} / $self->{db}->{$M, $b}
                                      <=>
                         $post->{$a} / $self->{db}->{$M, $a}
                    } keys %$post) {
    $r .= pack 'w2', $did, $post->{$did};
  }
  #warn sprintf "reorg %d %s\n", scalar keys %$post, join ' ', unpack 'w*', $r;
  $r;
}

sub delete {
  my $self  = shift;
  my $key   = shift;
  my %occ;

  my $db;
  defined $self->{db} or $self->open;
  $db = $self->{db};
  $self->sync;
  $self->{records}--;

  # less than zero documents in database?
  _complain('delete of document', $key) and $self->{records} = 0
    if $self->{records} < 0;

  grep $occ{$_}++, &{$self->{func}}(@_);

  for (keys %occ) {# may reorder posting list
    my %post = unpack 'w*', $db->{$_};
    delete $post{$key};
    $db->{$_}    = $self->sort_postings(\%post);
    _complain('delete of term', $_) if $db->{$O,$_}-1 != keys %post;
    $db->{$O,$_} = scalar keys %post;
  }
  delete $db->{$M, $key};
}

sub intervall {
  my ($self, $first, $last) = @_;
  my $value = '';
  my $word  = '';
  my @result;

  return unless exists $self->{'intervall'};

  defined $self->{db} or $self->open;
  $self->sync;
  my $dbh = $self->{dbh};       # for convenience

  if (ref $self->{'intervall'}) {
    unless (exists $self->{'ifunc'}) {
      $self->{'ifunc'} =
        eval sprintf("sub {grep /./, %s}", _filtergen(@{$self->{intervall}}));
    }
    ($first) = &{$self->{'ifunc'}}($first) if $first;
    ($last)  = &{$self->{'ifunc'}}($last) if $last;
  }
  if (defined $first and $first ne '') {         # set the cursor to $first
    $dbh->seq($first, $value, R_CURSOR);
  } else {
    $dbh->seq($first, $value, R_FIRST);
  }
  # We assume that word do not start with the character \377
  # $last = pack 'C', 0xff unless defined $last and $last ne '';
  return () if defined $last and $first gt $last; # $first would be after the last word
  
  push @result, $first;
  while (!$dbh->seq($word, $value, R_NEXT)) {
    # We should limit this to a "resonable" number of words
    last if (defined $last and $word gt $last) or $word =~ /^($M|$O)/o;
    push @result, $word;
  }
  \@result;                     # speed
}

sub prefix {
  my ($self, $prefix) = @_;
  my $value = '';
  my $word  = '';
  my @result;

  return () unless defined $prefix; # Full dictionary requested !!
  return unless exists $self->{'prefix'};
  defined $self->{db} or $self->open;
  $self->sync;
  my $dbh = $self->{dbh};
  
  if (ref $self->{'prefix'}) {
    unless (exists $self->{'pfunc'}) {
      $self->{'pfunc'} =
        eval sprintf("sub {grep /./, %s}", _filtergen(@{$self->{prefix}}));
    }
    ($prefix) = &{$self->{'pfunc'}}($prefix);
  }

  if ($dbh->seq($word = $prefix, $value, R_CURSOR)) {
    return ();
  }
  return () if $word !~ /^$prefix/;
  push @result, $word;

  while (!$dbh->seq($word, $value, R_NEXT)) {
    # We should limit this to a "resonable" number of words
    last if $word !~ /^$prefix/;
    push @result, $word;
  }
  \@result;                     # speed
}

=head2 search($query)

The search method supports a range of search algorithms.  It is
recommended to tune the index by calling
C<$table-E<gt>set(top=E<gt>1)> B<after> bulk inserting the documents
into the table.  This is a computing intense operation and all inserts
and deletes after this optimization are slightly more expensive.  Once
reorganized, the index is kept sorted automatically until you switch
the optimization off by calling C<$table-E<gt>set(top=E<gt>0)>.

When searching a tuned index, a query can be processed faster if the
caller requests only the topmost documents.  This can be done by
passing a C<top =E<gt>> I<n> parameter to the search method.

For single term queries, the method returns only the I<n> top ranking
documents.  For multi term queries two optimized algorithms are
available. The first algorithm computes the top n documents
approximately but very fast, sacrificing a little bit of precision for
speed.  The second algorithm computes the topmost I<n> documents
precisely.  This algorithm is slower and should be used only for small
values of I<n>.  It can be requested by passing the query attribute
C<picky =E<gt> 1>. Both algorithms may return more than I<n> hits.
While the picky version might not be faster than the brute force
version on average for modest size databases it uses less memory and
the processing time is almost linear in the number of query terms, not
in the size of the lists.

=cut

sub search {
  my $self  = shift;
  my $query = shift;

  defined $self->{db} or $self->open;
  $self->sync;
  $self->search_raw($query, &{$self->{func}}(@_)); # No call to parse() here
}

sub parse {
  my $self  = shift;

  defined $self->{db} or $self->open;
  &{$self->{func}}(@_);
}

sub keys {
  my $self  = shift;

  defined $self->{db} or $self->open;
  keys %{$self->{db}};
}

sub search_prefix {
  my $self  = shift;

  # print "search_prefix(@_)\n";
  defined $self->{db} or $self->open;
  $self->search_raw(map($self->prefix($_), @_));
}

sub _complain ($$) {
  my ($action, $term) = @_;

  require Carp;
  Carp::cluck
    (sprintf("WAIT database inconsistency during $action [%s]: ".
             "Please rebuild index\n",
             $term,));
}

sub search_raw {
  my $self  = shift;
  my $query = shift;
  my %score;

  # Top $wanted documents must be correct. Zero means all matching
  # documents.
  my $wanted = $query->{top};
  my $strict = $query->{picky};

  # Return at least $minacc documents. Zero means all matching
  # documents.
  # my $minacc = $query->{accus} || $wanted;

  # Open index and flush cache if necessary
  defined $self->{db} or $self->open;
  $self->sync;

  # We keep duplicates
  my @terms = 
    # Sort words by decreasing document frequency
    sort { $self->{db}->{$O,$a} <=> $self->{db}->{$O,$b} }
      # check which words occur in the index. 
      grep { $self->{db}->{$O,$_} } @_;

  return () unless @terms;                 # nothing to search for

  # We special-case one term queries here.  If the index was sorted,
  # choping off the rest of the list will return the same ranking.
  if ($wanted and @terms == 1) {
    my $term  = shift @terms;
    my $idf   = log($self->{records}/$self->{db}->{$O,$term});
    my @res;

    if ($self->{reorg}) { # or not $query->{picky}
      @res = unpack "w". int(2*$wanted), $self->{db}->{$term};
    } else {
      @res = unpack 'w*',                $self->{db}->{$term};
    }

    for (my $i=1; $i<@res; $i+=2) {
      $res[$i] /= $self->{db}->{$M, $res[$i-1]} / $idf;
    }

    return @res
  }

  # We separate exhaustive search here to avoid overhead and make the
  # code more readable. The block can be removed without changing the
  # result.
  unless ($wanted) {
    for (@terms) {
      my $df      = $self->{db}->{$O,$_};

      # The frequency *must* be 1 at least since the posting list is nonempty
      _complain('search for term', $_) and $df = 1 if $df < 1;

      # Unpack posting list for current query term $_
      my %post = unpack 'w*', $self->{db}->{$_};

      _complain('search for term', $_) if $self->{db}->{$O,$_} != keys %post;
      # This is the inverse document frequency. The log of the inverse
      # fraction of documents the term occurs in.
      my $idf = log($self->{records}/$df);
      for my $did (keys %post) {
        if (my $freq = $self->{db}->{$M, $did}) {
          $score{$did} += $post{$did} / $freq * $idf;
        }
      }
    }
    # warn sprintf "Used %d accumulators\n", scalar keys %score;
    return %score;
  }

  # A sloppy but fast algorithm for multiple term queries.
  unless ($strict) {
    for (@terms) {
      # Unpack posting list for current query term $_
      my %post = unpack 'w*', $self->{db}->{$_};

      # Lookup the number of documents the term occurs in (document frequency)
      my $occ  = $self->{db}->{$O,$_};

      _complain('search for term', $_) if $self->{db}->{$O,$_} != keys %post;
      # The frequency *must* be 1 at least since the posting list is nonempty
      _complain('search for term', $_) and $occ = 1 if $occ < 1;

      # This is the inverse document frequency. The log of the inverse
      # fraction of documents the term occurs in.
      my $idf = log($self->{records}/$occ);

      # If we have a reasonable number of accumulators, change the
      # loop to iterate over the accumulators.  This will compromise
      # quality for better speed.  The algorithm still computes the
      # exact weights, but the result is not guaranteed to contain the
      # *best* results.  The database might contain documents better
      # than the worst returned document.
      
      # We process the lists in order of increasing length.  When the
      # number of accumulators exceeds $wanted, no new documents are
      # added, only the ranking/weighting of the seen documents is
      # improved.  The resulting ranking list must be pruned, since only
      # the top most documents end up near their "optimal" rank.
      
      if (keys %score < $wanted) {
        for my $did (keys %post) {
          if (my $freq = $self->{db}->{$M, $did}) {
            $score{$did} += $post{$did} / $freq * $idf;
          }
        }
      } else {
        for my $did (keys %score) {
          next unless exists $post{$did};
          if (my $freq = $self->{db}->{$M, $did}) {
            $score{$did} += $post{$did} / $freq * $idf;
          }
        }
      }
    }
    return %score;
  }
  my @max; $max[$#terms+1]=0;
  my @idf;

  # Preparation loop.  This extra loop makes sense only when "reorg"
  # and "wanted" are true.  But at the time beeing, keeping the code
  # for the different search algorithms in one place seems more
  # desirable than some minor speedup of the brute force version.  We
  # do cache $idf though.

  for (my $i = $#terms; $i >=0; $i--) {
    local $_ = $terms[$i];
    # Lookup the number of documents the term occurs in (document frequency)
    my $df      = $self->{db}->{$O,$_};

    # The frequency *must* be 1 at least since the posting list is nonempty
    _complain('search for term', $_) and $df = 1 if $df < 1;

    # This is the inverse document frequency. The log of the inverse
    # fraction of documents the term occurs in.
    $idf[$i] = log($self->{records}/$df);

    my ($did,$occ);
    if ($self->{reorg}) {
      ($did,$occ) = unpack 'w2', $self->{db}->{$_};
    } else {                    # Maybe this costs more than it helps
      ($did,$occ) = unpack 'w2', $self->sort_postings($self->{db}->{$_});
    }
    my $freq      = $self->{db}->{$M, $did};
    my $max       = $occ/$freq*$idf[$i];
    $max[$i]      = $max + $max[$i+1];
  }

  # Main loop 
  for my $i (0 .. $#terms) {
    my $term = $terms[$i];
    # Unpack posting list for current query term $term. We loose the
    # sorting order because the assignment to a hash.
    my %post = unpack 'w*', $self->{db}->{$term};

    _complain('search for term', $term)
      if $self->{db}->{$O,$term} != keys %post;

    my $idf  = $idf[$i];
    my $full;                   # Need to process all postings
    my $chop;                   # Score necessary to enter the ranking list

    if (# We know that wanted is true since we especial cased the
        # exhaustive search.

        $wanted and

        # We did sort here if necessary in
        # the preparation loop
        # $self->{reorg} and

        scalar keys %score > $wanted) {
      $chop = (sort { $b <=> $a } values %score)[$wanted];
      $full = $max[$i] > $chop;
    } else {
      $full = 1;
    }

    if ($full) {
      # We need to inspect the full list. Either $wanted is not given,
      # the index is not sorted, or we don't have enough accumulators
      # yet.
      if (defined $chop) {
        # We might be able to avoid allocating accumulators
        for my $did (keys %post) {
          if (my $freq = $self->{db}->{$M, $did}) {
            my $wgt = $post{$did} / $freq * $idf;
            # We add an accumulator if $wgt exeeds $chop
            if (exists $score{$did} or $wgt > $chop) {
              $score{$did} += $wgt;
            }
          }
        }
      } else {
        # Allocate acumulators for each seen document.
        for my $did (keys %post) {
          if (my $freq = $self->{db}->{$M, $did}) {
            $score{$did} += $post{$did} / $freq * $idf;
          }
        }
      }
    } else {
      # Update existing accumulators
      for my $did (keys %score) {
        next unless exists $post{$did};
        if (my $freq = $self->{db}->{$M, $did}) {
          $score{$did} += $post{$did} / $freq * $idf;
        }
      }
    }
  }
  #warn sprintf "Used %d accumulators\n", scalar keys %score;
  %score;
}

sub set {
  my ($self, $attr, $value) = @_;

  die "No such indexy attribute: '$attr'" unless $attr eq 'top';

  return delete $self->{reorg} if $value == 0;

  return if     $self->{reorg};     # we are sorted already
  return unless $self->{mode} & O_RDWR;
  defined $self->{db} or $self->open;

  $self->sync;
  while (my($key, $value) = each %{$self->{db}}) {
    next if $key =~ /^\377[om]/;
    $self->{db}->{$key} = $self->sort_postings($value);
  }
  $self->{reorg} = 1;
}

sub sync {
  my $self = shift;

  if ($self->{mode} & O_RDWR) {
    print STDERR "Flushing $self->{cached} postings\n" if $self->{cached};
    while (my($key, $value) = each %{$self->{cache}}) {
      if ($self->{reorg}) {
        $self->{db}->{$key} = $self->sort_postings($self->{db}->{$key}
                                                   . $value);
      } else {
        $self->{db}->{$key} .= $value;
      }
    }
    while (my($key, $value) = each %{$self->{cdict}}) {
      $self->{db}->{$key} = 0 unless  $self->{db}->{$key};
      $self->{db}->{$key} += $value;
    }
    $self->{cache}  = {};
    $self->{cdict}  = {};
    $self->{cached} = 0;
  }
}

sub close {
  my $self = shift;

  if ($self->{dbh}) {
    $self->sync;
    delete $self->{dbh};
    untie %{$self->{db}};
    delete $self->{db};
    delete $self->{func};
    delete $self->{cache};
    delete $self->{cached};
    delete $self->{cdict};
    delete $self->{pfunc} if defined $self->{pfunc};
    delete $self->{ifunc} if defined $self->{ifunc};
    delete $self->{xfunc} if defined $self->{xfunc};
  }
}

1;

