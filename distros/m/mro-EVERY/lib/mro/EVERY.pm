########################################################################
# housekeeping
########################################################################

package mro::EVERY v1.0.1;
use v5.24;
use mro;

use Carp            qw( croak           );
use Scalar::Util    qw( blessed         );
use Symbol          qw( qualify_to_ref  );

########################################################################
# package varaibles
########################################################################

our @CARP_NOT   = ( __PACKAGE__, qw( mro ) );
my %class2dfs   = ();

########################################################################
# utility subs
########################################################################

my $find_name
= sub
{
    my $proto   = shift;
    my $auto    = shift;
    my ($name)  = $auto =~ m{ (\w+) $}x;
    my $class   = blessed $proto || $proto;

    $proto->can( $name )
    or croak "Botched EVERY: '$proto' cannot '$name'";

    # class at entry point gets to decide the mro type.

    my $mro     = $class2dfs{ $class } || $class->mro::get_mro;
    my @isa     = $class->mro::get_linear_isa( $mro )->@*;

    # @found preserves array context of map.
    #
    # this should never croak afer the can
    # check unless they have an overloaded 
    # can and forgot qw( autoload );

    my @found
    = map
    {
        *{ qualify_to_ref $name => $_ }{ CODE }
        or
        ()
    }
    @isa
    or
    croak "Bogus $proto: '$name' not in @isa";

    @found
};

my $find_auto
= sub
{
    my $proto   = shift;
    my $auto    = shift;
    my ($name)  = $auto =~ m{ (\w+) $}x;

    $proto->can( $name )
    or croak "Botched EVERY: '$proto' cannot '$name'";

    local $"    = ',';
    my @isa     = $proto->mro::get_linear_isa->@*;

    # @found preserves array context of map.

    my @found
    = grep
    {
        $_
    }
    map
    {
        *{ qualify_to_ref $name => $_ }{ CODE }
        or
        do
        {
            my $isa = qualify_to_ref ISA        => $_;
            my $ref = qualify_to_ref AUTOLOAD   => $_;

            local *$isa = [];

            # at this point can is isolated to the
            # single pacakge.

            my $al
            = $_->can( $name )
            ? *{ $ref }{ CODE }
            : ''
            ;

            $al
            ?   sub
                {
                    # at this point if package can $name and
                    # has an AUTOLOAD but not the named sub.
                    #
                    # install $AUTOLOAD and bon voyage!

                    local *{ $ref } = $auto;
                    goto &$al;
                }
            : ()
            ;
        }
    }
    @isa
    or
    croak "Bogus $proto: '$name' & AUTOLOAD not in @isa";

    @found
};

my $finder  = $find_name;

sub import
{
    shift;
    my $caller  = caller;

    for( @_ )
    {
        my ( $status, $arg ) = m{ (no)? (dfs|autoload) }x;

        if( $arg eq 'dfs' )
        {
            # delay the lookup of mro::get_mro until runtim
            # to allow classes to fiddle with it at runtime.

            if( $status  )
            {
                delete $class2dfs{ $caller }
            }
            else
            {
                $class2dfs{ $caller } = 'dfs'
            }
        }
        elsif( $arg eq 'autoload' )
        {
            $finder
            = $status
            ? $find_name
            : $find_auto
        }
        else
        {
            croak "Botched EVERY: unknown argument '$_'";
        }
    }

    return
}

########################################################################
# pseudo-packages
########################################################################

package EVERY;
use v5.22;
use Carp            qw( croak   );
use List::Util      qw( uniq    );

our @CARP_NOT   = ( __PACKAGE__, qw( mro ) );
our $AUTOLOAD   = '';

AUTOLOAD
{
    my $proto   = shift
    or croak "Bogus EVERY, called without an object.";

    # remaining arguments left on the stack.

    $proto->$_( @_ )
    for uniq $proto->$finder( $AUTOLOAD );
}

package EVERY::LAST;
use v5.22;
use Carp            qw( croak   );
use List::Util      qw( uniq    );

our @CARP_NOT   = ( __PACKAGE__, qw( mro ) );
our $AUTOLOAD   = '';

AUTOLOAD
{
    my $proto   = shift
    or croak "Bogus EVERY::LAST, called without an object.";

    # remaining arguments left on the stack.

    $proto->$_( @_ )
    for uniq reverse $proto->$finder( $AUTOLOAD );
}

# keep require happy
1
__END__

=head1 NAME

mro::EVERY - EVERY & EVERY::LAST pseudo-packages using mro.

=head1 SYNOPSIS

    # EVERY & EVERY::LAST redispatch the named method into
    # all classes in the object/class hierarchy which
    # define the method or have a suitable can() which 
    # returns their AUTOLOAD to handdle the method.

    # one common use: initialization in construction.
    #
    # construct an object then dispatch the 'initialize'
    # method into any derived classes  least-to-most derived
    # that declare their own 'initialize' method.
    #
    # derived classes don't have to re-dispatch the method,
    # they just handle the object and argumets on their own.
    #
    # Note: not finding that  $object->can( $method )
    # raises an exception. generic base classes should
    # provide a stub if it's reasonable that none of the
    # derived classes hande the method.

    package MyBase;
    use mro qw( c3 );
    use mro::EVERY;

    sub construct
    {
        my $proto   = shift;
        my $class   =

        bless \( my $a = '' ), blessed $proto || $proto
    }

    sub new
    {
        my $object  = &construct;

        $object->EVERY::LAST::initialize( @_ );
        $object
    }

    # notice the lack of a daisy-chain call in the 
    # initialize. each initialize defined up the 
    # stack is called once.

    sub initialize{};

    # another common use: cleanup in destruction.

    # tear down an object from the top down, calling
    # 'cleanup' for most-to-least derived classes.

    package Thingy;
    use mro qw( dfs );
    use mro::EVERY;

    DESTROY
    {
        my $object  = shift;

        $object->EVERY::cleanup;
    }

    # again, notice the lack of a daisy-chain.

    sub cleanup {}

    # Dispatching to AUTOLOAD that can.

    # the "autoload" switch turns on scanning for
    # $proto->can( $name ) and checking for AUTOLOAD
    # subs (vs. simply checking for a defined coderef
    # in the package).
    #
    # using this approach requires properly overloading
    # can() in the package.
    #
    # note that AUTOLOAD's can have all sorts of side
    # effects, this should be used with care and where
    # the handling classes really do have overloaded
    # "can" methods and really do handle the named
    # operation properly.
    #
    # lacking an overloaded can() and appropriate
    # AUTOLOAD, this is a waste.
    #
    # nu, don't say I didn't warn you.

    package RocketEngine;
    use mro qw( c3 );
    use parent qw( Fuel Base );

    use mro::EVERY  qw( autoload );

    sub ignite
    {
        my $obj = shift;

        $obj->EVERY::bottle( 'open' );
        $obj->EVERY::oxydize;
    }

    package Base;
    use mro qw( c3 );

    # EVERY ends up here via parent 'Base'.
    #
    # can has to return something for every method
    # the class can handle -- including UNIVERSAL
    # and any other base classes. this is a trivial
    # example that works because there are no other
    # bases classes other than UNIVERSAL here.

    my %can =
    (
        oxydize => \&AUTOLOAD
    );

    sub can
    {
        $_[0]->UNIVERSAL::can( $_[1] )
        or
        %can{ $_[1] }
    }

    sub bottle
    {
        # not autoloaded, found via 
        # UNIVERSAL::can.

        ...
    }

    our $AUTOLOAD   = '';
    AUTOLOD
    {
        # call ends up here becuase mro::EVERY can
        # find that $pkg->can( 'oxydize' ) and
        # also that there is an AUTOLOAD defined
        # in the package (not just inherited).

        my $name    = ( split '::', $AUTOLOAD )[-1];

        if( 'oxydize' eq $name )
        {
            say 'Burn, baby, burn!'
        }
    }

    # some very, very old code may depend on using depth
    # first searches. This switch turns on dfs for calls
    # to mro::EVERY & mro::EVERY::LAST from the Frobnicate 
    # package only.
    #
    # Note that other packages using either pseudo-class
    # will still get whatever mro they have declared and 
    # will search Frobnicate using whatever mro they define.

    package Frobnicte;
    use mro::EVERY qw( dfs );

=head1 DESCRIPTION

The use of both pseudo-classes is re-dispatching an arbitrary
method up or down the inheritence stack without each class in the
hierarchy having to do its own re-dispatch to another. One common
use of this is in initializers, which can use EVERY::LAST to walk
the tree from least-to-most derived classes calling the method where
it is declared in each class (vs. simply inherited). This works
nicely for base class destructors also using EVERY to tear down the
object from most-to-least derived layers.

An initial sanity check of '$object->can( $method )' to ensure that
something in the hierarchy claims to handle the call. If not an
exception is raised. Inherited methods are also skipped to avoid
duplicate dispatches into the same method with the same object.
For installed methods a unique check for the returned coderefs
also helps avoid duplicate dispatches.

Without autoloading this is quite simple: Walk down the list from
mro::get_linear_isa looking for packages the method name in their
pacakge as CODE.  The unique list of subrefs is dispatced in
order for EVERY and in reverse for EVERY::LAST. This is pretty much
the same guts as NEXT, just using mro for the package names rather
than iterating on @ISA.

One final step after finding the declared (vs. inherited) methods
is applying uniq() to get a distinct list. This is important in
not re-dispatching the same method mulitple times up or down the
stack. In the case of EVERY this finds a unique list of most-
derived methods avilable; EVERY::LAST finds the least-derived
going up the stack from base to derived classes.

Autoload requires a bit more work, and co-operation from the classes
in overloading can() to return true for methods handled by the
AUTOLOAD. In some cases it's trivial: return true for anything.
If the AUTOLOAD only handles some cases then can() needs to return
the correct ones. The AUTOLOAD also has to exist in the classes
package space (vs. being inherited).

=head1 SEE ALSO

=over 4

=item mro

This describes the use of "dfs" & "c3" methologies for
resolving class inheritence order. This module is agnostic,
relying on mro::get_linea_isa which handles them properly.

=item NEXT

Further description EVERY & EVERY::LAST.

The NEXT uses its own DFS inheritence search and is not compatible
with mro. If you don't require 5.8 compatibility then this module
and mro's next::method and maybe::next::method along with this one
will be a reasonable substitute.

If you are dealing with existing code that uses NEXT then this may
provide different result for any classes using mro( c3 ).

=back
