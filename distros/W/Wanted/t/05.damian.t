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

# Test for Damian's loop bug

sub do_something_anything {}
my $ok = 2;
my @answers = (
    1,1,0,0,1,1,0,0,1,1,0,0,
    0,0,1,1,0,0,1,1,0,0,1,1
);

sub okedoke
{
    my( $rv ) = @_;
    is( $rv, shift( @answers ) );
}

my $flipflop = 0;

sub foo
{
	okedoke( want('BOOL') );
	return( $flipflop = !$flipflop ); # alternate true and false
}

for (1..3)
{
	while( foo() )
	{
		do_something_anything;
	}
	while( my $answer = foo() )
	{
		do_something_anything;
	}
}

sub bar
{
	okedoke( want('!BOOL') );
	return( $flipflop = !$flipflop ); # alternate true and false
}

for (1..3)
{
	while( bar() )
	{
		do_something_anything;
	}
	my $answer;
	while( $answer = bar() )
	{
		do_something_anything;
	}
}

is( scalar( @answers ), 0 );

done_testing();

__END__
