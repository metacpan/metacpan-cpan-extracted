###############################################################################
#
# This file copyright (c) 2006-2008 by Randy J. Ray, all rights reserved
#
# See "LICENSE" in the documentation for licensing and redistribution terms.
#
###############################################################################
#
#   $Id: Authors.pm 49 2008-04-06 10:45:43Z  $
#
#   Description:    Specialization of the API class for author data.
#
#   Functions:      BUILD
#                   new
#                   copy
#                   find
#                   set_id
#                   get_categories
#                   set_categories
#                   get_subjects
#                   set_subjects
#                   normalize_args
#
#   Libraries:      Class::Std
#                   Error
#                   WebService::ISBNDB::API
#
#   Global Consts:  $VERSION
#
###############################################################################

package WebService::ISBNDB::API::Authors;

use 5.006;
use strict;
use warnings;
no warnings 'redefine';
use vars qw($VERSION);
use base 'WebService::ISBNDB::API';

use Class::Std;
use Error;

$VERSION = "0.21";

my %id         : ATTR(:init_arg<id> :get<id> :default<>);
my %name       : ATTR(:name<name>            :default<>);
my %first_name : ATTR(:name<first_name>      :default<>);
my %last_name  : ATTR(:name<last_name>       :default<>);
my %dates      : ATTR(:name<dates>           :default<>);
my %has_books  : ATTR(:name<has_books>       :default<>);
my %categories : ATTR(:init_arg<categories>  :default<>);
my %subjects   : ATTR(:init_arg<subjects>    :default<>);

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

    $self->set_type('Authors');

    throw Error::Simple("'categories' must be a list-reference")
        if ($args->{categories} and (ref($args->{categories}) ne 'ARRAY'));

    throw Error::Simple("'subjects' must be a list-reference")
        if ($args->{subjects} and (ref($args->{subjects}) ne 'ARRAY'));

    return;
}

###############################################################################
#
#   Sub Name:       copy
#
#   Description:    Copy the Authors-specific attributes over from target
#                   object to caller.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $target   in      ref       Object of the same class
#
#   Globals:        %id
#                   %name
#                   %first_name
#                   %last_name
#                   %dates
#                   %has_books
#                   %subjects
#                   %categories
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
    $id{$id1}         = $id{$id2};
    $name{$id1}       = $name{$id2};
    $first_name{$id1} = $first_name{$id2};
    $last_name{$id1}  = $last_name{$id2};
    $dates{$id1}      = $dates{$id2};
    $has_books{$id1}  = $has_books{$id2};

    # This must be tested and copied by value
    $categories{$id1}  = [ @{$categories{$id2}}  ] if ref($categories{$id2});
    $subjects{$id1}  = [ @{$subjects{$id2}}  ] if ref($subjects{$id2});

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
#   Sub Name:       set_categories
#
#   Description:    Set the list of Categories objects for this instance. The
#                   list will initially be a list of IDs, taken from the
#                   attributes of the XML. Only upon read-access (via
#                   get_categories) will the list be turned into real objects.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $list     in      ref       List-reference of category data
#
#   Globals:        %categories
#
#   Returns:        Success:    $self
#                   Failure:    throws Error::Simple
#
###############################################################################
sub set_categories
{
    my ($self, $list) = @_;

    throw Error::Simple("Argument to 'set_categories' must be a list " .
            "reference")
        unless (ref($list) eq 'ARRAY');

    # Make a copy of the list
    $categories{ident $self} = [ @$list ];

    $self;
}

###############################################################################
#
#   Sub Name:       get_categories
#
#   Description:    Return a list-reference of the Categories. If this is
#                   the first such request, then the category values are going
#                   to be scalars, not objects, and must be converted to
#                   objects before being returned.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#
#   Globals:        %categories
#
#   Returns:        Success:    list-reference of data
#                   Failure:    throws Error::Simple
#
###############################################################################
sub get_categories
{
    my $self = shift;

    my $categories = $categories{ident $self};

    # If any element is not a reference, we need to transform the list
    if (grep(! ref($_), @$categories))
    {
        my $class = $self->class_for_type('Categories');
        # Make sure it's loaded
        eval "require $class;";
        my $cat_id;

        for (0 .. $#$categories)
        {
            unless (ref($cat_id = $categories->[$_]))
            {
                throw Error::Simple("No category found for ID '$cat_id'")
                    unless ref($categories->[$_] = $class->find({ id =>
                                                                  $cat_id }));
            }
        }
    }

    # Make a copy, so the real reference doesn't get altered
    [ @$categories ];
}

###############################################################################
#
#   Sub Name:       set_subjects
#
#   Description:    Set the list of Subjects objects for this instance. The
#                   list will initially be a list of IDs, taken from the
#                   attributes of the XML. Only upon read-access (via
#                   get_subjects) will the list be turned into real objects.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $list     in      ref       List-reference of category data
#
#   Globals:        %subjects
#
#   Returns:        Success:    $self
#                   Failure:    throws Error::Simple
#
###############################################################################
sub set_subjects
{
    my ($self, $list) = @_;

    throw Error::Simple("Argument to 'set_subjects' must be a list reference")
        unless (ref($list) eq 'ARRAY');

    # Make a copy of the list
    $subjects{ident $self} = [ @$list ];

    $self;
}

###############################################################################
#
#   Sub Name:       get_subjects
#
#   Description:    Return a list-reference of the Subjects. If this is
#                   the first such request, then the subject values are going
#                   to be scalars, not objects, and must be converted to
#                   objects before being returned.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#
#   Globals:        %subjects
#
#   Returns:        Success:    list-reference of data
#                   Failure:    throws Error::Simple
#
###############################################################################
sub get_subjects
{
    my $self = shift;

    my $subjects = $subjects{ident $self};

    # If any element is not a reference, we need to transform the list
    if (grep(! ref($_), @$subjects))
    {
        my $class = $self->class_for_type('Subjects');
        # Make sure it's loaded
        eval "require $class;";
        my ($subj_id, $books);

        for (0 .. $#$subjects)
        {
            unless (ref($subj_id = $subjects->[$_]))
            {
                ($subj_id, $books) = split(/:/, $subj_id);
                throw Error::Simple("No subject found for ID '$subj_id'")
                    unless ref($subjects->[$_] = $class->find({ id =>
                                                                $subj_id }));
                # Use the value in $books to override the value from the DB
                $subjects->[$_]->set_book_count($books);
            }
        }
    }

    # Make a copy, so the real reference doesn't get altered
    [ @$subjects ];
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
    $args = { person_id => $args } unless (ref $args);

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

        # A key of "id" needs to be translated as "person_id"
        if ($key eq 'id')
        {
            $args->{"index$count"} = 'person_id';
            $args->{"value$count"} = $value;

            next;
        }

        # These are the only other allowed search-key(s)
        if ($key =~ /^(:?name|person_id)$/)
        {
            $args->{"index$count"} = $key;
            $args->{"value$count"} = $value;

            next;
        }

        throw Error::Simple("'$key' is not a valid search-key for publishers");
    }

    # Add the "results" values that we want
    $args->{results} = [ qw(details subjects categories) ];

    $args;
}

1;

=pod

=head1 NAME

WebService::ISBNDB::API::Authors - Data class for author information

=head1 SYNOPSIS

    use WebService::ISBNDB::API::Authors;

    $me = WebService::ISBNDB::API::Authors->find('ray_randy_j');

=head1 DESCRIPTION

The B<WebService::ISBNDB::API::Authors> class extends the
B<WebService::ISBNDB::API> class to add attributes specific to the data
B<isbndb.com> provides on authors.

=head1 METHODS

The following methods are specific to this class, or overridden from the
super-class.

=head2 Constructor

The constructor for this class may take a single scalar argument in lieu of a
hash reference:

=over 4

=item new($PERSON_ID|$ARGS)

This constructs a new object and returns a referent to it. If the parameter
passed is a hash reference, it is handled as normal, per B<Class::Std>
mechanics. If the value is a scalar, it is assumed to be the author's ID
within the system, and is looked up by that.

If the argument is the hash-reference form, then a new object is always
constructed; to perform searches see the search() and find() methods. Thus,
the following two lines are in fact different:

    $book = WebService::ISBNDB::API::Authors->new({ id => "ray_randy_j" });

    $book = WebService::ISBNDB::API::Authors->new('ray_randy_j');

The first creates a new object that has only the C<id> attribute set. The
second returns a new object that represents the given author,
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

The following attributes are used to maintain the content of an author
object:

=over 4

=item id

The unique ID within the B<isbndb.com> system for this author.

=item name

The full name of the author.

=item first_name

The author's first name only.

=item last_name

The author's last name only.

=item dates

If the author is deceased, this will have the years of birth and death,
separated by a hyphen, e.g., "1900-1988".

=item has_books

A boolean value indicating whether the author has books in the database.

=item categories

A list of category objects for the categories the author is listed in.

=item subjects

A list of subject objects for the subjects the author's books are listed
under.

The instances of B<Subjects> objects stored in this attribute differ from
those instantiated from the service normally. The C<book_count> attribute
in these objects indicates the number of books I<belonging to this author>
that fall into this subject, not the total number of books in the database
that do.

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

Return the author's name. This is the full name, as would appear in the
C<author_text> field of a B<WebService::ISBNDB::API::Books> object.

=item set_name($NAME)

Set the name to the value in C<$NAME>.

=item get_first_name

Returns the author's first name only.

=item set_first_name($NAME)

Set the authors's first name. Note that C<first_name> and C<last_name>
combined may not always be the same value as C<name>.

=item get_last_name

Get the author's last name only.

=item set_last_name($NAME)

Set the authors's last name. Note that C<first_name> and C<last_name>
combined may not always be the same value as C<name>.

=item get_dates

If the author is deceased, this returns the years of birth and death.

=item set_dates($DATES)

Set birth-death date range.

=item get_has_books

Get the boolean indicating whether this author has books in the service
database.

=item set_has_books($BOOL)

Set the boolean flag that indicates whether this author has any books in the
service's database.

=item get_categories

Return a list-reference of the categories this author is listed in. Each
element of the list will be an instance of
B<WebService::ISBNDB::API::Categories>.

=item set_categories($CATEGORIES)

Set the categories to the list-reference given in C<$CATEGORIES>. When the
author object is first created from the XML data, this list is populated
with the IDs of the categories. They are not converted to objects until
requested (via get_categories()) by the user.

=item get_subjects

Return a list-reference of the subjects this author has books in. Each element
of the list will be an instance of B<WebService::ISBNDB::API::Subjects>. Note
that these subject objects differ slightly from having instantiated the same
subjects directly; their C<book_count> attributes indicate the number of books
specific to this author that fall under the subject, not the total number of
books from the database as a whole.

=item set_subjects($SUBJECTS)

Set the list of subjects to the contents of the list-reference passed in
C<$SUBJECTS>. When the author object is first created from the XML data, this
list is populated with the IDs of the subjects. They are not converted to
objects until requested (via get_subjects()) by the user.

=back

=head2 Utility Methods

Besides the constructor and the accessors, the following methods are provided
for utility:

=over 4

=item find($ARG|$ARGS)

This is a specialization of find() from the parent class. It allows the
argument passed in to be a scalar in place of the usual hash reference. If the
value is a scalar, it is searched for as if it were the ID. If the value is a
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

The value should be a text string. The search returns authors whose name
matches the string.

=item id|person_id

The value should be a text string. The search returns the author whose ID
in the system matches the value.

=back

Note that the names above may not be the same as the corresponding parameters
to the service. The names are chosen to match the related attributes as
closely as possible, for ease of understanding.

=head1 EXAMPLES

Get the record for the author of this module:

    $me = WebService::ISBNDB::API::Authors->find('ray_randy_j');

Find all authors with "Clinton" in their name:

    $clintons = WebService::ISBNDB::API::Authors->
                    search({ name => 'clinton' });

=head1 CAVEATS

The data returned by this class is only as accurate as the data retrieved from
B<isbndb.com>.

The list of results from calling search() is currently limited to 10 items.
This limit will be removed in an upcoming release, when iterators are
implemented.

=head1 SEE ALSO

L<WebService::ISBNDB::API>, L<WebService::ISBNDB::API::Categories>,
L<WebService::ISBNDB::API::Subjects>

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
