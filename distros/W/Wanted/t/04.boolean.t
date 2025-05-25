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
        Wanted->import;
    };
    ok( !$@, 'use Wanted' );
    if( $@ )
    {
        BAIL_OUT( "Unable to load Wanted" );
    }
};

use warnings;
use strict;

# Check the low-level want_boolean() routine

sub wb
{
    my( $w, $name, $r ) = @_;
    my $a = Wanted::want_boolean(0);
    # 'is' does not work, because want_boolean(0) return '' (empty string), while we expect 0, but using $w == $a, force '' to become 0, and then the test becomes true... Not sure this is really good. Both ends up being false, which is ok for boolean, but it is not the same return value
    # if( !is( $a, $w, "want_boolean(0) -> " . ( $a // 'undef' ) ) )
    if( !ok( $a == $w, ( defined( $name ) ? "$name: " : '' ) . "want_boolean(0) -> '" . ( $a // 'undef' ) . "'" ) )
    {
        diag( "\$a = '", ( $a // 'undef' ), "'" );
    }
    return( $r );
}

# In older (< 0.10) versions of Wanted, want_boolean would return true
# even in void context. That's no longer true.
wb(0, 'void context' );

my( $x, @x );
$x = ( wb(1, 'chaining with &&', 1) && wb(0) );
if( wb(1) ) {}

$x = ( wb(1, 'tenary operation' ) ? 17 : 23);
$x = ( $x ? wb(0, 'tenary operation', 1) : die );

if( $x ? wb(1, 'tenary operation', 1) : die )
{
    pass( "want_boolean(0) -> 1 in tenary operation" );
}
else
{
    fail( "want_boolean(0) -> 1 in tenary operation" );
}

eval{ die unless( wb( 1, 'boolean', 1 ) ) };
if( $@ )
{
    fail( "want_boolean(0) -> 1 (should not die)" );
}
else
{
    pass( "want_boolean(0) -> 1 (should not die)" );
}

if( ( wb( 1, 'boolean', 1 ) && wb( 1, 'boolean', 0 ) ) || wb( 1, 'boolean' ) )
{
    () = $x
}

wb( ( wb( 1, 'embedded chaining && left', 1 ) && wb( 0, 'embedded chaining && right', 0 ) ) || wb( 0, 'boolean', 0 ), 'boolean', 0 );

# Now check that want('BOOL') is okay

sub wantt
{
    my $r = shift( @_ );
    Wanted::want( @_ ) ? pass( "want( @_ )" ) : fail( "want( @_ )" );
    $r
}

 wantt( 0, 'SCALAR', 'BOOL', '!REF' ) ||
!wantt( 0, 'SCALAR', 'BOOL', '!REF' ) || 1;

wantt( 0, '!BOOL' );
$x = wantt( 0, '!BOOL' );
@x = wantt( 0, qw'LIST !BOOL' );

$x = ( wantt( 0, 'BOOL' ) xor wantt( 0, 'BOOL' ) );
$x = !( 0 + wantt( 1, '!BOOL' ) );

done_testing();

__END__
