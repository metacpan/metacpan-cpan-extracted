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
        Wanted->import();
    };
    ok( !$@, 'use Wanted' );
    if( $@ )
    {
        BAIL_OUT( "Unable to load Wanted" );
    }
};

use strict;
use warnings;

sub foo :lvalue
{
    my $w = shift( @_ );
    if( want( qw/LVALUE ASSIGN/ ) )
    {
        my( $a ) = want('ASSIGN');
        is( $a, 23, "want('ASSIGN') -> 23" );
        lnoreturn;
    }
    elsif( $w eq 'list' )
    {
        ok( want('LIST'), 'caller expects a list' );
        rreturn( 1, 2, 3 );
    }
    elsif( $w eq 'bool' )
    {
        ok( want('BOOL'), 'caller expects a boolean' );
        rreturn(0);
    }
    elsif( $w eq 'string' )
    {
        ok( want( qw/SCALAR !REF/ ), 'caller expects a non-ref scalar' );
        rreturn(23);
    }
    return; # You have to put this at the end to keep the compiler happy
}

foo() = 23;

my( $x, @x, %h );

@x = foo( 'list' );

ok( !foo( 'bool' ), "want('BOOL') -> 0" );

$x = foo('string');

done_testing();

__END__
