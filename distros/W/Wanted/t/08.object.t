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

# Test the OBJECT reference type

sub t
{
    my $expect = shift( @_ );
    my $opname = Wanted::parent_op_name(0);
    is( $opname, $expect );
    return( wantarray ? @_ : shift( @_ ) );
}

sub nop{}
my $obj = bless( {}, 'main' );

t( 'method_call', $obj )->nop( 'blast' );
t( 'entersub', \&nop )->( 'blamm!' );

sub wrt
{
    my $wantref = Wanted::wantref();
    my $expected = shift( @_ );
    is( $wantref, $expected );
    return( wantarray ? @_ : shift( @_ ) );
}

wrt( 'OBJECT', $obj )->nop();
wrt( 'CODE',  \&nop )->( nop() );

sub wantt
{
    my $r = shift( @_ );
    Wanted::want( @_ ) ? pass() : fail();
    $r
}

wantt( $obj, 'OBJECT' )->nop( wantt( \&nop, 'CODE' )->() );

done_testing();

__END__
