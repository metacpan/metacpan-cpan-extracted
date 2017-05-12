###############################################################################
#
# This file copyright (c) 2006-2008 by Randy J. Ray, all rights reserved
#
# See "LICENSE" in the documentation for licensing and redistribution terms.
#
###############################################################################
#
#   $Id: Iterator.pm 47 2008-04-06 10:12:34Z  $
#
#   Description:    This class provides an iterator in the spirit of chapter 4
#                   of "Higher Order Perl", by Mark-Jason Dominus. Not all of
#                   this class follows his style to the letter, but the
#                   concepts here have their basis there.
#
#                   The role of the Iterator is to encapsulate a set of
#                   records returned by a call to the isbndb.com service. The
#                   set may be a disjoint set, such as the authors or subjects
#                   associated with a book. Or, the results may be from a call
#                   to a class' search() method, which can return potentially
#                   hundreds of records.
#
#   Functions:      BUILD
#                   first
#                   next
#                   all
#                   fetch_next_page
#                   reset
#
#   Libraries:      Class::Std
#                   Error
#
#   Global Consts:  $VERSION
#
###############################################################################

package WebService::ISBNDB::Iterator;

use 5.006;
use strict;
use warnings;
use vars qw($VERSION);

use Class::Std;
use Error;

use WebService::ISBNDB::API;

$VERSION = "0.10";

my %total_results   : ATTR(:name<total_results>   :default<0> );
my %page_size       : ATTR(:name<page_size>       :default<10>);
my %page_number     : ATTR(:name<page_number>     :default<1> );
my %shown_results   : ATTR(:name<shown_results>   :default<0> );
my %contents        : ATTR(:name<contents>        :default<>  );
my %request_args    : ATTR(:get<request_args>                 );
my %index           : ATTR(:name<index>           :default<0> );
my %agent           : ATTR(:name<agent>           :default<>  );
my %fetch_page_hook : ATTR(:name<fetch_page_hook> :default<>  );
my %first_contents  : ATTR;

###############################################################################
#
#   Sub Name:       BUILD
#
#   Description:    Check for an "agent" argument, and get the default agent
#                   if there is none. Also assign "request_args", as it does
#                   not have an explicit settor. Lastly, default "contents" to
#                   an empty array-ref.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $id       in      scalar    The unique ID for the object
#                   $args     in      hashref   The arguments passed to new()
#
#   Globals:        %agent
#                   %request_args
#
#   Returns:        Success:    $self
#                   Failure:    throws Error::Simple
#
###############################################################################
sub BUILD
{
    my ($self, $id, $args) = @_;

    throw Error::Simple("Argument 'contents' cannot be null")
        unless ($args->{contents} and
                (ref($args->{contents}) eq 'ARRAY'));
    throw Error::Simple("Argument 'request_args' cannot be null")
        unless ($args->{request_args} and
                (ref($args->{request_args}) eq 'HASH'));
    # Copy the args to the local attribute store, making sure to deep-copy any
    # array-refs.
    $request_args{$id} = {};
    for (keys %{$args->{request_args}})
    {
        if (ref $args->{request_args}->{$_})
        {
            $request_args{$id}->{$_} = [ @{$args->{request_args}->{$_}} ];
        }
        else
        {
            $request_args{$id}->{$_} = $args->{request_args}->{$_};
        }
    }

    $args->{agent} = WebService::ISBNDB::API->get_default_agent()
        unless $args->{agent};
    $first_contents{$id} = [ @{$args->{contents}} ];

    $self;
}

###############################################################################
#
#   Sub Name:       first
#
#   Description:    Return the first element in the list of results for this
#                   iterator.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#
#   Globals:        %contents
#
#   Returns:        Success:    Object instance or undef
#
###############################################################################
sub first
{
    my $self = shift;

    $first_contents{ident $self}->[0];
}

###############################################################################
#
#   Sub Name:       next
#
#   Description:    Return the next element in the list, or undef if the
#                   iterator is exhausted. If the list is at the end, but there
#                   are pages yet to be fetched, get the next page.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#
#   Returns:        Success:    Object or undef
#                   Failure:    throws Error::Simple
#
###############################################################################
sub next
{
    my $self = shift;

    my $index     = $self->get_index;
    my $contents  = $self->get_contents;
    my $total     = $self->get_total_results;
    my $page_size = $self->get_page_size;
    my $retval;

    if ($index and ($index % $page_size == 0))
    {
        # We've gone past our internal cache, but there are still pages to be
        # fetched from isbndb.com.
        $self->fetch_next_page;
        # Because the previous method changed the internal contents list, and
        # $contents points to the same list, the next statement is perfectly
        # fine.
        $retval = $contents->[$index++ % $page_size];
    }
    elsif ($index % $page_size <= $#$contents)
    {
        # We still have enough data held internally in @$contents
        $retval = $contents->[$index++ % $page_size];
    }
    else
    {
        # The iterator is out of elements.
        $retval = undef;
    }

    # Set new index
    $self->set_index($index);

    $retval;
}

###############################################################################
#
#   Sub Name:       all
#
#   Description:    Return a list or list-reference of all the elements in this
#                   iterator. Leaves the iterator in an exhausted state, but
#                   always starts from the beginning (via a call to reset())
#                   regardless of where the iterator was before this call.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#
#   Returns:        Success:    list or list-reference, depending on wantarray
#                   Failure:    throws Error::Simple
#
###############################################################################
sub all
{
    my $self = shift;

    my @all;
    $self->reset;
    while ($_ = $self->next)
    {
        push(@all, $_);
    }

    return wantarray ? @all : \@all;
}

###############################################################################
#
#   Sub Name:       reset
#
#   Description:    Reset the internal index back to zero, so that the next
#                   bump of the iterator starts over at the beginning.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#
#   Returns:        0
#
###############################################################################
sub reset
{
    my $self = shift;

    my $contents = $self->get_contents; # Returns the actual list-reference
    # Explicitly overwrite any current contents with the initial set
    @$contents = @{$first_contents{ident $self}};
    $self->set_page_number(1);
    $self->set_index(0);

    0;
}

###############################################################################
#
#   Sub Name:       fetch_next_page
#
#   Description:    Retrieve the next page of results from the service and
#                   tack them on to the end of the contents list.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#
#   Returns:        Success:    $self
#                   Failure:    throws Error::Simple
#
###############################################################################
sub fetch_next_page
{
    my $self = shift;

    my $agent     = $self->get_agent;
    my $req_args  = $self->get_request_args;
    my $contents  = $self->get_contents;
    my $page_size = $self->get_page_size;
    my $page_num  = $self->get_page_number;
    my $shown     = $self->get_shown_results;

    # In theory, we shouldn't get called by next() when we've already read the
    # last page from the source. However, it's better to be safe.
    return $self if (($self->get_index + 1) == $self->get_total_results);

    my %args = %$req_args;
    $args{page_number} = ++$page_num;

    if (ref(my $hook = $self->get_fetch_page_hook) eq 'CODE')
    {
        eval { $hook->($self, \%args); };
        throw Error::Simple("Error invoking fetch-page hook: $@") if $@;
    }

    my $newcontent = $agent->request_all($contents->[$#$contents], \%args);
    # If the request failed, it already threw an uncaught exception
    @$contents = @{$newcontent->get_contents}; # Overwrite @$contents
    # Update the tracking values
    $self->set_page_number($page_num);
    $self->set_shown_results($newcontent->get_shown_results);

    $self;
}

1;

=pod

=head1 NAME

WebService::ISBNDB::Iterator - Iterator class for large result-sets

=head1 SYNOPSIS

    # The search() method of API-derived classes returns an Iterator
    $iter = WebService::ISBNDB::API->search(Books =>
                                            { author =>
                                             'poe_edgar_allan' });

    print $iter->get_total_results, " books found.\n";
    while ($book = $iter->next)
    {
        print $book->get_title, "\n";
    }

    # Reset the iterator
    $iter->reset;

    # Do something else with all the elements found by the search
    for ($iter->all)
    {
        ...
    }

=head1 DESCRIPTION

This class provides an iterator object to abstract the results from a search.
Searches may return anywhere from no matches to thousands. Besides the fact
that trying to allocate all of that data at once could overwhelm system
memory, the B<isbndb.com> service returns data in "pages", rather than risk
sending an overwhelming response.

The iterator stores information about the initial request, and as the user
progresses past the in-memory slice of data, it makes subsequent requests
behind the scenes to refresh the data until the end of the results-set is
reached.

It is not expected that users will manually create iterators. Iterators will
be created as needed by the C<search> method in the API classes.

=head1 METHODS

Methods are broken in the following groups:

=head2 Constructor

=over 4

=item new($ARGS)

The constructor is based on the B<Class::Std> model. The argument it takes is
a hash-reference whose key/value pairs are attribute names and values. The
attributes are defined below, in L</Accessor Methods>.

The only I<required> attributes in the arguments list are C<request_args> and
C<contents>. The first
is the set of arguments used in the initial request made to the service. They
are reused when subsequent pages need to be fetched. The second is the initial
set of objects, fetched from the first page of results.

=back

=head2 Iterator Methods

These methods are the general-use interface between the user and the iterator.
In most cases, an application will only need to use the methods listed here:

=over 4

=item first

Return the first element in the results-set. Regardless of the current position
within the iterator, this is always the very first element (or C<undef>, if
there were no elements found by the search). This does not alter the position
of the internal pointer, or trigger any additional requests to the data
source.

=item next

Return the next element off the iterator, or C<undef> if the iterator is
exhausted. All elements returned by an iterator descend from
B<WebService::ISBNDB::API>. All elements in a given iterator will always be
from the same implementation class. The iterator does not explicitly
identify the class of the objects, since the application had to have had some
degree of knowledge before making the call to C<search>.

=item all

Returns the full set of results from the iterator, from the beginning
to the end (if the iterator has already been read some number of times, it
is reset before the list is constructed). The return value is the list of
elements when called in a list-context, or a list-reference of the elements
when called in a scalar context. The iterator will be in an exhausted state
after this returns.

=item reset

Resets the internal counter within the iterator to the beginning of the list.
This allows the iterator to be re-used when and if the user desires.

=item fetch_next_page

When a request (via next()) goes past the internal set of data, this method is
called to request the next page of results from the data source, until the
last page has been read. This method alters the C<page_number>, C<contents>
and C<shown_results> attributes. If the user has set a hook (via
set_fetch_page_hook()), it is called with the arguments for the request just
prior to the request itself. The arguments are those provided in the
C<request_args> attribute, plus a C<page_number> argument set to the page
that is being requested.

=back

=head2 Accessor Methods

The accessor methods provide access to the internal attributes of the object.
These attributes are:

=over 4

=item total_results

The total number of results in the result-set, not to be confused with the
number of results currently in memory.

=item page_size

The size of the "page" returned by the data source, in turn the maximum
number of elements held internally by the iterator at any given time. As the
index proceeds to the end of the in-memory list, a new page is fetched and
this many new elements replace the previous set internally.

=item page_number

The number of the page of results currently held within the iterator. When the
iterator fetches a new page, this is incremented. When the iterator is reset,
this is set to 1.

=item shown_results

The number of results currently held within the iterator. When the last page
of a results-set is fetched, it may have fewer than C<page_size> elements in
it. This attribute will always identify the number of elements currently kept
internally.

=item contents

The list reference used internally to store the current set of objects for
the page of results held by the iterator. Be careful with this value, as
changing its contents can change the internal state of the iterator.

=item request_args

The hash reference that stores the original request arguments used to fetch
the initial page of data from the data source. This is used to make any
additional requests for subsequent pages, as needed. Be careful with the
value, as changing its contents can affect the iterator's ability to fetch
further pages.

=item index

The integer value that marks the current position within the iterator. The
value is the position within the whole set of results, not just within the
single page held internally.

=item agent

The B<WebService::IDBNDB::Agent> instance that is used to fetch additional
pages as needed. It is generally set at object-construction time by the
API object that creates the iterator. If it is not specified in the
constructor, the C<get_default_agent> method of B<WebService::ISBNDB::API>
is called.

=item fetch_page_hook

If this attribute has a value that is a code-reference, the code-reference
is invoked with the arguments that are going to be passed to the C<request>
method of the C<agent>. The hook (or callback) will receive the iterator
object referent and the hash-reference of arguments, as if it had been called
as a method in this class. The arguments are those stored in C<request_args>
as well as one additional argument, C<page_number>, containing the number of
the page being requested.

Note that the hook will B<not> be called for the first page fetched from the
data source. That is because that fetch is done outside the scope of the
iterator class, and the data from that initial fetch is provided when the
iterator is constructed.

=back

Note that for most of the attributes, only the "get" accessor is documented.
Users should not need to manually set any of the attributes (except for
C<fetch_page_hook>) unless they are sub-classing this class:

=over 4

=item get_total_results

=item get_page_size

=item get_page_number

=item get_shown_results

=item get_contents

=item get_request_args

=item get_index

=item get_agent

Return the relevant attribute's value. Note, again, that get_contents() and
get_request_args() return the actual reference value used internally. Changes
to the contents of those reference values may impact the behavior of the
iterator itself.

=item set_fetch_page_hook($HOOK)

Set a hook (callback) to be called each time the iterator has to fetch a new
page from the data source. The value is a code-reference, and is called with
the iterator object and a hash-reference of the request arguments as
parameters. Any return value is ignored. If the hook dies, an exception
is thrown by fetch_next_page() with the error message.

=item get_fetch_page_hook

Get the current hook value, if any.

=back

=head1 SEE ALSO

L<WebService::ISBNDB::API>, L<Class::Std>

=head1 AUTHOR

Randy J. Ray E<lt>rjray@blackperl.comE<gt>

=head1 LICENSE

This module and the code within are
released under the terms of the Artistic License 2.0
(http://www.opensource.org/licenses/artistic-license-2.0.php). This
code may be redistributed under either the Artistic License or the GNU
Lesser General Public License (LGPL) version 2.1
(http://www.opensource.org/licenses/lgpl-license.php).

=cut
