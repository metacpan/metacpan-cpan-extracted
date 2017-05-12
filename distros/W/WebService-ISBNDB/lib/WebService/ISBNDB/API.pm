###############################################################################
#
# This file copyright (c) 2006-2008 by Randy J. Ray, all rights reserved
#
# See "LICENSE" in the documentation for licensing and redistribution terms.
#
###############################################################################
#
#   $Id: API.pm 48 2008-04-06 10:38:11Z  $
#
#   Description:    This is the base class for the API classes: Books,
#                   Publishers, Subjects (and the others as isbndb.com adds
#                   them to the API).
#
#   Functions:      _find
#                   _search
#                   add_type
#                   BUILD
#                   class_for_type
#                   copy
#                   find
#                   get_agent
#                   get_api_key
#                   get_default_agent
#                   get_default_agent_args
#                   get_default_api_key
#                   get_default_protocol
#                   get_protocol
#                   get_type
#                   import
#                   new
#                   normalize_args
#                   remove_type
#                   search
#                   set_agent
#                   set_default_agent
#                   set_default_agent_args
#                   set_default_api_key
#                   set_default_protocol
#                   set_protocol
#                   set_type
#
#   Libraries:      Class::Std
#                   Error
#                   WebService::ISBNDB::Agent
#
#   Global Consts:  $VERSION
#                   COREPROTOS
#                   CORETYPES
#
###############################################################################

package WebService::ISBNDB::API;

use 5.006;
use strict;
use warnings;
no warnings 'redefine';
use vars qw(@ISA $VERSION @TYPES %TYPES);
use constant CORETYPES  => qw(Authors Books Categories Publishers Subjects);

use Class::Std;
use Error;
require WebService::ISBNDB::Agent;

$VERSION = "0.23";

BEGIN
{
    @ISA = qw(Class::Std);

    @TYPES = (CORETYPES);
    %TYPES = map { $_ => __PACKAGE__ . "::$_" } @TYPES;
}

# Attributes for the ::API class, shared by all the children
my %protocol   : ATTR(:init_arg<protocol>                    :default<>);
my %api_key    : ATTR(:init_arg<api_key> :set<api_key>       :default<>);
my %type       : ATTR(:init_arg<type>                        :default<>);
my %agent      : ATTR(:init_arg<agent>                       :default<>);
my %agent_args : ATTR(:init_arg<agent_args> :set<agent_args> :default<>);

# Default values, for use by {get,set}_default_*
my %DEFAULTS = ( protocol   => 'REST',
                 api_key    => '',
                 agent      => undef,
                 agent_args => { agent => __PACKAGE__ . "/$VERSION" } );

###############################################################################
#
#   Sub Name:       import
#
#   Description:    Importer routine for "use Module" handling.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $class    in      scalar    Name of class being loaded
#                   %argz     in      hash      Key/value pairs passed in.
#
#   Returns:        1
#
###############################################################################
sub import
{
    my ($class, %argz) = @_;

    # Recognized import-keys are "api_key", "protocol", "agent" and
    # "agent_args":
    $class->set_default_protocol($argz{protocol}) if $argz{protocol};
    $class->set_default_api_key($argz{api_key}) if $argz{api_key};
    $class->set_default_agent($argz{agent}) if $argz{agent};
    $class->set_default_agent_args($argz{agent_args}) if $argz{agent_args};

    1;
}

###############################################################################
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
    my ($type, $self, %obj_defaults, $args, $new);

    # Need to make sure $class is the name, not a reference, for later tests.
    # But if it is a reference, we should also save the protocol and api_key
    # values.
    if (ref $class)
    {
        $obj_defaults{protocol} = $class->get_protocol;
        $obj_defaults{api_key} = $class->get_api_key;
        $class = ref($class);
    }

    # If $class matches this package, then they are allowed to specify a type
    # as the leading argument (Books, Publishers, etc.)
    $type = shift(@argz) if (($class eq __PACKAGE__) and (@argz > 1));
    $args = shift @argz || {};

    if ($type)
    {
        throw Error::Simple("new: Unknown factory type '$type'")
            unless $type = $class->class_for_type($type);
        # Make sure it is loaded
        eval "require $type;";
    }

    # Set any of the defaults if $class came in as an object
    if (ref $args)
    {
        foreach (qw(protocol api_key))
        {
            $args->{$_} = $obj_defaults{$_} if ($obj_defaults{$_} and
                                                ! $args->{$_});
        }
    }

    # I really hate this part here. I hate having to overload new() just to get
    # around the only-accepts-hashref-arg thing.
    if (ref $args)
    {
        $new = $type ? $type->new($args) : $class->SUPER::new($args);
    }
    else
    {
        $new = $type ? $type->new(\%obj_defaults) : $class->new(\%obj_defaults);
        $new = $new->find($args);
    }

    $new;
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

    $self->set_type('API');

    # If the 'agent' parameter is set, check it's validity. If it is valid, and
    # 'protocol' is not set, set it from the agent's protocol() method.
    if ($args->{agent})
    {
        # First, test that agent is valid
        throw Error::Simple('Value for "agent" parameter must derive from ' .
                            'WebService::ISBNDB::Agent')
            unless (ref($args->{agent}) and
                    $args->{agent}->isa('WebService::ISBNDB::Agent'));
        # Set $args->{protocol} if it isn't already set. Test it if it is.
        if ($args->{protocol})
        {
            throw Error::Simple('Provided agent does not match specified ' .
                                "protocol ('$args->{protocol}')")
                unless ($args->{agent}->protocol($args->{protocol}));
        }
        else
        {
            $args->{protocol} = $args->{agent}->protocol;
        }
    }

    # All protocols are all-uppercase, so just make sure as we assign it
    $protocol{$id}   = uc $args->{protocol} || $self->get_default_protocol;
    $agent{$id}      = $args->{agent};
    # Fall back to the defaults here
    $api_key{$id}    = $self->get_default_api_key unless $args->{api_key};
    $agent_args{$id} = $self->get_default_agent_args unless $args->{agent_args};
    # Remove these so they aren't further processed
    delete @$args{qw(protocol agent)};

    return;
}

###############################################################################
#
#   Sub Name:       get_type
#
#   Description:    Return the generic type of the object, versus the actual
#                   class.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $class    in      scalar    Class name or object
#
#   Globals:        %TYPES
#                   %type
#
#   Returns:        Type
#
###############################################################################
sub get_type
{
    my $class = shift;

    my $type = '';

    if (ref $class)
    {
        $type = $type{ident $class};
    }
    else
    {
        $type = $class->new({})->get_type;
    }

    $type;
}

###############################################################################
#
#   Sub Name:       add_type
#
#   Description:    Add a name-to-class mapping for the factory nature of this
#                   class' constructor.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $class    in      scalar    Ignored-- this can be a static
#                                                 method or not.
#                   $type     in      scalar    The type name, usually the last
#                                                 element of the classname with
#                                                 a leading cap (e.g. Books).
#                   $pack     in      scalar    The package that should be
#                                                 instantiated for the type.
#
#   Globals:        @TYPES
#                   %TYPES
#
#   Returns:        Success:    $pack (for chaining purposes)
#                   Failure:    Throws Error::Simple
#
###############################################################################
sub add_type
{
    my ($class, $type, $pack) = @_;

    throw Error::Simple("No package specfied for $type") unless $pack;

    push(@TYPES, $type);
    $TYPES{$type} = $pack;
}

###############################################################################
#
#   Sub Name:       remove_type
#
#   Description:    Delete the given type from the map.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $class    in      scalar    Ignored-- this can be a static
#                                                 method or not.
#                   $type     in      scalar    The type name, usually the last
#                                                 element of the classname with
#                                                 a leading cap (e.g. Books).
#
#   Globals:        @TYPES
#                   %TYPES
#                   CORETYPES
#
#   Returns:        Success:    void
#                   Failure:    throws Error::Simple if $type is in @CORETYPES
#
###############################################################################
sub remove_type
{
    my ($class, $type) = @_;

    throw Error::Simple("Cannot remove a core type")
        if (grep($_ eq $type, (CORETYPES)));
    delete $TYPES{$type};
    @TYPES = grep($_ ne $type, @TYPES);

    return;
}

###############################################################################
#
#   Sub Name:       class_for_type
#
#   Description:    Return the actual class that should be used to instantiate
#                   the given type.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $class    in      scalar    Ignored-- this can be a static
#                                                 method or not.
#                   $type     in      scalar    Type to look up.
#
#   Globals:        %TYPES
#
#   Returns:        Success:    class name
#                   Failure:    undef
#
###############################################################################
sub class_for_type
{
    my ($class, $type) = @_;

    $TYPES{$type};
}

###############################################################################
#
#   Sub Name:       get_api_key
#
#   Description:    Return the object's API key, or the default one if called
#                   statically.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object or class name
#
#   Globals:        %api_key
#                   $DEFAULTS
#
#   Returns:        API key
#
###############################################################################
sub get_api_key
{
    my $self = shift;

    ref($self) ? $api_key{ident $self} : $self->get_default_api_key;
}

###############################################################################
#
#   Sub Name:       get_protocol
#
#   Description:    Return the object's protocol, or the default one if called
#                   statically.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object or class name
#
#   Globals:        %protocol
#                   $DEFAULTS
#
#   Returns:        protocol string
#
###############################################################################
sub get_protocol
{
    my $self = shift;

    ref($self) ? $protocol{ident $self} : $self->get_default_protocol;
}

###############################################################################
#
#   Sub Name:       set_protocol
#
#   Description:    Set the protocol, and possibly the agent, on the object
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object of/derived from this
#                                                 class
#                   $proto    in      scalar    New protocol value
#                   $agent    in      ref       If passed, a new agent. Agent's
#                                                protocol() method must
#                                                validate $proto.
#
#   Globals:        %protocol
#
#   Returns:        Success:    $self
#                   Failure:    Throws Error::Simple
#
###############################################################################
sub set_protocol
{
    my ($self, $proto, $agent) = @_;

    # Make sure $proto is all-uppercase
    $proto = uc $proto;

    $protocol{ident $self} = $proto;
    # set_agent() tests the object's value of protocol against itself, so this
    # must be done after we've altered %protocol.
    $self->set_agent($agent) if $agent;

    $self;
}

###############################################################################
#
#   Sub Name:       get_agent
#
#   Description:    Return the agent object for the calling object. The agent
#                   object's creation is delayed until the first such request.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#
#   Globals:        %agent
#
#   Returns:        Success:    Object that is a (or derives from)
#                                 WebService::ISBNDB::Agent
#                   Failure:    throws Error::Simple
#
###############################################################################
sub get_agent
{
    my $self = shift;

    my $id = ident $self;
    my $agent = $id ? $agent{$id} : $self->get_default_agent;

    unless ($agent)
    {
        my $agent_args;
        $agent_args = $agent_args{$id} if $id;
        $agent_args = $self->get_default_agent_args unless $agent_args;
        my $protocol;
        $protocol = $protocol{$id} if $id;
        $protocol = $self->get_default_protocol unless $protocol;

        # new() in WebService::ISBNDB::Agent also acts as a factory
        $agent = WebService::ISBNDB::Agent->new($protocol,
                                                { agent_args => $agent_args });
        $agent{$id} = $agent if ($id);
    }

    $agent;
}

###############################################################################
#
#   Sub Name:       set_agent
#
#   Description:    Manually set the agent instance for this object.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $agent    in      ref       New agent object. Must derive
#                                                 from
#                                                 WebService::ISBNDB::Agent.
#
#   Globals:        %agent
#
#   Returns:        Success:    $self
#                   Failure:    throws Error::Simple
#
###############################################################################
sub set_agent
{
    my ($self, $agent) = @_;

    throw Error::Simple("New agent must derive from WebService::ISBNDB::Agent")
        unless (ref $agent and $agent->isa('WebService::ISBNDB::Agent'));
    throw Error::Simple("New agent does not match object's declared protocol" .
                        ' (' . $self->get_protocol . ')')
        unless $agent->protocol($self->get_protocol);

    $agent{ident $self} = $agent;

    $self;
}

###############################################################################
#
#   Sub Name:       set_type
#
#   Description:    Setter for the type attribute, marked RESTRICTED so that
#                   it can only be used here and in subclasses.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $type     in      scalar    Type value
#
#   Globals:        %type
#
#   Returns:        $self
#
###############################################################################
sub set_type : RESTRICTED
{
    my ($self, $type) = @_;

    $type{ident $self} = $type;

    $self;
}

###############################################################################
#
#   Sub Name:       find
#
#   Description:    Find a single entity, based on the first argument (which
#                   identifies the type).
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   @args     in      array     Variable, depending on $self.
#                                                 See text.
#
#   Globals:        %TYPES
#
#   Returns:        Success:    $self or new object
#                   Failure:    throws Error::Simple
#
###############################################################################
sub find
{
    my ($self, @args) = @_;

    # If $self is/points to the API class, then the first element of @args has
    # to be the name of a data class, and we defer to its find() method with
    # the remainder of @args.
    if ($self->get_type eq 'API')
    {
        my $type = shift(@args);
        throw Error::Simple("find: Unknown factory type '$type'")
            unless ($type = $self->class_for_type($type));
        eval "require $type;";
        return $type->find(@args);
    }

    # If it isn't, just fall through to the semi-private _find()
    $self->_find($self->normalize_args(@args));
}

###############################################################################
#
#   Sub Name:       _find
#
#   Description:    Actual find() implementation. Calls in to the correct
#                   request_{all|single} method of the agent this object has
#                   allocated.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object or class
#                   $args     in      hashref   Hash reference of the arguments
#                                                 for the find operation.
#
#   Returns:        Success:    New object
#                   Failure:    throws Error::Simple
#
###############################################################################
sub _find : PRIVATE
{
    my ($self, $args) = @_;

    $self->get_agent->request_single($self, $args);
}

###############################################################################
#
#   Sub Name:       search
#
#   Description:    Find zero or more entities, based on the criteria
#                   provided. If this is called from the API class, the first
#                   argument might identify the type.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   @args     in      array     Variable, depending on $self.
#                                                 See text.
#
#   Globals:        %TYPES
#
#   Returns:        Success:    $self or new object
#                   Failure:    throws Error::Simple
#
###############################################################################
sub search
{
    my ($self, @args) = @_;

    # If $self is/points to the API class, then the first element of @args has
    # to be the name of a data class, and we defer to its search() method with
    # the remainder of @args.
    if ($self->get_type eq 'API')
    {
        my $type = shift(@args);
        throw Error::Simple("search: Unknown factory type '$type'")
            unless ($type = $self->class_for_type($type));
        eval "require $type;";
        $args[0]->{api_key} = $self->get_api_key;
        return $type->search(@args);
    }

    # Otherwise, fall-through to the semi-private _search().
    $self->_search($self->normalize_args(@args));
}

###############################################################################
#
#   Sub Name:       _search
#
#   Description:    Actual search() implementation. Calls in to the correct
#                   request_{all|single} method of the agent this object has
#                   allocated.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object or class
#                   $args     in      hashref   Hash reference of the arguments
#                                                 for the find operation.
#
#   Returns:        Success:    List-reference of zero+ objects
#                   Failure:    throws Error::Simple
#
###############################################################################
sub _search : PRIVATE
{
    my ($self, $args) = @_;

    $self->get_agent->request_all($self, $args);
}

###############################################################################
#
#   Sub Name:       normalize_args
#
#   Description:    Hook routine for sub-classes to override; allows for
#                   translation of the keys in $args to the form needed by
#                   the service.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $class    in      scalar    Ignored
#                   $args     in      hashref   Returned unaltered
#
#   Returns:        $args, without change
#
###############################################################################
sub normalize_args
{
    $_[1];
}

###############################################################################
#
#   Sub Name:       get_default_protocol
#
#   Description:    Return the current value of the default protocol
#
#   Arguments:      All ignored
#
#   Globals:        %DEFAULTS
#
#   Returns:        $DEFAULTS{protocol}
#
###############################################################################
sub get_default_protocol
{
    $DEFAULTS{protocol};
}

###############################################################################
#
#   Sub Name:       set_default_protocol
#
#   Description:    Set a new value for the default protocol
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $class    in      scalar    Ignored
#                   $proto    in      scalar    New protocol value; forced UC
#
#   Globals:        $DEFAULTS{protocol}
#
#   Returns:        void
#
###############################################################################
sub set_default_protocol
{
    my ($class, $proto) = @_;

    $DEFAULTS{protocol} = uc $proto;
    return;
}

###############################################################################
#
#   Sub Name:       get_default_api_key
#
#   Description:    Return the current value of the default API key
#
#   Arguments:      All ignored
#
#   Globals:        %DEFAULTS
#
#   Returns:        $DEFAULTS{api_key}
#
###############################################################################
sub get_default_api_key
{
    $DEFAULTS{api_key};
}

###############################################################################
#
#   Sub Name:       set_default_api_key
#
#   Description:    Set a new value for $default_api_key
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $class    in      scalar    Ignored
#                   $api_key  in      scalar    New API key value
#
#   Globals:        %DEFAULTS
#
#   Returns:        void
#
###############################################################################
sub set_default_api_key
{
    my ($class, $api_key) = @_;

    $DEFAULTS{api_key} = $api_key;
    return;
}

###############################################################################
#
#   Sub Name:       get_default_agent
#
#   Description:    Retrieve the default agent (LWP::UserAgent) object
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $class    in      scalar    Class called from
#
#   Globals:        %DEFAULTS
#
#   Returns:        $DEFAULTS{agent}
#
###############################################################################
sub get_default_agent
{
    my $class = shift;

    unless ($DEFAULTS{agent})
    {
        $DEFAULTS{agent} =
            WebService::ISBNDB::Agent->new($class->get_protocol(),
                                           { agent_args =>
                                             $DEFAULTS{agent_args} });
    }

    $DEFAULTS{agent};
}

###############################################################################
#
#   Sub Name:       set_default_agent
#
#   Description:    Set a new value for the default agent. Tests to see if it
#                   is a derivative of LWP::UserAgent.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $class    in      scalar    Ignored
#                   $agent    in      ref       New agent value
#
#   Globals:        %DEFAULTS
#
#   Returns:        Success:    void
#                   Failure:    throws Error::Simple
#
###############################################################################
sub set_default_agent
{
    my ($class, $agent) = @_;

    throw Error::Simple("Argument to 'set_default_agent' must be an object " .
                        "of or derived from LWP::UserAgent")
        unless (! defined $agent or
                (ref $agent and $agent->isa('LWP::UserAgent')));

    $DEFAULTS{agent} = $agent;
    return;
}

###############################################################################
#
#   Sub Name:       get_default_agent_args
#
#   Description:    Retrieve the default agent args
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $class    in      scalar    Ignored
#
#   Globals:        %DEFAULTS
#
#   Returns:        $DEFAULTS{agent_args}
#
###############################################################################
sub get_default_agent_args
{
    $DEFAULTS{agent_args};
}

###############################################################################
#
#   Sub Name:       set_default_agent_args
#
#   Description:    Set a new value for the default agent arguments. Tests to
#                   see that it is a has reference.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $class    in      scalar    Ignored
#                   $agent_args in    ref       New agent_args value
#
#   Globals:        %DEFAULTS
#
#   Returns:        Success:    void
#                   Failure:    throws Error::Simple
#
###############################################################################
sub set_default_agent_args
{
    my ($class, $agent_args) = @_;

    throw Error::Simple("Argument to 'set_default_agent_args' must be a " .
                        "hash-reference")
        unless (ref($agent_args) eq 'HASH');

    $DEFAULTS{agent_args} = $agent_args;
    return;
}

###############################################################################
#
#   Sub Name:       copy
#
#   Description:    Copy attributes from the target object to the caller.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object
#                   $target   in      ref       Object of the same class
#
#   Globals:        %protocol
#                   %api_key
#                   %type
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

    $protocol{$id1} = $protocol{$id2};
    $api_key{$id1}  = $api_key{$id2};
    $type{$id1}     = $type{$id2};

    return;
}

1;

=pod

=head1 NAME

WebService::ISBNDB::API - Base class for the WebService::ISBNDB API classes

=head1 SYNOPSIS

    require WebService::ISBNDB::API;

    $handle = WebService::ISBNDB::API->new({ protocol => REST =>
                                      api_key => $key });

    $book = $handle->new(Books => { isbn => '0596002068' });
    $all_lotr = $handle->search(Books =>
                                { title => 'lord of the rings ' });

=head1 DESCRIPTION

The B<WebService::ISBNDB::API> class is the base for the classes that handle
books, publishers, authors, categories and subjects. It also acts as a
factory-class for instantiating those other classes. Any of the data classes
can be created from the constructor of this class, using the syntax described
below.

This class manages the common elements of the data classes, including the
handling of the communication agent used to make requests of B<isbndb.com>.
This class (and all sub-classes of it) are based on the B<Class::Std>
inside-out objects pattern. See L<Class::Std> for more detail.

All error conditions in the methods of this class are handled using the
exception model provided by the B<Error> module. Most errors are thrown in
the form of B<Error::Simple> exception objects. See L<Error> for more
detail.

=head1 USING THE ISBNDB.COM SERVICE

In order to access the B<isbndb.com> web service programmatically, you must
first register an account on their site (see
L<https://isbndb.com/account/create.html>) and then create an access key.
You can create more than one key, as needed. All the API calls require the
access key be part of the parameters.

More information is available at L<http://isbndb.com>. You can also view the
documentation for their API at L<http://isbndb.com/docs/api/>.

=head1 METHODS

The following methods are provided by this class, usable by all derived
classes. Private methods are not documented here.

=head2 Constructor

The constructor for this class behaves a little differently than the default
constructor provided by B<Class::Std>.

=over 4

=item new([ $TYPE, ] $ARGS)

Constructs a new object, returning the referent. The value of C<$ARGS> is a
hash-reference of key/value pairs that correspond to the attributes for the
class. If C<$TYPE> is provided, then the value must match one of the known
data-types, and the new object will be created from that class rather than
B<WebService::ISBNDB::API>. Likewise, C<$ARGS> will be passed to that class'
constructor and not processed at all by this one.

If C<$TYPE> is not a known type (see L</Managing Types>), then an exception
of type B<Error::Simple> is thrown.

=back

The class also defines:

=over 4

=item copy($TARGET)

Copies the target object into the calling object. All attributes (including
the ID) are copied. This method is marked "CUMULATIVE" (see L<Class::Std>),
and any sub-class of this class should provide their own copy() and also mark
it "CUMULATIVE", to ensure that all attributes at all levels are copied.

=back

This method copies only the basic attributes. Each of the implementation
classes must provide additional copy() methods (also marked "CUMULATIVE") to
ensure that all attributes are copied.

=head2 Accessors

The accessor methods are used to set and retrieve the attributes (instance
data) stored on the object. While a few of them have special behavior, most
operate as simple get or set accessors as described in L<Class::Std>. The
attributes for this class are:

=over 4

=item protocol

This attribute identifies the communication protocol this object will use for
making requests of the B<isbndb.com> service. The value for it is always
forced to upper-case, as all protocols are regarded in that manner.
 (See L</Default Attribute Values>.)

=item api_key

To use the B<isbndb.com> service, you must register on their web site and
obtain an API key. The key must be used on all data requests to their API.
This attribute stores the API key to be used on all requests made by the
object. (See L</Default Attribute Values>.)

=item agent

This attribute stores the object used for communicating with the service.
The value must be a sub-class of the B<WebService::ISBNDB::Agent> class.
 (See L</Default Attribute Values>.)

=item agent_args

When the B<WebService::ISBNDB::Agent>-based object is instantiated, any
arguments stored in this attribute will be passed to the constructor. If set,
this attribute's value must be a hash-reference (otherwise the constructor
will throw an exception). (See L</Default Attribute Values>.)

=item type

This attribute is read-only by users that are not sub-classes of this class.
It identifies the class-type of the object, which is generally the last
element of the class name (C<API>, C<Books>, etc.). It allows the
B<WebService::ISBNDB::Agent> sub-classes to make choices based on the type of
the object. ("Type" in this context should not be confused with "types" as
they pertain to mapping books, publishers, etc. to specific data classes.)

=back

The following accessor methods are provided by this class:

=over 4

=item get_protocol

Retrieve the current value of the protocol attribute.

=item set_protocol($PROTO [ , $AGENT ])

Set the protocol to use for communication. Optionally, you can also provide
an agent instance at the same time, and set both values. If an agent is
specified, it will be tested against the new protocol value, to make sure it
works with that protocol. If the agent does not match the protocol, an
exception will be thrown.

=item get_api_key

Retrieve the current API key.

=item set_api_key

Set the API key to use when contacting the service. If this value is not
recognized by the B<isbndb.com> service, you will not be able to retrieve any
data.

=item get_agent

Retrieve the current B<WebService::ISBNDB::Agent>-derived object used for
communication. Unless the agent was explicitly provided as an argument to
the constructor, the agent object is constructed lazily: it is only
instantiated upon the first call to this method.

=item set_agent

Set a new agent object for use when this object makes requests from the
service. An agent object must derive from the B<WebService::ISBNDB::Agent>
class (that class itself cannot act as an agent). When a new agent is
assigned, its B<protocol> method is called with the current value of the
C<protocol> attribute of the object, to ensure that the agent matches the
protocol. If not, an exception is thrown.

=item get_agent_args

Get the arguments that are to be passed to agent-instantiation.

=item set_agent_args

Provide a new set of arguments to be used when instantiating an agent object.
The value must be a hash reference, or the constructor for the agent class
will thrown an exception.

=item get_type

Get the class' "type". In most cases, this is the last component of the
class name. Note that there is no set-accessor for this attribute; it cannot
be set by outside users.

=back

=head2 Default Attribute Values

In addition to the above, the following accessors are provided to allow
users to set default values for the protocol, the API key, the agent and the
defaut arguments for agent construction. This allows you
to set these once, at the start of the application, and not have to pass them
to every new object instantiation:

=over 4

=item set_default_protocol($PROTO)

Sets the default protocol to the value of C<$PROTO>. Unlike the API key, there
is already a default value for this when the module is loaded (B<REST>).

=item get_default_protocol

Returns the current default protocol.

=item set_default_api_key($KEY)

Sets a new default API key. There is no built-in default for this, so you must
either call this, set it via module-import (see below), or provide the key
value for each individual object creation.

=item get_default_api_key

Returns the current default API key.

=item set_default_agent($AGENT)

Sets a new value for the default agent. Any object created without an C<agent>
attribute will inherit this value. The value must be an instance of
B<LWP::UserAgent> or a derivative class.

=item get_default_agent

Get the default agent. If it hasn't been set the first time this is called,
one is created (possibly using the default agent arguments).

=item set_default_agent_args($ARGS)

Sets a new value for the default arguments to agent creation. Any time an
agent is created without the object having an explicit value for arguments
to pass, this value is read and used. The value must be a hash reference.

=item get_default_agent_args

Get the set of default agent arguments, if any.

=back

Besides using these accessors to provide the defaults, you can also specify
them when loading the module:

    use WebService::ISBNDB::API (api_key => 'abc123');

C<agent>, C<agent_args>, C<api_key> and C<protocol> are recognized at
use-time.

=head2 Managing Types

As the root of the data-class hierarchy, this package also provides the
methods for managing the data-types known to the overall module.

The built-in data-types are:

=over 4

=item Authors

This type covers the author data structures returned by B<isbndb.com>. It is
covered in detail in L<WebService::ISBNDB::API::Authors>.
=item Books

This type covers the book data structures returned by B<isbndb.com>. It is
covered in detail in L<WebService::ISBNDB::API::Books>.

=item Categories

This type covers the category data structures returned by B<isbndb.com>. It
is covered in detail in L<WebService::ISBNDB::API::Categories>.

=item Publishers

This type covers the publisher data structures returned by B<isbndb.com>. It
is covered in detail in L<WebService::ISBNDB::API::Publishers>.

=item Subjects

This type covers the subject data structures returned by B<isbndb.com>. It is
covered in detail in L<WebService::ISBNDB::API::Subjects>.

=back

Note that the types are case-sensitive.

The following methods operate on the internal types map:

=over 4

=item add_type($TYPE, $CLASS)

Add a mapping for the type specified by C<$TYPE> to the class specified in
C<$CLASS>. C<$TYPE> may be one of the core types listed above; if so, then the
new class will override the built-in class for that type. You cannot remove
a type/class mapping for any of the core types; you can only re-override them
by calling the method again. If you want to temporarily redirect a type, you
must save the original value (using B<class_for_type>) and manually restore it
by called B<add_type> again.

=item class_for_type($TYPE)

Returns the class-name for the given C<$TYPE>. Throws an exception if C<$TYPE>
is not in the mapping table.

=item remove_type($TYPE)

Removes the type/class mapping for the given C<$TYPE>. Note that you cannot
remove the mappings for any of the core types listed above, even if you have
already overridden them with B<add_type>. If you pass any of the core types,
an exception will be thrown.

=back

All of the type-map methods may be called as static methods.

=head2 Retrieving Data

B<WebService::ISBNDB::API> and its sub-classes support the retrieval of data
in two ways: single-record and searching.

Single-record retrieval is for getting just one result from the service,
usually from a known unique key (such as fetching a book by the ISBN). The
interface for it always returns a single result, even when the criteria are
not specific-enough and more than one record is returned. In these cases, the
first record is used and the rest discarded.

Searching returns zero or more results from a search of the service using the
provided criteria. Presently, the return is in the form of a list-reference
(even when the result-set has only one element or no elements). This will
change in the future, to an object-base result-set that offers iterators and
delayed-loading of results.

The data-retrieving methods are:

=over 4

=item find($TYPE, $IDENT|$ARGS)

Finds a single record, using either a scalar identifying value (C<$IDENT>) or
a hash reference (C<$ARGS>) with one or more key/value pairs. The value of
C<$TYPE> tells C<WebService::ISBNDB::API>) which data class to do the
find-operation on. If the value is not a known type, an exception is thrown.

How the scalar value C<$IDENT> is used in the data-retrieval is dependent on
the value of C<$TYPE>. See the documentation for the various data classes
for more detail.

=item search($TYPE, $ARGS)

Search for items of type C<$TYPE> using the key/value pairs in the hash
reference C<$ARGS>. C<$ARGS> must be a hash reference, there is no corner-case
for a scalar as with B<find>.

=item normalize_args($ARGS)

In this class, this method does nothing. It is available for sub-classes to
overload. If a class overloads it, the requirement is that any changes to the
arguments be made in-place, altering C<$ARGS>, and that the return value be
either C<$ARGS> itself or a copy.

The purpose of this method is to allow implementation classes to make any
translation of user-space argument names to the names used by B<isbndb.com>.
Most of the implementation classes also use it to add more arguments in order
to retrieve extra data from the service.

=back

These methods may be called as static methods.

=head1 CAVEATS

The data returned by this class is only as accurate as the data retrieved from
B<isbndb.com>.

The list of results from calling search() is currently limited to 10 items.
This limit will be removed in an upcoming release, when iterators are
implemented.

=head1 SEE ALSO

L<Class::Std>, L<Error>, L<WebService::ISBNDB::Agent>,
L<WebService::ISBNDB::API::Authors>, L<WebService::ISBNDB::API::Books>,
L<WebService::ISBNDB::API::Categories>,
L<WebService::ISBNDB::API::Publishers>, L<WebService::ISBNDB::API::Subjects>

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
