########################################################################
# housekeeping
########################################################################

package mro::EVERY v0.1.4;
use v5.24;
use mro;

use Carp            qw( croak           );
use List::Util      qw( uniq            );
use Scalar::Util    qw( blessed         );
use Symbol          qw( qualify_to_ref  );

########################################################################
# package varaibles
########################################################################

our @CARP_NOT   = ( __PACKAGE__, qw( mro ) );
my $find_subs   = '';
my $with_auto   = '';

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

    # if they handle this via AUTOLOAD then we have 
    # problem at this point, see find_with_autoload.
    #
    # if the dispatching class has no ancestors then 
    # treat it as its own ancestor.
    
    local $"    = ',';
    my @isa     = $class->mro::get_linear_isa->@*;

    # uniq avoids case of multiple-dispatch of 
    # hardwired inherited methods at multiple 
    # places in the tree. 

    my @found
    = uniq
    grep
    {
        $_
    }
    map
    {
        *{ qualify_to_ref $name => $_ }{ CODE }
    }
    @isa
    or
    croak "Bogus $proto: '$name' not in @isa";

    @found
};

my $find_with_autoload
= sub
{
    my $proto   = shift;
    my $auto    = shift;
    my ($name)  = $auto =~ m{ (\w+) $}x;

    $proto->can( $name )
    or croak "Botched EVERY: '$proto' cannot '$name'";
 
    local $"    = ',';
    my @isa     = $proto->mro::get_linear_isa->@*;

    # uniq avoids multiple-dispatch in case where
    # AUTOLOAD handling $name is inherited.

    my @found
    = uniq
    grep
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

sub import
{
    shift;  # discard this package

    for( @_ )
    {
        m{^   autoload $}x and $with_auto = 1;
        m{^ noautoload $}x and $with_auto = '';
    }

    $find_subs
    = $with_auto
    ? $find_with_autoload
    : $find_name
    ;

    return
}

########################################################################
# pseudo-packages
########################################################################

package EVERY;
use v5.22;
use Carp    qw( croak );

our @CARP_NOT   = ( __PACKAGE__, qw( mro ) );
our $AUTOLOAD   = '';

AUTOLOAD
{
    my $proto   = shift
    or croak "Bogus EVERY, called without an object.";

    # remaining arguments left on the stack.

    $proto->$_( @_ )
    for $proto->$find_subs( $AUTOLOAD );
}

package EVERY::LAST;
use v5.22;
use Carp    qw( croak );

our @CARP_NOT   = ( __PACKAGE__, qw( mro ) );
our $AUTOLOAD   = '';

AUTOLOAD
{
    my $proto   = shift
    or croak "Bogus EVERY::LAST, called without an object.";

    # remaining arguments left on the stack.

    $proto->$_( @_ )
    for reverse $proto->$find_subs( $AUTOLOAD );
}

# keep require happy
1
__END__

=head1 NAME

mro::EVERY - EVERY & EVERY::LAST pseudo-packages using mro. 

=head1 SYNOPSIS

    # EVERY & EVERY::LAST redispatch the named method into
    # all classes in the object/class hierarchy which 
    # implement the method or have a suitable can() and 
    # AUTOLOAD to handdle the method.


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
        oxydize     => \&AUTOLOAD
      , AUTOLOAD    => \&AUTOLOAD
      , bottle      => \&bottle
    );

    sub can
    {
        %can{ $_[1] }
        or
        UNIVERSAL->can( $_[1] )
    }

    sub bottle
    {
        # autoloaded or not, this has to be 
        # handled by can(), above.

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

=head1 DESCRIPTION

The main use of both pseudo-classes is re-dispatching an arbitrary 
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
mro::get_linear_isa looking for packages that define their own code
for the method name. The resulting list of subrefs is dispatced in
order for EVERY and in reverse for EVERY::LAST. This is pretty much
the same guts as NEXT, just using mro for the package names rather
than iterating on @ISA. 

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
