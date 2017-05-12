package Tie::Google;

# ----------------------------------------------------------------------
# $Id: Google.pm,v 1.3 2003/04/01 14:48:34 dlc Exp $
# ----------------------------------------------------------------------
# Apparently, a few people thought this would be a neat idea.
# The initial email I recieved on the topic:
#
# From: Richard Soderberg <blog@crystalflame.net>
# Date: Thu, 13 Feb 2003 10:42:07 -0500
# To: darren@cpan.org
# Subject: Tie::Google?
#
# #perl found DBD::google recently.  I thought I'd point out that there'd
# also be a great market for Tie::Google.  =)
#
# my @results; tie @results, 'Tie::Google', $KEY, $saerch_string;
# do ... for my $result { grep { $_->{url} =~ /google.com/ } @results };
#
#  - R.
#
# To which I cavalierly responded with something ridiculous, like "OK".

use strict;
use vars qw($VERSION $DEBUG $DEFAULT_BATCH_SIZE);

use Carp qw(carp);
use Symbol qw(gensym);
use Net::Google;

# Offsets into the array-based object
sub KEY()     { 0 }     # The user's API key
sub TYPE()    { 1 }     # The tie type: SCALAR, ARRAY, HASH
sub QUERY()   { 2 }     # The query terms
sub OPTIONS() { 3 }     # Options tied in
sub DATA()    { 4 }     # Search results
sub GOOGLE()  { 5 }     # Net::Google instance

# Tie types that we support and have to differentiate between
sub SCALAR() { 0 }
sub ARRAY()  { 1 }
sub HASH()   { 2 }

$VERSION = 0.03;
$DEFAULT_BATCH_SIZE = 10 unless defined $DEFAULT_BATCH_SIZE;
$DEBUG = 0 unless defined $DEBUG;

# tie constructors
sub TIESCALAR { return shift->new(SCALAR, @_) }
sub TIEARRAY  { return shift->new(ARRAY, @_)  }
sub TIEHASH   { return shift->new(HASH, @_)   }

# ----------------------------------------------------------------------
# new($TYPE, $KEY, $query)
#
# Create a new Tie::Google instance.  This method should never be
# called by outside facing code, only by the TIEFOO methods.
#
# A Tie::Google instance maintains a few pieces of information:
#
#   0. The API key of the user
#
#   1. The type of tie (SCALAR, ARRAY, HASH)
#
#   2. The query
#
#   3. Options passed in
#
#   4. The results of the query.
#
#   5. The Net::Google instace, created with the API key (item 0)
#
# The interesting things happen here in new.  new must be passed a
# type, a key, and a query.  If the user is tieing a scalar ("I feel
# lucky"), then we are only interested in the first element returned
# by the search; if the user is tieing an array, then we want all of
# the elements; if the user is tieing a hash, then we want all of the
# elements of a number of searches.  My "solution" (heh heh heh) is to
# store all data in a hashref, indexed into the instance as DATA; if
# the user is tieing an array or scalar (Tie::Google treats them
# identically), then we store the results in the key named $KEY, so
# that we can treat all types of ties consistently; otherwise, search
# results are keyed by query.
# ----------------------------------------------------------------------
sub new {
    my ($class, $type, $KEY, $query, $options) = @_;
    $options = { } unless defined $options && ref($options) eq 'HASH';
    my $self = bless [ $KEY, $type, $query, $options, { }, undef, ] => $class;

    # Is $KEY actually a file?
    # I do this in DBD::google as well; perhaps there I should submit
    # a patch to Aaron so that Net::Google can do this directly.
    if (-e $KEY) {
        my $fh = gensym;
        open $fh, $KEY or die "Can't open keyfile $KEY for reading: $!";
        chomp($KEY = <$fh>);
        close $fh or die "Can't close keyfile $KEY: $!";

        $self->[KEY] = $KEY;
    }

    # Set some reasonable defaults search boundaries, and instantiate
    # the Net::Google instance.
    $options->{'starts_at'} = 0 unless defined $options->{'starts_at'};
    $options->{'max_results'} ||= $DEFAULT_BATCH_SIZE;

    $self->[GOOGLE] = Net::Google->new(key => $self->[KEY],
                                       debug => $options->{'debug'} || 0);

    # * If called from TIEHASH, then store the results keyed by
    #   search terms, otherwise keyed by $KEY
    #
    # * If called from TIESCALAR, we only want the first result.
    #
    # $self->[OPTIONS] contains starts_at and max_results.
    #
    if ($type == HASH) {
        $self->do_search($query, $query,
                         $self->[OPTIONS]->{'starts_at'},
                         $self->[OPTIONS]->{'max_results'});
    }
    elsif ($type == SCALAR) {
        $self->do_search($KEY, $query, 0, 1);
    }
    else {
        $self->do_search($KEY, $query,
                         $self->[OPTIONS]->{'starts_at'},
                         $self->[OPTIONS]->{'max_results'});
    }

    return $self;
}

# ----------------------------------------------------------------------
# do_search($store_as, $query)
#
# This is where all the Net::Google magic has to happen.
#
# do_search will use Net::Google to search for $query, and store the
# results in $self->[DATA]->{$store_as}.
# ----------------------------------------------------------------------
sub do_search {
    my ($self, $store_as, $query, $start, $num) = @_;

    # Preparation for the search
    #
    # do_search can conceivably be invoked with one argument,
    # in which case we use it both as search term and key into the
    # DATA hash.
    #
    # $start and $num will be taken from OPTIONS->{'starts_at'} and
    # OPTIONS->{'max_results'}, respectively, if they are not
    # provided.
    return unless $store_as;
    $query ||= $store_as;

    $start = $self->[OPTIONS]->{'starts_at'}
        unless defined $start;

    $num ||= $self->[OPTIONS]->{'max_results'};

    # The search
    my $search = $self->[GOOGLE]->search(%{ $self->[OPTIONS] });
    $search->query($query);
    $search->starts_at($start);
    $search->max_results($num);
    $self->[DATA]->{$store_as} = [
        map {
                +{  title               => $_->title(),
                    URL                 => $_->URL(),
                    snippet             => $_->snippet(),
                    cachedSize          => $_->cachedSize(),
                    directoryTitle      => $_->directoryTitle(),
                    summary             => $_->summary(),
                    hostName            => $_->hostName(),
                    directoryCategory   => $_->directoryCategory(),
                }
            } @{ $search->results }
    ];
}

# ----------------------------------------------------------------------
# is_scalar(), is_array(), is_hash()
#
# Utility methods; is the object a tied scalar, tied array, or tied hash?
# ----------------------------------------------------------------------
sub is_scalar { shift->[TYPE] == SCALAR }
sub is_array  { shift->[TYPE] == ARRAY  }
sub is_hash   { shift->[TYPE] == HASH   }

# ----------------------------------------------------------------------
# FETCH()       # scalar
# FETCH($int)   # array
# FETCH($key)   # hash
#
# In the case of a tied scalar or a tied array, the search should
# already have been performed.  In the case of a tied hash, that might
# not necessarily be the case, so we might have to do a search.
#
# Needed by tied scalar, tied hash, and tied array implementations.
# ----------------------------------------------------------------------
sub FETCH {
    my ($self, $index) = @_;
    $index = 0 unless defined $index;

    if ($self->is_hash) {
        $self->do_search($index, $index)
            unless exists $self->[DATA]->{$index};

        return $self->[DATA]->{$index};
    }

    return $self->[DATA]->{$self->[KEY]}->[$index];

}

# ----------------------------------------------------------------------
# EXISTS($item)
#
# Returns true if this item exists in the instances search results:
#
#   tie %g, "Tie::Google", $KEY, "perl";
#   print exists $g{"perl"};
#
#   tie @g, "Tie::Google", $KEY, "perl";
#   print exists $g[2]; # does this work?
#
# Needed for tied hash and tied array implementation.
# ----------------------------------------------------------------------
sub EXISTS {
    my ($self, $index) = @_;

    return exists $self->[DATA]->{$index}
        if $self->is_hash;

    return exists $self->[DATA]->{$self->[KEY]}->[$index];

}

# ----------------------------------------------------------------------
# CLEAR()
#
# Clears out the search results:
#
#   tie @g, "Tie::Google", $KEY, "perl";
#   @g = ();
#
#   tie %g, "Tie::Google", $KEY, "perl";
#   print $g{"apache"};
#   print $g{"python"};
#   %g = ();
#
# Needed by the tied hash and tied array interfaces.
# ----------------------------------------------------------------------
sub CLEAR {
    my $self = shift;

    return %{$self->[DATA]} = ()
        if $self->is_hash;

    return @{$self->[DATA]->{$self->[KEY]}} = ();
}

# ----------------------------------------------------------------------
# FIRSTKEY()
#
# Needed for each(%g).  This implementation is taken from Tie::Hash.
#
# NOTE: This only iterates over keys that are _already defined_! It
# _does not_ attempt to iterate over all of Google, or anything silly
# like that.  Although that would be great fun...
#
# Needed for tied hash implementation.
# ----------------------------------------------------------------------
sub FIRSTKEY {
    my $self = shift;
    my $a = scalar keys %{$self->[DATA]};
    each %{$self->[DATA]} 
}

# ----------------------------------------------------------------------
# NEXTKEY()
#
# Needed for each(%g).  This implementation is taken from Tie::Hash.
#
# See NOTE for FIRSTKEY.
#
# Needed for tied hash implementation.
# ----------------------------------------------------------------------
sub NEXTKEY {
    my $self = shift;
    each %{$self->[DATA]}
}

# ----------------------------------------------------------------------
# DELETE($index)
#
# Remove an item from the search results list.
#
# Needed for tied hash and tied array implementation.
# ----------------------------------------------------------------------
sub DELETE {
    my ($self, $index) = @_;

    return delete $self->[DATA]->{$index}
        if $self->is_hash;

    return delete $self->[DATA]->{$self->[KEY]}->{$index}
        if $self->is_array;
}

# ----------------------------------------------------------------------
# STORE($index, $value)
#
# Anyone calling this method either misunderstands Google or is
# intentionally attempting to push the limits of this module.
#
# Nothing should be able to store anything here, right?
#
# NOTE: This means that these instances are effectively static once
# they are initialized!
#
# Needed for tied scalar, tied array, and tied hash implementations.
# ----------------------------------------------------------------------
sub STORE { carp("Misguided attempt to modify Google's database") }

# ----------------------------------------------------------------------
# STORESIZE($count)
#
# Called when the user does:
#
#   $#g = 100;
#
# If $count > current number of elements, then extend the search.
# If $count < current number of elements, then drop some.
#
# Needed for tied array implementation.
# ----------------------------------------------------------------------
sub STORESIZE {
    my ($self, $count) = @_;
    my $arr = $self->[DATA]->{$self->[KEY]};
    my $cur_total = scalar @$arr;

    if ($count > $cur_total) {
        $self->do_search($self->[KEY], $self->[QUERY], 0, $count);
    }
    elsif ($count == $cur_total) {
        # la la la...
    }
    else {
        pop @$arr while @$arr > $count;
    }

    return $self->FETCHSIZE();
}

# ----------------------------------------------------------------------
# FETCHSIZE()
#
# Needed for tied array implementation.
# ----------------------------------------------------------------------
sub FETCHSIZE {
    my $self = shift;
    scalar @{$self->[DATA]->{$self->[KEY]}};
}

# ----------------------------------------------------------------------
# EXTEND($size)
#
# Called when the user does:
#
#   @g = 100;
#
# Needed for tied array implementation.
#
# XXX This implementation might not be right.
# ----------------------------------------------------------------------
sub EXTEND {
    shift->STORESIZE(@_)
}

# ----------------------------------------------------------------------
# PUSH($item)
#
# Needed for tied array implementation.
# ----------------------------------------------------------------------
sub PUSH {
    carp "Can't add results to Google's database -- do it the old " .
         "fashioned way, please!";
}

# ----------------------------------------------------------------------
# POP()
#
# Removes the last search result from the list of results, and
# returns it.
#
# Needed for tied array implementation.
# ----------------------------------------------------------------------
sub POP {
    my $self = shift;
    pop @{$self->[DATA]->{$self->[KEY]}};
}

# ----------------------------------------------------------------------
# SHIFT()
#
# Needed for tied array implementation.
# ----------------------------------------------------------------------
sub SHIFT {
    my $self = shift;
    shift @{$self->[DATA]->{$self->[KEY]}};
}

# ----------------------------------------------------------------------
# UNSHIFT($item)
#
# Needed for tied array implementation.
# ----------------------------------------------------------------------
sub UNSHIFT {
    carp "Trying to stick your results into the head of Google's ".
         "list, eh?  Shame on you!";
}

# ----------------------------------------------------------------------
# SPLICE($offset, $limit, @list)
#
# Needed for tied array implementation.
# ----------------------------------------------------------------------
sub SPLICE {
    my ($self, $offset, $limit) = @_;
    my $arr = $self->[DATA]->{$self->[KEY]};

    if (@_ > 3) {
        carp "Can't modify search results this way.  Please stuff ".
             "Google the old fashioned way.";
        return;
    }

    splice @$arr, $offset, $limit;
}

# ----------------------------------------------------------------------
# DESTROY()
#
#
# Needed by the tied hash, tied array, and tied scalar interfaces.
# ----------------------------------------------------------------------
sub DESTROY { }

1;

__END__

XXX The TIEARRAY implementation is incomplete
XXX The Net::Google integration is completely missing

Tests!

=head1 NAME

Tie::Google - Single-variable access to Google search results

=head1 SYNOPSIS

  my $KEYFILE = glob "~/.googlekey";
  my ($g, @g, %g);

  # Tied array interface
  tie @g, "Tie::Google", $KEYFILE, "perl";
  for my $r (@g) {
      printf " * <a href='%s'>%s</a>\n",
          $r->{'URL'}, $r->{'title'};
  }

  # Tied hash interface
  tie %g, "Tie::Google", $KEYFILE;
  for my $term (qw[ perl python ruby ]) {
      my $res = $g{$term};
      printf "%d results for '%s:\n", scalar @$res, $term;

      for my $r (@$res) {
          printf " * <a href='%s'>%s</a>\n",
              $r->{'URL'}, $r->{'title'};
      }
  }

  # Tied scalar interface: I Feel Lucky
  use LWP::Simple qw(getprint);
  tie $g, "Tie::Google", $KEYFILE, "perl";
  getprint($g->{'URL'});

=head1 USING Tie::Google

Using tied variables can make searching Google much simpler for
trivial programs.  C<Tie::Google> presents a simple interface to
Google's search API, using C<Net::Google> as the underlying transport
mechanism.  To use C<Tie::Google>, you must already be registered with
Google and have an API key.

You can tie scalars, arrays, or hashes to the C<Tie::Google> class;
each offers slightly different functionality, but all offer direct
access to Google search results.  The basic syntax of all types is:

  tie VAR, 'Tie::Google', $APIKEY, $QUERY, \%OPTIONS;

where:

=over 8

=item VAR

VAR is the variable name, which can be a scalar, array, or hash:

  tie $g, "Tie::Google", $KEY, $term;
  tie @g, "Tie::Google", $KEY, $term;
  tie %g, "Tie::Google", $KEY, $term;

=item $APIKEY

APIKEY is your Google API key or a file containing the key as the only
item on the first line; see
L<http://apis.google.com|http://apis.google.com> for details.

=item $QUERY

QUERY is your actual search term(s), as a string.  This can be
arbitrarily complex, up to the limits Google allows:

  tie $g, "Tie::Google", $KEY,
    "site:cnn.com allintitle:priest court -judas";

=item %OPTIONS

Any options specified in this hashref will be passed to the
Net::Google::Search instance.  Available options include C<starts_at>,
C<max_results>, C<ie>, C<oe>, and C<lr>.  See L<Net::Google>.

=back

=head2 The Tied Array Interface

Tieing an array to C<Tie::Google> gives you an array of search
results.  How many search results are returned depends on the value of
the C<max_results> option defined when the array was tied (or
$DEFAULT_BATCH_SIZE if C<max_results> was not set), though extending
the array of results can be done by growing the array.

  $#g = 20;

Will resize the result set to 20 results.  If there are more than 20,
the ones on the end will be popped off; if there are less than 20,
then more will be retrieved.

C<Tie::Google> supports all non-additive array operations, including
C<shift>, C<pop>, and the 3 argument form of C<splice> (not the 4
argument version).  Specifically unallowed are C<unshift>, C<push>,
and general assigment.

See L<"RESULTS"> for details about the individual search results.

=head2 The Tied Hash Interface

The tied hash interface is similar to the tied array interface, except
that there are a bunch of them.  Asking for a key in the hash %g
initiates a search to Google, with the specified key as the search
term:

  my $results = $g{'perl apache'};

This initiates a search with "perl apache" as the query.  $results is
a reference to an array of hashrefs (see L<"RESULTS"> for details
about said hashrefs).

Tied hashes support all hash functions, including C<each>, C<keys>,
and C<values>.  Deleting from the hash is allowed (it removes the
search results for the deleted terms), but adding to the hash is not.

There can be many sets of search results stored in a tied hash.  To
see what this looks like, try this:

  use Data::Dumper;
  my (%g, $KEY, $dummy);

  tie %g, "Tie::Google", $KEY;
  $dummy = $g{'perl'};
  $dummy = $g{'python'};
  $dummy = $g{'ruby'};

  print Dumper(tied(%g));

Also, for comparison, try:

  tie @g, "Tie::Google", $KEY, "perl";
  print Dumper(tied(@g));

If C<starts_at> or C<max_results> are specified during the C<tie>,
these options are carried over into new searches (when a new key is
requested from the hash), so plan accordingly.  If the C<max_value> is
set to 1000, for example, then every access of a new key is going to
contain 1000 elements, which will be pretty slow.

=head2 The Tied Scalar Interface

Do you feel lucky?  If so, tie a scalar to C<Tie::Google>:

  tie $g, "Tie::Google", $KEY, "python";

Will give you the top result.  This is conceptually similar to using
the "I Feel Lucky" button on Google.com's front search interface.

=head1 RESULTS

All results (values returned from these tied variables) are hash
references; the contents of these hashrefs are based on the
C<Net::Google::Response> class (see L<Net::Google::Response> for
details).  These elements currently are:

=over 4

=item *

title

=item *

URL

=item *

snippet

=item *

cachedSize

=item *

directoryTitle

=item *

summary

=item *

hostName

=item *

directoryCategory

=back

All keys are case sensitive, and return exactly what
L<Net::Google::Response> says they do (C<Tie::Google> does no
massaging of this data).






=head1 TODO / BUGS

This module is far from complete, or even fully thought out.  TODO
items currently include:

=over 4

=item *

The tests currently suck, to the point of embarrassment.  Don't
mention it, I'm a little sensitive about it.

=item *

Some of the behaviors are kind of wonky.  If anyone has any better
ideas, please let me know.  Patches demanded^Wwelcome^.

=item *

Tied arrays should get the next 10 results when you get to the end of
the array.  Currently, you have to manually extend the array using:

  $#g = 100;

to get 100 search results.

Although this technique will have the unfortunate side-effect of
trying to iterate through all the results in Google's database.

=item *

The tied hash interface should be implemented in terms of the tied
array interface.  That is, the values associated with each key (search
term) should be a reference to an array tied to C<Tie::Google>.  I
started doing it this way but it made my brain hurt.

=item *

Does there need to be a TIEHANDLE interface as well?  Hmmm...

  while (<$google>) {
      ...

=item *

Should returned search results be data structures (they are
currently), the actual C<Net::Google::Result> instances (where the
data is currently being derived from), or new objects in their own
right (e.g., C<Tie::Google::Result>)?  I see advantages to each path:
data structures would be simpler, passing on C<Result> objects without
modification would be faster, and using a new set of objects allows
new functionality to be added, for example useful stringification.

=back

=head1 SEE ALSO

L<Net::Google>, L<DBD::google>

=head1 AUTHOR

darren chamberlain (E<lt>darren@cpan.orgE<gt>), with some prompting
from Richard Soderberg.
