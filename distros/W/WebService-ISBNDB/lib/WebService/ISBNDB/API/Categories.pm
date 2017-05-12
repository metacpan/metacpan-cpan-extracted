###############################################################################
#
# This file copyright (c) 2006-2008 by Randy J. Ray, all rights reserved
#
# See "LICENSE" in the documentation for licensing and redistribution terms.
#
###############################################################################
#
#   $Id: Categories.pm 49 2008-04-06 10:45:43Z  $
#
#   Description:    This is an extension of the API base-class that provides
#                   the information specific to categories.
#
#   Functions:      BUILD
#                   copy
#                   new
#                   set_id
#                   get_parent
#                   get_sub_categories
#                   set_sub_categories
#                   find
#                   normalize_args
#
#   Libraries:      Class::Std
#                   Error
#                   WebService::ISBNDB::API
#
#   Global Consts:  $VERSION
#
###############################################################################

package WebService::ISBNDB::API::Categories;

use 5.006;
use strict;
use warnings;
no warnings 'redefine';
use vars qw($VERSION);
use base 'WebService::ISBNDB::API';

use Class::Std;
use Error;

$VERSION = "0.21";

my %id             : ATTR(:init_arg<id>     :get<id>     :default<>);
my %parent         : ATTR(:init_arg<parent> :set<parent> :default<>);
my %name           : ATTR(:name<name>                    :default<>);
my %summary        : ATTR(:name<summary>                 :default<>);
my %depth          : ATTR(:name<depth>                   :default<>);
my %element_count  : ATTR(:name<element_count>           :default<>);
my %sub_categories : ATTR(:init_arg<sub_categories>      :default<>);

###############################################################################
#
#   Sub Name:       new
#
#   Description:    Pass off to the super-class constructor, which handles
#                   the special cases for arguments.
#
###############################################################################
sub new
{
    shift->SUPER::new(@_);
}

###############################################################################
#
#   Sub Name:       BUILD
#
#   Description:    Builder for this class. See Class::Std.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $id       in      scalar    This object's unique ID
#                   $args     in      hashref   The set of arguments currently
#                                                 being considered for the
#                                                 constructor.
#
#   Returns:        Success:    void
#                   Failure:    throws Error::Simple
#
###############################################################################
sub BUILD
{
    my ($self, $id, $args) = @_;

    $self->set_type('Categories');

    if ($args->{sub_categories})
    {
        throw Error::Simple("'sub_categories' must be a list-reference")
            unless (ref($args->{sub_categories}) eq 'ARRAY');
        $args->{sub_categories} = [ @{$args->{sub_categories}} ];
    }

    return;
}

###############################################################################
#
#   Sub Name:       copy
#
#   Description:    Copy the Categories-specific attributes over from target
#                   object to caller.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $target   in      ref       Object of the same class
#
#   Globals:        %id
#                   %parent
#                   %name
#                   %summary
#                   %depth
#                   %element_count
#                   %sub_categories
#
#   Returns:        Success:    void
#                   Failure:    throws Error::Simple
#
###############################################################################
sub copy : CUMULATIVE
{
    my ($self, $target) = @_;

    throw Error::Simple("Argument to 'copy' must be the same class as caller")
        unless (ref($self) eq ref($target));

    my $id1 = ident $self;
    my $id2 = ident $target;

    # Do the simple (scalar) attributes first
    $id{$id1}            = $id{$id2};
    $parent{$id1}        = $parent{$id2};
    $name{$id1}          = $name{$id2};
    $summary{$id1}       = $summary{$id2};
    $depth{$id1}         = $depth{$id2};
    $element_count{$id1} = $element_count{$id2};

    # This must be tested and copied by value
    $sub_categories{$id1}  = [ @{$sub_categories{$id2}}  ]
        if ref($sub_categories{$id2});

    return;
}

###############################################################################
#
#   Sub Name:       set_id
#
#   Description:    Set the ID attribute on the object. Done manually so that
#                   we can restrict it to this package.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $id       in      scalar    ID, taken from isbndb.com data
#
#   Globals:        %id
#
#   Returns:        $self
#
###############################################################################
sub set_id : RESTRICTED
{
    my ($self, $id) = @_;

    $id{ident $self} = $id;
    $self;
}

###############################################################################
#
#   Sub Name:       get_parent
#
#   Description:    Return a Categories object for the parent. If the current
#                   value in the attribute is a scalar, convert it to an
#                   object and replace it before returning.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#
#   Globals:        %parent
#
#   Returns:        Success:    Categories object
#                   Failure:    throws Error::Simple
#
###############################################################################
sub get_parent
{
    my $self = shift;

    my $parent = $parent{ident $self};
    if ($parent and not ref($parent))
    {
        my $class = $self->class_for_type('Categories');

        throw Error::Simple("No category found for ID '$parent'")
            unless (ref($parent = $class->new($parent)));

        $parent{ident $self} = $parent;
    }

    $parent;
}

###############################################################################
#
#   Sub Name:       set_sub_categories
#
#   Description:    Set the list of Categories objects for this instance. The
#                   list will initially be a list of IDs, taken from the
#                   attributes of the XML. Only upon read-access (via
#                   get_sub_categories) will the list be turned into real
#                   objects.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $list     in      ref       List-reference of category data
#
#   Globals:        %sub_categories
#
#   Returns:        Success:    $self
#                   Failure:    throws Error::Simple
#
###############################################################################
sub set_sub_categories
{
    my ($self, $list) = @_;

    throw Error::Simple("Argument to 'set_sub_categories' must be a list " .
                        "reference")
        unless (ref($list) eq 'ARRAY');

    # Make a copy of the list
    $sub_categories{ident $self} = [ @$list ];

    $self;
}

###############################################################################
#
#   Sub Name:       get_sub_categories
#
#   Description:    Return a list-reference of the sub-Categories. If this is
#                   the first such request, then the category values are going
#                   to be scalars, not objects, and must be converted to
#                   objects before being returned.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#
#   Globals:        %sub_categories
#
#   Returns:        Success:    list-reference of data
#                   Failure:    throws Error::Simple
#
###############################################################################
sub get_sub_categories
{
    my $self = shift;

    my $sub_categories = $sub_categories{ident $self};

    # If any element is not a reference, we need to transform the list
    if (grep(! ref($_), @$sub_categories))
    {
        my $class = $self->class_for_type('Categories');
        # Make sure it's loaded
        eval "require $class;";
        my $cat_id;

        for (0 .. $#$sub_categories)
        {
            unless (ref($cat_id = $sub_categories->[$_]))
            {
                throw Error::Simple("No category found for ID '$cat_id'")
                    unless ref($sub_categories->[$_] =
                               $class->find({ id => $cat_id }));
            }
        }
    }

    # Make a copy, so the real reference doesn't get altered
    [ @$sub_categories ];
}

###############################################################################
#
#   Sub Name:       find
#
#   Description:    Find a single record using the passed-in search criteria.
#                   Most of the work is done by the super-class: this method
#                   turns a single-argument call into a proper hashref, and/or
#                   turns user-supplied arguments into those recognized by the
#                   API.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $args     in      variable  See text
#
#   Returns:        Success:    result from SUPER::find
#                   Failure:    throws Error::Simple
#
###############################################################################
sub find
{
    my ($self, $args) = @_;

    # First, see if we were passed a single scalar for an argument. If so, it
    # needs to become the id argument
    $args = { category_id => $args } unless (ref $args);

    $self->SUPER::find($args);
}

###############################################################################
#
#   Sub Name:       normalize_args
#
#   Description:    Normalize the contents of the $args hash reference, turning
#                   the user-visible (and user-friendlier) arguments into the
#                   arguments that the API expects.
#
#                   Also adds some "results" values, to tailor the returned
#                   content.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $class    in      scalar    Object ref or class name
#                   $args     in      hashref   Reference to the arguments hash
#
#   Returns:        Success:    $args (changed)
#                   Failure:    throws Error::Simple
#
###############################################################################
sub normalize_args
{
    my ($class, $args) = @_;

    my ($key, $value, @keys, $count, $results, %seen);

    # Turn the collection of arguments into a set that the isbndb.com API can
    # use. Each key/value pair has to become a pair of the form "indexX" and
    # "valueX". Some keys, like author and publisher, have to be handled with
    # more attention.
    @keys = keys %$args;
    $count = 0; # Used to gradually increment the "indexX" and "valueX" keys
    foreach $key (@keys)
    {
        # If we see "api_key", it means that WebService::ISBNDB::API::search
        # curried it into the arglist due to the type-level search being
        # called as a static method.
        next if $key eq 'api_key';
        $value = $args->{$key};
        delete $args->{$key};
        $count++;

        # A key of "id" needs to be translated as "subject_id"
        if ($key eq 'id')
        {
            $args->{"index$count"} = 'category_id';
            $args->{"value$count"} = $value;

            next;
        }

        # A key of "parent" should become "parent_id". If it is a plain
        # scalar, the value carries over. If it is a Categories object, use
        # the "id" method.
        if ($key eq 'parent')
        {
            $args->{"index$count"} = 'parent_id';
            $args->{"value$count"} =
                (ref $value and
                 $value->isa('WebService::ISBNDB::API::Categories')) ?
                $value->id : $value;

            next;
        }

        # These are the only other allowed search-key(s)
        if ($key =~ /^(:?name|category_id|parent_id)$/)
        {
            $args->{"index$count"} = $key;
            $args->{"value$count"} = $value;

            next;
        }

        throw Error::Simple("'$key' is not a valid search-key for publishers");
    }

    # Add the "results" values that we want
    $args->{results} = [ qw(details subcategories) ];

    $args;
}

1;

=pod

=head1 NAME

WebService::ISBNDB::API::Categories - Data class for category information

=head1 SYNOPSIS

    use WebService::ISBNDB::API::Categories;

    $ray_authors = WebService::ISBNDB::API::Categories->
                       search({ name => 'alphabetically.authors.r.a.y' });

=head1 DESCRIPTION

The B<WebService::ISBNDB::API::Categories> class extends the
B<WebService::ISBNDB::API> class to add attributes specific to the data
B<isbndb.com> provides on categories.

=head1 METHODS

The following methods are specific to this class, or overridden from the
super-class.

=head2 Constructor

The constructor for this class may take a single scalar argument in lieu of a
hash reference:

=over 4

=item new($CATEGORY_ID|$ARGS)

This constructs a new object and returns a referent to it. If the parameter
passed is a hash reference, it is handled as normal, per B<Class::Std>
mechanics. If the value is a scalar, it is assumed to be the category's ID
within the system, and is looked up by that.

If the argument is the hash-reference form, then a new object is always
constructed; to perform searches see the search() and find() methods. Thus,
the following two lines are in fact different:

    $book = WebService::ISBNDB::API::Categories->
                new({ id => "arts.music" });

    $book = WebService::ISBNDB::API::Categories->new('arts.music');

The first creates a new object that has only the C<id> attribute set. The
second returns a new object that represents the category named C<arts.music>,
with all data present.

=back

The class also defines:

=over 4

=item copy($TARGET)

Copies the target object into the calling object. All attributes (including
the ID) are copied. This method is marked "CUMULATIVE" (see L<Class::Std>),
and any sub-class of this class should provide their own copy() and also mark
it "CUMULATIVE", to ensure that all attributes at all levels are copied.

=back

See the copy() method in L<WebService::ISBNDB::API>.

=head2 Accessors

The following attributes are used to maintain the content of a category
object:

=over 4

=item id

The unique ID within the B<isbndb.com> system for this category.

=item name

The name of the category.

=item parent

The parent category, if there is one, that this category falls under.

=item summary

A brief summary of the category, if available.

=item depth

The depth of the category in the hierarchy. Top-level categories are at a
depth of 0. C<arts.opera.regions.france>, for example, is at a depth of 3.

=item element_count

Not documented in the B<isbndb.com> API; appears be the number of books in
the category and all of its sub-categories.

=item sub_categories

A list of category objects for the sub-categories that fall below this one.

=back

The following accessors are provided to manage these attributes:

=over 4

=item get_id

Return the category ID.

=item set_id($ID)

Sets the category ID. This method is restricted to this class, and cannot be
called outside of it. In general, you shouldn't need to set the ID after the
object is created, since B<isbndb.com> is a read-only source.

=item get_name

Return the category's name.

=item set_name($NAME)

Set the name to the value in C<$NAME>.

=item get_parent

Return the B<WebService::ISBNDB::API::Categories> object that represents this
category's parent. If this is a top-level category, then the method returns
C<undef>.

=item set_parent($PARENT)

Set the category's parent to the value in C<$PARENT>. This may be an object,
or it may be a category ID. If the value is not an object, the next call to
get_parent() will attempt to convert it to one by calling the service.

=item get_summary

Get the category summary.

=item set_summary($SUMMARY)

Set the category summary to C<$SUMMARY>.

=item get_depth

Get the category depth.

=item set_depth($DEPTH)

Set the category depth to C<$DEPTH>.

=item get_element_count

Get the count of elements.

=item set_element_count($COUNT)

Set the element count.

=item get_sub_categories

Return a list-reference of the sub-categories for the category. Each element
of the list will be an instance of B<WebService::ISBNDB::API::Categories>.

=item set_sub_categories($CATEGORIES)

Set the sub-categories to the list-reference given in C<$CATEGORIES>. When the
category object is first created from the XML data, this list is populated
with the IDs of the sub-categories. They are not converted to objects until
requested (via get_sub_categories()) by the user.

=back

=head2 Utility Methods

Besides the constructor and the accessors, the following methods are provided
for utility:

=over 4

=item find($ARG|$ARGS)

This is a specialization of find() from the parent class. It allows the
argument passed in to be a scalar in place of the usual hash reference. If the
value is a scalar, it is searched as though it were the ID. If the value is a
hash reference, it is passed to the super-class method.

=item normalize_args($ARGS)

This method maps the user-visible arguments as defined for find() and search()
into the actual arguments that must be passed to the service itself. In
addition, some arguments are added to the request to make the service return
extra data used for retrieving categories, location, etc. The
method changes C<$ARGS> in place, and also returns C<$ARGS> as the value from
the method.

=back

See the next section for an explanation of the available keys for searches.

=head1 SEARCHING

Both find() and search() allow the user to look up data in the B<isbndb.com>
database. The allowable search fields are limited to a certain set, however.
When either of find() or search() are called, the argument to the method
should be a hash reference of key/value pairs to be passed as arguments for
the search (the exception being that find() can accept a single string, which
has special meaning as detailed earlier).

Searches in the text fields are done in a case-insensitive manner.

The available search keys are:

=over 4

=item name

The value should be a text string. The search returns categories whose name
matches the string.

=item id|category_id

The value should be a text string. The search returns the category whose ID
in the system matches the value.

=item parent|parent_id

You can also search by the parent. The search-key C<parent> will accept either
a string (taken as the ID) or a Categories object, in which case the ID is
derived from it. If the key used is C<parent_id>, the value is assumed to be
the ID.

=back

Note that the names above may not be the same as the corresponding parameters
to the service. The names are chosen to match the related attributes as
closely as possible, for ease of understanding.

=head1 EXAMPLES

Get the record for the ID C<science>:

    $science = WebService::ISBNDB::API::Categories->find('science');

Find all category records that are sub-categories of C<science>:

    $science2 = WebService::ISBNDB::API::Categories->
                    search({ parent => $science });

=head1 CAVEATS

The data returned by this class is only as accurate as the data retrieved from
B<isbndb.com>.

The list of results from calling search() is currently limited to 10 items.
This limit will be removed in an upcoming release, when iterators are
implemented.

=head1 SEE ALSO

L<WebService::ISBNDB::API>

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
