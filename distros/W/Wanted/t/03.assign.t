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

# Test the ASSIGN context

sub t
{
    my( @params ) = @_;
    ok( want( @params ), "want( @params )" );
}

my $t;
sub tl :lvalue
{
        # Here, 'ok' will make the test 'ASSIGN' to fail, so we need to take a different approach
    # ok( want( @_ ), "want( @_ )" );
    want( @_ ) ? pass( "want( @_ )" ) : fail( "want( @_ )" );
    $t;
}

sub noop {}
sub idl :lvalue {@_[0..$#_]}

t( qw/RVALUE !ASSIGN/ );
tl( qw/RVALUE !ASSIGN/ );
noop( tl( qw/LVALUE !ASSIGN/ ) );
tl( qw/LVALUE ASSIGN/ ) = ();
tl( 'ASSIGN' ) = ();

sub backstr :lvalue
{
    if( want('LVALUE') )
    {
        warn( "Not in ASSIGN context" ) unless( want('ASSIGN') );
        my $a = want('ASSIGN');
        $_[0] = reverse( $a );
        lnoreturn;
    }
    else
    {
        rreturn scalar( reverse( $_[0] ) );
    }
    die; return;
}

my $b = backstr( 'qwerty' );
is( $b, 'ytrewq', 'qwerty -> ytrewq' );
backstr( my $foo ) = 'robin';
is( $foo, 'nibor', 'robin -> nibor' );

# Try with some stuff on the stack
for(1..3)
{
    backstr( $foo ) = 23;
}
is( $foo, 32, "\$foo now is 32" );

idl( tl( 'LVALUE', '!ASSIGN' ) ) = ();

done_testing();

__END__
