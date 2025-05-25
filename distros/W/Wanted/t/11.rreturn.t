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
        Wanted->import( qw( rreturn ) );
    };
    ok( !$@, 'use Wanted' );
    if( $@ )
    {
        BAIL_OUT( "Unable to load Wanted" );
    }
};

use strict;
use warnings;

sub t :lvalue
{
    my( $r ) = @_;
    ok( !Wanted::want_lvalue(0), "want_lvalue(0) -> false" );
    rreturn( $r );
    die( "This shouldn't happen" );
    return;
}

my( $x, @x );

$x = t( 19 );
if( !is( $x, 19, "\$x -> 19" ) )
{
    diag( "\$x = '$x'" );
}

@x = t( 1..3 );
if( !is( scalar( @x ), 1, "\@x -> 1 element (rreturn limitation in Wanted)" ) )
{
    diag( "Number of elements: '", scalar( @x ), "', values: [", join(", ", @x), "]" );
}
is( $x[0], 1, "\$x[0] -> 1 (rreturn limitation in Wanted)" );

TODO:
{
    # skip "want_lvalue(1) not detecting lvalue context", 1;
    local $TODO = "Perl does not propagate lvalue context into eval blocks (CxLVAL not set)";
    local $@;
    eval{ t() = 23 };
    if( $@ )
    {
        pass( "rreturn dies (cannot rreturn in lvalue context)" );
    }
    else
    {
        fail( "rreturn dies (cannot rreturn in lvalue context)" );
    }
}

sub t2 :lvalue
{
    my( $r ) = @_;
    ok( !Wanted::want_lvalue(0), "want_lvalue(0) -> false" );
    rreturn( $r );
    die( "This shouldn't happen" );
    return;
}

$x = t2( 19 );
if( !is( $x, 19, "\$x -> 19" ) )
{
    diag( "\$x = '$x'" );
}

@x = t2( 1..3 );
if( !is( scalar( @x ), 1, "\@x -> 1 element (rreturn limitation in Wanted)" ) )
{
    diag( "Number of elements: '", scalar( @x ), "', values: [", join(", ", @x), "]" );
}
is( $x[0], 1, "\$x[0] -> 1 (rreturn limitation in Wanted)" );

TODO:
{
    # skip "want_lvalue(1) not detecting lvalue context", 1;
    local $TODO = "Perl does not propagate lvalue context into eval blocks (CxLVAL not set)";
    local $@;
    eval{ t2() = 23 };
    if( $@ )
    {
        pass( "rreturn dies (cannot rreturn in lvalue context)" );
    }
    else
    {
        fail( "rreturn dies (cannot rreturn in lvalue context)" );
    }
}

sub t3 :lvalue
{
    ok( !Wanted::want_lvalue(0), "want_lvalue(0) -> false" );
    $x;
}

$x = 42;
{
    local $@;
    eval{ $x = t3() };
    if( $@ )
    {
        fail( "t3 should not die (behavior changed in modern Perl)" );
    }
    else
    {
        pass( "t3 should not die (behavior changed in modern Perl)" );
    }
}
is( $x, 42, "\$x -> 42 (unchanged)" );

done_testing();

__END__
