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

sub method
{
	my( undef, $expected ) = @_;
    my @ctx;
    for my $test ( qw( VOID SCALAR REF REFSCALAR CODE HASH ARRAY GLOB OBJECT BOOL LIST
                       Infinity LVALUE ASSIGN RVALUE ) )
	{
	    push( @ctx, $test ) if( Wanted::want( $test ) );
    }

    is( "@ctx", $expected );
	return( want("ARRAY") ? [] : want("HASH") ? {} : 1 );
}

my $obj = bless( {} );
$obj->method( 'VOID RVALUE' );

my @b = @{$obj->method( 'SCALAR REF ARRAY RVALUE' )};
my %b = %{$obj->method( 'SCALAR REF HASH RVALUE' )};

done_testing();

__END__
