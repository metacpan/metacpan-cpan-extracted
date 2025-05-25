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

# Now test the private low-level mechanisms

my $xxx;
sub lv :lvalue
{
    ok( Wanted::want_lvalue(0), 'want_lvalue(0) returns true in lvalue context' );
    $xxx;
}

&lv = 23;

sub rv :lvalue
{
    ok( !Wanted::want_lvalue(0), 'want_lvalue(0) returns false in rvalue context' );
    my $xxx;
}

&rv;

sub foo
{
    my( $expect, $count, $rv ) = @_;
    my $opname = Wanted::parent_op_name(0);
    is( $opname, $expect, "parent_op_name(0) -> $expect" );
    my $c = Wanted::want_count(0);
    is( $c, $count, "want_count(0) -> $count" );
    $rv;
}

my( $x, @x );
( $x, undef ) = foo( 'aassign', 2 );
$x = 2 + foo( 'add', 1, 7 );

foo( '(none)', 0 );

# GLOB context; will not actually print
print( foo( 'print', -1, '' ) );

@x = foo( 'aassign', -1 );

# Test the public API

#  wantref()
sub wc
{
    my $ref = Wanted::wantref();
    is( $ref, 'CODE', 'wantref() returns "CODE"' );
    sub {}
}
wc()->();
    
sub wg
{
    my $ref = Wanted::wantref();
    is( $ref, 'GLOB', 'wantref() returns "GLOB"' );
    \*foo;
}
$x = *{wg()};
$x = *{wg()}{FORM};

SKIP:
{
    unless( $] >= 5.022000 )
    {
        skip( "Skipping wantref() HASH test on Perl < 5.22.0 (no OP_MULTIDEREF)", 3 );
    }
    sub wh
    {
        my $ref = Wanted::wantref();
        is( $ref, 'HASH', 'wantref() returns "HASH"' );
        {}
    }
    $x = wh()->{foo};
    @x = %{wh()};
    @x = @{wh()}{qw/foo bar/};

    unless( $] >= 5.022000 )
    {
        skip( "Skipping wantref() ARRAY test on Perl < 5.22.0 (no OP_MULTIDEREF)", 2 );
    }
    sub wa
    {
        my $ref = Wanted::wantref();
        is( $ref, 'ARRAY', 'wantref() returns "ARRAY"' );
        [];
    }
    @x = @{wa()};
    wa()->[24] = ${wa()}[23];
};

#  howmany()

sub hm
{
    my $x = shift( @_ );
    my $h = Wanted::howmany();
    if( !ok( ( !defined( $x ) && !defined( $h ) || $x eq $h ), "howmany returns " . ( defined( $h ) ? "$h" : 'undef' ) . " vs " . ( $x // 'undef' ) ) )
    {
        diag( "\$h is '", ( $h // 'undef' ), "'" );
    }
}

hm(0);
@x = hm(undef);
(undef) = hm(1);

#  want()

sub pi ()
{
    if( want('ARRAY') )
    {
        return( [3, 1, 4, 1, 5, 9] );
    }
    elsif( want('LIST') )
    {
        return( ( 3, 1, 4, 1, 5, 9 ) );
    }
    else
    {
        return(3);
    }
}

is( pi->[2], 4, 'want an array' );
is( ((pi)[3]), 1, 'want an array' );

sub tc
{
    ok( ( want(2) && !want(3) ), 'want no more than 2 items' );
}

(undef, undef) = tc();

my $y;
sub g :lvalue
{
    my( @params ) = @_;
    ok( want( @params ), "want( @params )" );
    $y;
}
sub ng :lvalue
{
    my( @params ) = @_;
    ok( !want( @params ), "don't want( @params )" );
    $y;
}

(undef) =  g('LIST', 1);
(undef) = ng('LIST', 2);

$x      =  g('!LIST', 1);
$x      = ng('!LIST', 2);

g('RVALUE', 'VOID');
g('LVALUE', 'SCALAR') = 23;
is( $y, 23, 'lvalue assignment sets variable correctly' );

@x = g('RVALUE', 'LIST');
@x = \(g('LVALUE', 'LIST'));
($x) = \(scalar g($] >= 5.021007 ? ('LVALUE', 'SCALAR') : 'RVALUE'));
# $$x = 29;
# $$x = {};

# NOTE:
# Prior to Perl v5.16.0, taking a reference to the scalar return of an lvalue sub
# (via \(scalar g(...))) and assigning through that reference (i.e. $$x = ...)
# would not consistently modify the actual lvalue variable.
# Perl v5.16.0 and later fixed this by better integrating lvalue sub return values
# with the internal scalar stack. See: perldelta for Perl 5.16.0:
# <https://perldoc.perl.org/5.16.0/perldelta#Lvalue-subroutines>
if( $] >= 5.016000 )
{
    $$x = {};
}
else
{
    g('LVALUE', 'SCALAR') = {};
}

ng('REF') = g('HASH')->{foo};
$y = sub {}; # Just to silence warning
$x = defined( &{g('CODE')} );
sub main::23 {}

(undef, undef,  undef) = ( $x,  g(2) );
(undef, undef,  undef) = ( $x, ng(3) );

( $x ) = ( $x, ng(1) );

@x     = g(2);
my %x  = (1 => g('Infinity'));
@x{@x} = g('Infinity');

@x[1, 2] = g(2, '!3');

%x = ( 1 => 23, 2 => 'seven', 23 => 9, seven => 2);
@x{ @x{1, 2} } = g(2, '!3');
@x{()} = g(0, '!1');

@x = ( @x, g('Infinity') );
( $x ) = ( @x, g('!1') );

# Check the want('COUNT') and want('REF') synonyms

sub tCOUNT
{
    my( $w ) = @_;
    my $a = want('COUNT');
    if( !defined( $w ) and !defined( $a ) )
    {
        pass( "want('COUNT') -> undef" );
    }
    else
    {
        is( $a, $w, "expected count is " . ( $w // 'undef' ) . " vs actual " . ( $a // 'undef' ) );
    }
    return
}

tCOUNT(0);
$x = tCOUNT(1);
(undef, $x) = tCOUNT(2);

sub tREF
{
    my( $w ) = @_;
    my $a = want('REF');
    is( $a, $w, "want('REF') -> " . ( $a // 'undef' ) );
    return( \undef );
}

$x = ${tREF('SCALAR')};

sub not_lvaluable
{
    ok( !want('LVALUE'), 'want("LVALUE") is false' );
}

sub{}->(not_lvaluable());

@x   = tCOUNT(undef);
@::x = tCOUNT(undef);

($x, @x) = tCOUNT(undef);
($x, @::x)  = tCOUNT(undef);

(undef, undef, @x)    = tCOUNT(undef);
(undef, undef, @::x)  = tCOUNT(undef);

(@x, @::x) = tCOUNT(undef);
(@::x, @::x) = tCOUNT(undef);

%x   = tCOUNT(undef);
%::x = tCOUNT(undef);

%x    = ( a => 1, tCOUNT(undef) );
%::x  = ( a => 2, tCOUNT(undef) );

sub try_rreturn : lvalue
{
    rreturn @_;
    return;
}

{
    my $res;

    $res = try_rreturn( qw(a b c) );
    is( $res, 'c', "rreturn in scalar context ($res)" );

    $res = join( ':', try_rreturn( qw(a b c) ) );
    is( $res, 'a:b:c', "rreturn in list context ($res)" );
}

# NOTE: Issue No 16670: Convenience Forms (Dec 21, 2005)
# Test context() with no arguments
sub context_test
{
    my $expected = shift( @_ );
    my $context = Wanted::context();
    is( $context, $expected, "context() returns '$expected' context" );
    return( wantarray ? @_ : shift( @_ ) );
}

context_test('VOID');
$x = context_test('SCALAR');
@x = context_test('LIST');

context_test('BOOL') ? 1 : 0;
context_test('CODE', sub{})->();
$x = context_test('HASH', {})->{hello};
$x = context_test('ARRAY', [])->[0];
$x= *{context_test('GLOB',\*foo)};
$x= *{context_test('GLOB',\*foo)}{FORM};

$x = ${context_test('REFSCALAR', \'hello')};

sub noop{}
my $obj = bless( {}, 'main' );

context_test('OBJECT', $obj)->noop('hello');

# NOTE: Issue No 47963: want() Confused by Prototypes (Jul 17, 2009)
sub ok_proto($)
{
    # Does nothing
}

TODO:
{
    local $TODO = 'want() Confused by Prototypes (issue No 47963)';
    sub baz
    {
        my $is_code = want('CODE');
        ok( !$is_code, "want('CODE') returns false in scalar context with prototype" );
        return( 'CODE' ) if( $is_code );
    }
    ok_proto( baz() );
};

done_testing();

__END__
