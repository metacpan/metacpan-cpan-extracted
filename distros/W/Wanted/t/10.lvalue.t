#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib qw( ./blib/lib ./blib/arch ./lib ./t/lib );
    use Test::More;
    use vars qw( $DEBUG );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    eval
    {
        require Wanted;
        Wanted->import( qw( rreturn lnoreturn ) );
    };
    ok( !$@, 'use Wanted' );
    if( $@ )
    {
        BAIL_OUT( "Unable to load Wanted" );
    }
};

use strict;
use warnings;

# Test rreturn and lnoreturn

sub rreturner :lvalue
{
    my( $r ) = @_;
    rreturn( $r );
    die( "This shouldn't happen" );
    return;
}

sub lnoreturner :lvalue
{
    Wanted::lnoreturn;
    die( "This shouldn't happen" );
    return;
}

my( $x, @x );
$x = rreturner( 19 );
is( $x, 19, "\$x -> 19" );

@x = rreturner( 1..3 );
is( scalar( @x ), 1, "\@x -> 1 element (rreturn limitation in Wanted)" );
is( $x[0], 1, "\$x[0] -> 1 (rreturn limitation in Wanted)" );

lnoreturner() = 23;

$x = 42;
lnoreturner() = undef;
is( $x, 42, "\$x -> 42" );

sub lnoreturner2 :lvalue
{
    my( $r ) = @_;
    Wanted::lnoreturn;
    die( "This shouldn't happen" );
    $r;
}

$x = 99;
lnoreturner2( $x ) = undef;
is( $x, 99, "\$x -> 99" );

# Comment out double_return and double_lreturn tests for debugging
sub double_return :lvalue
{
    Wanted::double_return;
    die( "This shouldn't happen" );
    return;
}

{
    local $@;
    eval{ double_return() };
    if( $@ )
    {
        pass( "double_return dies (cannot return outside a subroutine)" );
    }
    else
    {
        fail( "double_return dies (cannot return outside a subroutine)" );
    }
}

sub double_lreturn :lvalue
{
    Wanted::double_return;
    die( "This shouldn't happen" );
    return;
}

{
    local $@;
    eval{ double_lreturn() = 23 };
    if( $@ )
    {
        pass( "double_lreturn dies (cannot return outside a subroutine)" );
    }
    else
    {
        fail( "double_lreturn dies (cannot return outside a subroutine)" );
    }
}

sub lnoreturner3 :lvalue
{
    Wanted::lnoreturn;
    die( "This shouldn't happen" );
    return;
}

{
    local $@;
    eval{ lnoreturner3() };
    if( $@ )
    {
        pass( "lnoreturner3 dies (must be in ASSIGN context)" );
    }
    else
    {
        fail( "lnoreturner3 dies (must be in ASSIGN context)" );
    }
}

{
    local $@;
    eval { lnoreturner3() = 23 };
    if( $@ )
    {
        fail( "lnoreturner3 should not die (is in ASSIGN context)" );
    }
    else
    {
        pass( "lnoreturner3 should not die (is in ASSIGN context)" );
    }
}

{
    local $@;
    eval { $x = lnoreturner3() };
    if( $@ )
    {
        pass( "lnoreturner3 dies (must be in ASSIGN context)" );
    }
    else
    {
        fail( "lnoreturner3 dies (must be in ASSIGN context)" );
    }
}

done_testing();

__END__
