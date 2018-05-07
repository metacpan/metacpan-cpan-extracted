package autobox;

use 5.008;

use strict;
use warnings;

use Carp;
use XSLoader;
use Scalar::Util;
use Scope::Guard;
use Storable;

# XXX this declaration must be on a single line
# https://metacpan.org/pod/version#How-to-declare()-a-dotted-decimal-version
use version 0.77; our $VERSION = version->declare('v3.0.1');

XSLoader::load 'autobox', $VERSION;

use autobox::universal (); # don't import

############################################# PRIVATE ###############################################

my $SEQ            = 0;  # unique identifier for synthetic classes
my $BINDINGS_CACHE = {}; # hold a reference to the bindings hashes
my $CLASS_CACHE    = {}; # reuse the same synthetic class if the @isa has been seen before

# all supported types
# the boolean indicates whether the type is a real internal type (as opposed to a virtual type)
my %TYPES = (
    UNDEF     => 1,
    INTEGER   => 1,
    FLOAT     => 1,
    NUMBER    => 0,
    STRING    => 1,
    SCALAR    => 0,
    ARRAY     => 1,
    HASH      => 1,
    CODE      => 1,
    UNIVERSAL => 0
);

# type hierarchy: keys are parents, values are (depth, children) pairs
my %ISA = (
    UNIVERSAL => [ 0, [ qw(SCALAR ARRAY HASH CODE) ] ],
    SCALAR    => [ 1, [ qw(STRING NUMBER) ] ],
    NUMBER    => [ 2, [ qw(INTEGER FLOAT) ] ]
);

# default bindings when no args are supplied
my %DEFAULT = (
    SCALAR => 'SCALAR',
    ARRAY  => 'ARRAY',
    HASH   => 'HASH',
    CODE   => 'CODE'
);

# reinvent List::MoreUtils::uniq to keep the dependencies light - return a reference
# to an array containing (in order) the unique members of the supplied list
sub _uniq($) {
    my $list = shift;
    my (%seen, @uniq);

    for my $element (@$list) {
        next if ($seen{$element});
        push @uniq, $element;
        $seen{$element} = 1;
    }

    return [ @uniq ];
}

# create a shim class - actual methods are implemented by the classes in its @ISA
#
# as an optimization, return the previously-generated class
# if we've seen the same (canonicalized) @isa before
sub _generate_class($) {
    my $isa = _uniq(shift);

    # As an optimization, simply return the class if there's only one.
    # This speeds up method lookup as the method can (often) be found directly in the stash
    # rather than in the ISA hierarchy with its attendant AUTOLOAD-related overhead
    if (@$isa == 1) {
        my $class = $isa->[0];
        _make_class_accessor($class); # NOP if it has already been added
        return $class;
    }

    my $key = Storable::freeze($isa);

    return $CLASS_CACHE->{$key} ||= do {
        my $class = sprintf('autobox::_shim_%d_', ++$SEQ);
        my $synthetic_class_isa = _get_isa($class); # i.e. autovivify

        @$synthetic_class_isa = @$isa;
        _make_class_accessor($class);
        $class;
    };
}

# expose the autobox class (for can, isa &c.)
# https://rt.cpan.org/Ticket/Display.html?id=55565
sub _make_class_accessor ($) {
    my $class = shift;
    return unless (defined $class);

    {
        no strict 'refs';
        *{"$class\::autobox_class"} = sub { $class } unless (*{"$class\::autobox_class"}{CODE});
    }
}

# pretty-print the bindings hash by showing its values as the inherited classes rather than the synthetic class
sub _pretty_print($) {
    my $hash = { %{ shift() } }; # clone the hash to isolate it from the original

    # reverse() turns a hash that maps an isa signature to a class name into a hash that maps
    # a class name into a boolean
    my %synthetic = reverse(%$CLASS_CACHE);

    for my $type (keys %$hash) {
        my $class = $hash->{$type};
        $hash->{$type} = $synthetic{$class} ? [ _get_isa($class) ] : [ $class ];
    }

    return $hash;
}

# default sub called when the DEBUG option is supplied with a true value
# prints the assigned bindings for the current scope
sub _debug ($) {
    my $bindings = shift;
    require Data::Dumper;
    no warnings qw(once);
    local ($|, $Data::Dumper::Indent, $Data::Dumper::Terse, $Data::Dumper::Sortkeys) = (1, 1, 1, 1);
    print STDERR Data::Dumper::Dumper($bindings), $/;
}

# return true if $ref ISA $class - works with non-references, unblessed references and objects
# we can't use UNIVERSAL::isa to test if a value is an array ref;
# if the value is 'ARRAY', and that package exists, then UNIVERSAL::isa('ARRAY', 'ARRAY') is true!
sub _isa($$) {
    my ($ref, $class) = @_;
    return Scalar::Util::blessed($ref) ? $ref->isa($class) : ref($ref) eq $class;
}

# get/autovivify the @ISA for the specified class
sub _get_isa($) {
    my $class = shift;
    my $isa   = do {
        no strict 'refs';
        *{"$class\::ISA"}{ARRAY};
    };
    return wantarray ? @$isa : $isa;
}

# install a new set of bindings for the current scope
#
# XXX this could be refined to reuse the same hashref if its contents have already been seen,
# but that requires each (frozen) hash to be cached; at best, it may not be much of a win, and at
# worst it will increase bloat
sub _install ($) {
    my $bindings = shift;
    $^H{autobox} = $bindings;
    $BINDINGS_CACHE->{$bindings} = $bindings; # keep the $bindings hash alive
}

# return the supplied class name or a new class name made by appending the specified
# type to the namespace prefix
sub _expand_namespace($$) {
    my ($class, $type) = @_;

    # make sure we can weed out classes that are empty strings or undef by returning an empty list
    Carp::confess("_expand_namespace not called in list context") unless (wantarray);

    if ((defined $class) && ($class ne '')) {
        ($class =~ /::$/) ? "$class$type" : $class;
    } else { # return an empty list
        ()
    }
}

############################################# PUBLIC (Methods) ###############################################

# enable some flavour of autoboxing in the current scope
sub import {
    my $class = shift;
    my %args = ((@_ == 1) && _isa($_[0], 'HASH')) ? %{shift()} : @_; # hash or hashref
    my $debug = delete $args{DEBUG};

    %args = %DEFAULT unless (%args); # wait till DEBUG has been deleted

    # normalize %args so that it has a (possibly empty) array ref for all types, both real and virtual
    for my $type (keys %TYPES) {
        if (exists $args{$type}) { # exists() as the value may be undef (or ''), meaning "don't default this type"
            if (_isa($args{$type}, 'ARRAY')) {
                $args{$type} = [ @{$args{$type}} ]; # clone the array ref to isolate changes
            } else {
                $args{$type} = [ $args{$type} ];
            }
        } else {
            $args{$type} = [];
        }
    }

    # if supplied, fill in defaults for unspecified SCALAR, ARRAY, HASH and CODE bindings
    # must be done before the virtual type expansion below as one of the defaults, SCALAR, is a
    # virtual type

    my $default = delete $args{DEFAULT};

    if ($default) {
        $default = [ $default ] unless (_isa($default, 'ARRAY')); # no need to clone as we flatten it each time

        for my $type (keys %DEFAULT) {
            # don't default if a binding has already been supplied; this may include an undef value meaning
            # "don't default this type" e.g.
            #
            #     use autobox
            #         DEFAULT => 'MyDefault',
            #         HASH    => undef;
            #
            # undefs are winnowed out by _expand_namespace

            next if (@{$args{$type}});
            push @{$args{$type}}, map { _expand_namespace($_, $type) } @$default;
        }
    }

    # expand the virtual type "macros" from the root to the leaves
    for my $vtype (sort { $ISA{$a}->[0] <=> $ISA{$b}->[0] } keys %ISA) {
        next unless ($args{$vtype});

        my @types = @{$ISA{$vtype}->[1]};

        for my $type (@types) {
            if (_isa($args{$vtype}, 'ARRAY')) {
                push @{$args{$type}}, map { _expand_namespace($_, $vtype) } @{$args{$vtype}};
            } else {
                # _expand_namespace returns an empty list if $args{$vtype} is undef (or '')
                push @{$args{$type}}, _expand_namespace($args{$vtype}, $vtype);
            }
        }

        delete $args{$vtype};
    }

    my $bindings; # custom typemap

    # clone the bindings hash if available
    #
    # we may be assigning to it, and we don't want to contaminate outer/previous bindings
    # with nested/new bindings
    #
    # as of 5.10, references in %^H get stringified at runtime, but we don't need them then

    $bindings = $^H{autobox} ? { %{ $^H{autobox} } } : {};

    # sanity check %args, expand the namespace prefixes into class names,
    # and copy values to the $bindings hash

    my %synthetic = reverse(%$CLASS_CACHE); # synthetic class name => bool - see _pretty_print

    for my $type (keys %args) {
        # we've handled the virtual types, so we only need to check that this is a valid (real) type
        Carp::confess("unrecognized option: '", (defined $type ? $type : '<undef>'), "'") unless ($TYPES{$type});

        my (@isa, $class);

        if ($class = $bindings->{$type}) {
            @isa = $synthetic{$class} ? _get_isa($class) : ($class);
        }

        # perform namespace expansion; dups are removed in _generate_class below
        push @isa, map { _expand_namespace($_, $type) } @{$args{$type}};

        $bindings->{$type} = [ @isa ]; # assign the (possibly) new @isa for this type
    }

    # replace each array ref of classes with the name of the generated class.
    # if there's only one class in the type's @ISA (e.g. SCALAR => 'MyScalar') then
    # that class is used; otherwise a shim class whose @ISA contains the two or more classes
    # is created

    for my $type (keys %$bindings) {
        my $isa = $bindings->{$type};

        # delete empty arrays e.g. use autobox SCALAR => []
        if (@$isa == 0) {
            delete $bindings->{$type};
        } else {
            # associate the synthetic/single class with the specified type
            $bindings->{$type} = _generate_class($isa);
        }
    }

    # This turns on autoboxing i.e. the method call checker sets a flag on the method call op
    # and replaces its default handler with the autobox implementation.
    #
    # It needs to be set unconditionally because it may have been unset in unimport

    $^H |= 0x80020000; # set HINT_LOCALIZE_HH + an unused bit to work around a %^H bug

    # install the specified bindings in the current scope
    _install($bindings);

    # this is %^H as an integer - it changes as scopes are entered/exited
    # we don't need to stack/unstack it in %^H as %^H itself takes care of that
    # note: we need to call this *after* %^H is referenced (and possibly created) above

    my $scope = _scope();
    my $old_scope = exists($^H{autobox_scope})? $^H{autobox_scope} : 0;
    my $new_scope; # is this a new (top-level or nested) scope?

    if ($scope == $old_scope) {
        $new_scope = 0;
    } else {
        $^H{autobox_scope} = $scope;
        $new_scope = 1;
    }

    # warn "OLD ($old_scope) => NEW ($scope): $new_scope ", join(':', (caller(1))[0 .. 2]), $/;

    if ($debug) {
        $debug = \&_debug unless (_isa($debug, 'CODE'));
        $debug->(_pretty_print($bindings));
    }

    return unless ($new_scope);

    # This sub is called when this scope's $^H{autobox_leave} is deleted, usually when
    # %^H is destroyed at the end of the scope, but possibly directly in unimport()
    #
    # _enter splices in the autobox method call checker and method call op
    # if they're not already enabled
    #
    # _leave performs the necessary housekeeping to ensure that the default
    # checker and op are restored when autobox is no longer in scope

    my $guard = Scope::Guard->new(sub { _leave() });
    $^H{autobox_leave} = $guard;

    _enter();
}

# delete one or more bindings; if none remain, disable autobox in the current scope
#
# note: if bindings remain, we need to create a new hash (initially a clone of the current
# hash) so that the previous hash (if any) is not contaminated by new deletion(s)
#
#   use autobox;
#
#       "foo"->bar;
#
#   no autobox qw(SCALAR); # don't clobber the default bindings for "foo"->bar
#
# however, if there are no more bindings we can remove all traces of autobox from the
# current scope.

sub unimport {
    my ($class, @args) = @_;

    # the only situation in which there is no bindings hash is if this is a "no autobox"
    # that precedes any "use autobox", in which case we don't need to turn autoboxing off as it's
    # not yet been turned on
    return unless ($^H{autobox});

    my $bindings;

    if (@args) {
        $bindings = { %{$^H{autobox}} }; # clone the current bindings hash
        my %args = map { $_ => 1 } @args;

        # expand any virtual type "macros"
        for my $vtype (sort { $ISA{$a}->[0] <=> $ISA{$b}->[0] } keys %ISA) {
            next unless ($args{$vtype});

            # we could delete the types directly from $bindings here, but we may as well pipe them
            # through the option checker below to ensure correctness
            $args{$_} = 1 for (@{$ISA{$vtype}->[1]});

            delete $args{$vtype};
        }

        for my $type (keys %args) {
            # we've handled the virtual types, so we only need to check that this is a valid (real) type
            Carp::confess("unrecognized option: '", (defined $type ? $type : '<undef>'), "'") unless ($TYPES{$type});
            delete $bindings->{$type};
        }
    } else { # turn off autoboxing
        $bindings = {}; # empty hash to trigger full deletion below
    }

    if (%$bindings) {
        _install($bindings);
    } else { # remove all traces of autobox from the current scope
        $^H &= ~0x80020000; # unset HINT_LOCALIZE_HH + the additional bit
        delete $^H{autobox};
        delete $^H{autobox_scope};
        delete $^H{autobox_leave}; # triggers the leave handler
    }
}

1;
