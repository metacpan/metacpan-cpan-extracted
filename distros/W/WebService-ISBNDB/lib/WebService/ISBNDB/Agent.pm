###############################################################################
#
# This file copyright (c) 2006-2008 by Randy J. Ray, all rights reserved
#
# See "LICENSE" in the documentation for licensing and redistribution terms.
#
###############################################################################
#
#   $Id: Agent.pm 47 2008-04-06 10:12:34Z  $
#
#   Description:    This is the base class for all protocol agents. It provides
#                   the skeletal functionality and management of the LWP::UA
#                   instance.
#
#   Functions:      add_protocol
#                   BUILD
#                   class_for_protocol
#                   get_useragent
#                   new
#                   protocol
#                   raw_request
#                   remove_protocol
#                   request
#                   request_all
#                   request_body
#                   request_headers
#                   request_method
#                   request_single
#                   request_uri
#                   resolve_obj
#                   set_useragent
#                   _lr_trim
#
#   Libraries:      Class::Std
#                   Error
#                   LWP::UserAgent
#                   HTTP::Request
#                   URI
#
#   Global Consts:  $VERSION
#
###############################################################################

package WebService::ISBNDB::Agent;

use 5.006;
use strict;
use warnings;
use vars qw($VERSION @PROTOS %PROTOS);
use base 'Class::Std';
use constant COREPROTOS => qw(REST);

use Error;
use URI;
use LWP::UserAgent;
use HTTP::Request;

$VERSION = "0.30";

BEGIN
{
    @PROTOS = (COREPROTOS);
    %PROTOS = map { $_ => __PACKAGE__ . "::$_" } @PROTOS;
}

my %useragent      : ATTR(:init_arg<useragent>  :default<>);
my %agent_args : ATTR(:name<agent_args> :default<>);

##############################################################################
#
#   Sub Name:       new
#
#   Description:    Constructor for the class.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $class    in      scalar    The class to bless object into
#                   @argz     in      list      Variable list of args, see text
#
#   Globals:        %TYPES
#
#   Returns:        Success:    new object
#                   Failure:    Throws Error::Simple
#
###############################################################################
sub new
{
    my ($class, @argz) = @_;
    my ($proto, $self);

    # Need to make sure $class is the name, not a reference, for later tests:
    $class = ref($class) || $class;

    # If $class matches this package, then they must specify a protocol
    # as the leading argument (currently only 'REST')
    if ($class eq __PACKAGE__)
    {
        $proto = uc shift(@argz);
        throw Error::Simple("new: Unknown factory type '$proto'")
            unless $class = $class->class_for_protocol($proto);
        # Make sure it is loaded
        eval "require $class;";
    }
    my $args = shift(@argz) || {};

    return $proto ? $class->new($args) : $class->SUPER::new($args);
}

###############################################################################
#
#   Sub Name:       BUILD
#
#   Description:    Class initializer.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $id       in      scalar    Unique identifier for $self
#                   $args     in      hashref   Current arguments for the
#                                                 constructor
#
#   Returns:        Success:    void
#                   Failure:    throws Error::Simple
#
###############################################################################
sub BUILD
{
    my ($self, $id, $args) = @_;

    throw Error::Simple("Value for 'useragent' must derive from LWP::UserAgent")
        if ($args->{useragent} and
            ! (ref($args->{useragent}) and $args->{useragent}->isa('LWP::UserAgent')));
    throw Error::Simple("Value for 'agent_args' must be a hash reference")
        if ($args->{agent_args} and (ref($args->{agent_args}) ne 'HASH'));

    return;
}

###############################################################################
#
#   Sub Name:       get_useragent
#
#   Description:    Retrieve the LWP::Agent object used by this object. Create
#                   it if it isn't already allocated.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#
#   Globals:        %useragent
#
#   Returns:        Success:    LWP::UserAgent isntance
#                   Failure:    throws Error::Simple
#
###############################################################################
sub get_useragent
{
    my $self = shift;
    my $useragent = $useragent{ident $self};

    unless ($useragent)
    {
        my $useragent_args = $agent_args{ident $self};

        $useragent = LWP::UserAgent->new(%$useragent_args);
    }

    $useragent;
}

###############################################################################
#
#   Sub Name:       set_useragent
#
#   Description:    Assign a new useragent to the object. The agent must derive
#                   from LWP::UserAgent.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $agent    in      ref       New agent object
#
#   Globals:        %useragent
#
#   Returns:        Success:    $self
#                   Failure:    throws Error::Simple
#
###############################################################################
sub set_useragent
{
    my ($self, $agent) = @_;

    throw Error::Simple("New agent must be derived from LWP::UserAgent")
        unless (! defined $agent or
                (ref($agent) and $agent->isa('LWP::UserAgent')));

    $useragent{ident $self} = $agent;

    $self;
}

###############################################################################
#
#   Sub Name:       add_protocol
#
#   Description:    Add a name-to-class mapping for the list of known Agent
#                   protocols.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $class    in      scalar    Ignored-- this can be a static
#                                                 method or not.
#                   $proto    in      scalar    The protocol name, usually the
#                                                 last element of the classname
#                                                 all-lowercase (e.g. rest).
#                   $pack     in      scalar    The package that should be
#                                                 instantiated for the protocol
#
#   Globals:        @PROTOS
#                   %PROTOS
#
#   Returns:        Success:    $pack (for chaining purposes)
#                   Failure:    Throws Error::Simple
#
###############################################################################
sub add_protocol
{
    my ($class, $proto, $pack) = @_;

    $proto = uc $proto;
    throw Error::Simple("No package specfied for $proto") unless $pack;

    push(@PROTOS, $proto);
    $PROTOS{$proto} = $pack;
}

###############################################################################
#
#   Sub Name:       remove_protocol
#
#   Description:    Delete the given protocol from the map.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $class    in      scalar    Ignored-- this can be a static
#                                                 method or not.
#                   $proto    in      scalar    The protocol name, usually the
#                                                 last element of the classname
#                                                 in all-lowercase (e.g. rest).
#
#   Globals:        @PROTOS
#                   %PROTOS
#                   @COREPROTOS
#
#   Returns:        Success:    void
#                   Failure:    throws Error::Simple if $proto in @COREPROTOS
#
###############################################################################
sub remove_protocol
{
    my ($class, $proto) = @_;

    throw Error::Simple("Cannot remove a core protocol")
        if (grep($_ eq $proto, (COREPROTOS)));
    delete $PROTOS{$proto};
    @PROTOS = grep($_ ne $proto, @PROTOS);

    return;
}

###############################################################################
#
#   Sub Name:       class_for_protocol
#
#   Description:    Return the actual class that should be used to instantiate
#                   the given protocol.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $class    in      scalar    Ignored-- this can be a static
#                                                 method or not.
#                   $proto    in      scalar    Protocol to look up.
#
#   Globals:        %PROTOS
#
#   Returns:        Success:    class name
#                   Failure:    undef
#
###############################################################################
sub class_for_protocol
{
    my ($class, $proto) = @_;

    $PROTOS{$proto};
}

###############################################################################
#
#   Sub Name:       protocol
#
#   Description:    For the implementation classes, this should either return
#                   a string identifying the protocol, or if passed a string
#                   should return a true/false whether the class matches that
#                   protocol.
#
#                   In this package, it just throws an exception, to remind you
#                   to override it in the implementation class.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#
#   Returns:        This version just throws Error::Simple
#
###############################################################################
sub protocol
{
    my $self = shift;
    my $class = ref($self) || $self;

    throw Error::Simple("Package $class has not overridden the protocol() " .
                        "method");
}

###############################################################################
#
#   Sub Name:       request_single
#
#   Description:    Make a request, returning a single result object.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $obj      in      ref       Object from the API hierarchy
#                   $args     in      hashref   Arguments to the request
#
#   Returns:        Success:    object reference
#                   Failure:    throws Error::Simple
#
###############################################################################
sub request_single
{
    my ($self, $obj, $args) = @_;

    $self->request($obj, $args)->first;
}

###############################################################################
#
#   Sub Name:       request_all
#
#   Description:    Make a request, returning all the matching records as
#                   objects, in an Iterator instance.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#
#                   $self     in      ref       Object
#                   $obj      in      ref       Object from the API hierarchy
#                   $args     in      hashref   Arguments to the request
#
#   Returns:        Success:    array reference
#                   Failure:    throws Error::Simple
#
###############################################################################
sub request_all
{
    my ($self, $obj, $args) = @_;

    $self->request($obj, $args);
}

###############################################################################
#
#   Sub Name:       request_method
#
#   Description:    Return the HTTP request method needed for sending the
#                   request to the service.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $obj      in      ref       Object from the API hierarchy
#                   $args     in      hashref   Arguments to the request
#
#   Returns:        null string
#
###############################################################################
sub request_method : RESTRICTED
{
    '';
}

###############################################################################
#
#   Sub Name:       request_uri
#
#   Description:    Return the URL to which the request should be sent, as an
#                   object of the URI class.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $obj      in      ref       Object from the API hierarchy
#                   $args     in      hashref   Arguments to the request
#
#   Returns:        null URI object
#
###############################################################################
sub request_uri : RESTRICTED
{
    URI->new();
}

###############################################################################
#
#   Sub Name:       request_headers
#
#   Description:    Return any additional headers (besides the default ones
#                   set up by HTTP::Request and LWP::UserAgent) needed for the
#                   request, as an array reference.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $obj      in      ref       Object from the API hierarchy
#                   $args     in      hashref   Arguments to the request
#
#   Returns:        empty array reference
#
###############################################################################
sub request_headers : RESTRICTED
{
    [];
}

###############################################################################
#
#   Sub Name:       request_body
#
#   Description:    Return the body-content of the request, as a scalar
#                   reference.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $obj      in      ref       Object from the API hierarchy
#                   $args     in      hashref   Arguments to the request
#
#   Returns:        empty scalar reference
#
###############################################################################
sub request_body : RESTRICTED
{
    \'';
}

###############################################################################
#
#   Sub Name:       resolve_obj
#
#   Description:    Decide what value to use within request_single() and
#                   request_all(), based on the disposition of $obj.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $obj      in      scalar    Input from the user, to be
#                                                 resolved
#
#   Returns:        Success:    value to use
#                   Failure:    throws Error::Simple
#
###############################################################################
sub resolve_obj : RESTRICTED
{
    my ($self, $obj) = @_;
    my $retval;

    # Is it already a usable object?
    if ($obj->isa('WebService::ISBNDB::API'))
    {
        # This actually catches two of the cases, ref($obj) and $obj being
        # the name of a class that qualifies.
        $retval = $obj;
    }
    elsif (my $tmp = WebService::ISBNDB::API->class_for_type($obj))
    {
        $retval = $tmp;
    }
    else
    {
        # No dice
        throw Error::Simple("Value ($obj) not valid for operation");
    }

    $retval;
}

###############################################################################
#
#   Sub Name:       request
#
#   Description:    Stub for the request method that subclasses must override.
#
#   Returns:        throws Error::Simple
#
###############################################################################
sub request
{
    throw Error::Simple((ref($_[0]) || $_[0]) . ' did not override request()');
}

###############################################################################
#
#   Sub Name:       raw_request
#
#   Description:    Do the actual work of creating and dispatching the HTTP
#                   request. Return the body of the response as a scalar
#                   reference. This allows request_single() and request_all()
#                   to share this part of the logic and focus on their specific
#                   functions.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $obj      in      ref       Object from the API hierarchy
#                   $args     in      hashref   Arguments to the request
#
#   Returns:        Success:    scalar reference
#                   Failure:    throws Error::Simple
#
###############################################################################
sub raw_request : RESTRICTED
{
    my ($self, $obj, $args) = @_;

    # Resolve $obj before using it to call the other methods
    $obj = $self->resolve_obj($obj);

    my $method  = $self->request_method($obj, $args);
    my $uri     = $self->request_uri($obj, $args);
    my $headers = $self->request_headers($obj, $args);
    my $body    = $self->request_body($obj, $args);

    # We have to have at least a method and a URI, so check those:
    throw Error::Simple("Cannot make a request without a HTTP method (Did " .
                        "you remember to override request_method()?)")
        unless $method;
    throw Error::Simple("Cannot make a request without a HTTP URL (Did " .
                        "you remember to override request_uri()?)")
        unless $uri;

    my $request = HTTP::Request->new($method, $uri, $headers, $$body);
    my $UA = $self->get_useragent;

    # Make the request, check for problems
    my $response = $UA->request($request);
    throw Error::Simple("Error from HTTP request: " . $response->message)
        if ($response->is_error);

    my $anon = $response->content;
    \$anon;
}

###############################################################################
#
#   Sub Name:       _lr_trim
#
#   Description:    Do a right- and left-trim of whitespace and newlines off of
#                   the passed-in string. Also translate newlines and returns
#                   within a string to spaces, and squeeze sequences of spaces.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $class    in      scalar    Ignored
#                   $string   in      scalar    String to trim
#
#   Returns:        Trimmed string
#
###############################################################################
sub _lr_trim
{
    my ($class, $string) = @_;

    $string =~ tr/\n\r\t / /s;
    $string =~ s/^[\s\n]*//;
    $string =~ s/[\s\n]*$//;

    $string;
}

1;

=pod

=head1 NAME

WebService::ISBNDB::Agent - Base class for data-retrieval agents

=head1 SYNOPSIS

    package WebService::ISBNDB::Agent::REST;

    use strict;
    use warnings;
    use base 'WebService::ISBNDB::Agent';

=head1 DESCRIPTION

The B<WebService::ISBNDB::Agent> class is a base class for all the classes
that provide actual communication protocol support for the
B<WebService::ISBNDB::API> module. Unlike the API class, this class is not
usable on its own except as a factory to create instances of classes that
derive from it.

The agent classes are responsible for actually setting up the web requests
to retrieve data, parsing the results of those calls, and returning the
data in formats usable by the API classes.

This class (and all sub-classes of it) are based on the B<Class::Std>
inside-out objects pattern. See L<Class::Std> for more detail.

All error conditions in the methods of this class are handled using the
exception model provided by the B<Error> module. Most errors are thrown in
the form of B<Error::Simple> exception objects. See L<Error> for more
detail.

=head1 METHODS

The following methods are implemented (or in some cases, stubbed) in this
base class. In some cases, the method requires that an implementation class
override it in order to work. This is noted when it applies.

=head2 Constructor

The constructor for this class should only ever be called to act as a factory
constructor. Instantiating this class directly is not permitted, and will
cause an exception to be thrown.

=over 4

=item new($PROTO [ , $ARGS ])

Create a new object of the specified protocol and return a referent to it.
If C<$args> is passed, it is passed along to the protocol class' constructor.
If the protocol referred to by C<$PROTO> is unknown, or if C<$PROTO> is not
passed, an exception will be thrown.

=back

=head2 Accessors

The accessor methods are used to set and retrieve the attributes (instance
data) stored on the object. While a few of them have special behavior, most
operate as simple get or set accessors as described in L<Class::Std>. The
attributes for this class are:

=over 4

=item useragent

The user-agent (an instance or derivative of B<LWP::UserAgent>) used to make
all the HTTP requests to the service. Unless explicitly provided by the user,
this value is not initialized until the first request made to it. The next
attribute allows the user to specify arguments to the constructor when the
object is finally instantiated.

=item agent_args

A hash reference of parameters to be passed to the constructor of the agent
when it is created. The B<LWP::UserAgent> constructor takes ordinary
key/value pairs as arguments, not a single hash reference like classes
derived from B<Class::Std>. This value will be "flattened" when the
constructor is called. Value within it, however, will not be. You must make
certain that the values for any keys specified match the expected format
within B<LWP::UserAgent>.

=back

The following accessor methods are provided by this class:

=over 4

=item get_useragent

Retrieve the user-agent this object uses for HTTP communication. The creation
of this object is delayed until the first request to fetch it (unless the
user has explicitly set the agent, or provided an agent in the construction
of the B<WebService::ISBNDB::Agent>-derived object).

=item set_useragent($AGENT)

Explicitly set the user-agent for this object to use. The new value must be
an instance of B<LWP::UserAgent>, or an object of a class that is derived
from that one. If it isn't, an exception will be thrown.

=item get_agent_args

Get the current value of the arguments used in the creation of a user-agent
instance. If none have been set, the value returned will be C<undef>.

=item set_agent_args($ARGS)

Set a new hash reference of arguments to be used when the user-agent is
instantiated. Note that the object will instantiate the user-agent at most
once, so setting this after the first call to B<get_useragent> (or after
explicitly setting the agent attribute) will have no effect. The value of
C<$ARGS> must be a hash reference, or an exception will be thrown.

=back

=head2 Managing Protocols

For communication protocols, the only built-in protocol is:

=over 4

=item REST

The web services protocol known as C<REpresentational State Transfer>, this
protocol uses the URL exclusively for data-fetch operations (which, since
B<isbndb.com> is a read-only source, is all this module does). All parameters
for searches and data retrieval are passed as query parameters in the URL in
the request.

=back

All protocol names are treated as upper-case strings. The values are forced
to upper-case within the following methods:

=over 4

=item add_protocol($PROTO, $CLASS)

Add a mapping of the new protocol specified by C<$PROTO> to the class given
as C<$CLASS>. As with types, you can use this to override the class that will
be instantiated for any of the built-in protocols. You cannot delete mappings
for any core protocols, so if you wish to temporarily override the class,
you must save the existing map value (with B<class_for_protocol>, below) and
re-assign it yourself.

=item class_for_protocol($PROTO)

Returns the class-name for the given protocol. If C<$PROTO> is not know, then
an exception (of type B<Error::Simple> ) is thrown.

=item remove_protocol($PROTO)

Removes the mapping for C<$PROTO> from the internal table. You cannot remove
the mapping for a core protocol (an exception will be thrown if you try to).
You can only override it with another call to B<add_protocol>.

=item protocol([$PROTO])

Return the protocol this object implements, or test a given string to see if
to matches the implemented protocol. If C<$PROTO> is passed in, the method
will return either a true or false value, depending on whether the value
matches the protocol of this object. If C<$PROTO> is not passed in, the
return value is a string representation of the module's protocol.

=back

The protocol-oriented methods are intended for the future, if/when
B<isbndb.com> should offer other methods besides REST. These class methods
can be used by separate modules to register their protocols with this
class.

As with the type-map methods in B<WebService::ISBNDB::API>, all of the
protocol-map methods may be called as static methods.

=head2 Making Requests

The role of the agent classes is to make the requests for data from the
B<isbndb.com> service, parse the body of the response and convert that data to
objects from the B<WebService::ISBNDB::API> hierarchy. To do this, this base
class provides methods for making the requests, which themselves are composed
of several methods restricted to the B<WebService::ISBNDB::Agent> hierarchy.

The methods are:

=over 4

=item request_single($OBJ, $ARGS)

Make a request of the service, returning a single object as a result. C<$OBJ>
controls the type of object returned, as well as the type of request sent.
C<$OBJ> can be one of three types of values:

=over 4

=item B<WebService::ISBNDB::API>-derived object

If the value is an object from one of the API classes (excluding
B<WebService::ISBNDB::API> itself), it is used not only to control the type of
request, but it is also overwritten with the result of the request. It is
also the return value of the call when successful.

=item Type name

If the value is a type recognized by the B<WebService::ISBNDB::API> class, the
class itself is retrieved via the B<class_for_type> method. That class is used
to provide the type-specific data that would otherwise be retrieved through an
existing object, and it is used to instantiate the new object with the data
returned by the request.

=item Class name

If the value is a full class name, it is first tested to see that the class is
a decendant of B<WebService::ISBNDB::API>. If so, it is used in the same way
as the class derived from the previous case.

=back

The C<$ARGS> parameter provides the arguments used in making the specific
request. It is a hash reference, whose keys and values are dependent on the
specific implementation class.

If the request returns more than one value, the first one is taken and the
rest are discarded. If the request returns no data, C<undef> is returned. If
there is an error of any sort, an exception is thrown.

=item request_all($OBJ, $ARGS)

This method sends the request, and returns all the resulting records from
the service. The arguments and behavior are identical to that of
C<request_single>, except that the return value includes all records returned
by the query.

Presently, the return value for a successful query is an array reference
containing the objects representing the matched records. This reference may
contain only one object, or even none, depending on whether the query
returned any data. In future versions, the return value will be an iterator
that manages the list internally, for faster response time and better memory
usage.

=item resolve_obj($OBJ) (R)

Resolves the disposition of the argument C<$OBJ>. This is what gets called by
B<request_single> and B<request_all> to determine how to interpret the first
argument.

This method is restricted to the B<WebService::ISBNDB::Agent> class and its
decendents.

=item raw_request($OBJ, $ARGS) (R)

This method is what gets called to actually assemble the request from the
next four methods, make the request, and return the content. In this class,
the return value is a scalar reference to the content of the HTTP response.
In case of error (either from information missing from the following methods
or from HTTP communication failure), an exception is thrown. No parsing of the
content is done by this method.

This method is restricted to the B<WebService::ISBNDB::Agent> class and its
decendents.

=item request($OBJ, $ARGS [ , $SINGLE ]) (R)

This method I<must> be overridden in the protocol implementation class. If
the base class version is called, it will always throw an exception.

This method is expected to fetch the content from B<raw_request>, above,
and return a suitable object created from the content. The C<$OBJ> and
C<$ARGS> parameters are the same as for B<request_single> and B<request_all>.
The optional argument C<$SINGLE> signifies that the request should only return
a single object, not a list of all objects returned by the service.

This method is restricted to the B<WebService::ISBNDB::Agent> class and its
decendents.

=item request_method($OBJ, $ARGS) (R)

Returns the type of HTTP request (C<GET> or C<POST>) that should be used in
making the request, as a string. Throws an exception in case of error. The
An exception is thrown in case of error (such as C<$OBJ> not being valid). The
C<$OBJ> and C<$ARGS> parameters fulfill the same roles as defined for
B<request_single>.

This method is restricted to the B<WebService::ISBNDB::Agent> class and its
decendents.

=item request_uri($OBJ, $ARGS) (R)

Returns the complete URL to use in making the request, as a B<URI> instance.
An exception is thrown in case of error (such as C<$OBJ> not being valid). The
C<$OBJ> and C<$ARGS> parameters fulfill the same roles as defined for
B<request_single>.

This method is restricted to the B<WebService::ISBNDB::Agent> class and its
decendents.

=item request_headers($OBJ, $ARGS) (R)

Returns an array reference of any additional headers needed for the request.
The format is a series of values in key/value order. The reference may be an
empty array, if no additional headers are needed. An exception is thrown if
there is an error. The C<$OBJ> and C<$ARGS> parameters are the same as defined
for B<request_single>.

This method is restricted to the B<WebService::ISBNDB::Agent> class and its
decendents.

=item request_body($OBJ, $ARGS) (R)

Returns the request body needed for making the request, as a scalar reference.
The scalar may be zero-length, if no data is needed in the request body. An
exception is thrown if there is an error. The arguments are the same as for
B<request_single> (and all the other methods in this group).

This method is restricted to the B<WebService::ISBNDB::Agent> class and its
decendents.

=back

All of the request-construction methods (request_uri(), request_headers(),
request_body() and request_method()) return no content (or null content) from
their versions in this class.
It is expected that implementation classes will override those that need to
have content (certainly B<request_uri> and B<request_method>), and leave
those that are not relevant to the protocol (REST, for example, does not need
a request body or additional headers).

=head1 SEE ALSO

L<WebService::ISBNDB::API>, L<WebService::ISBNDB::Agent::REST>,
L<LWP::UserAgent>, L<URI>

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
