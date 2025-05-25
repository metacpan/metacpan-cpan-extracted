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

sub foo :lvalue
{
    rreturn 23;
    return;
}

sub bar :lvalue
{
    lnoreturn;
    return;
}

{
    local $@;
    eval{ foo() = 7 };
    like( $@, qr/Can't rreturn in lvalue context/, 'no rreturn in lvalue context' );
}

{
    local $@;
    eval{ bar() };
    like( $@, qr/Can't lnoreturn except in ASSIGN context/, 'no lnoreturn outside of ASSIGN context' );
}

# NOTE: address the Want bug report No 4628: Segfault in Set::Array (Dec 10, 2003) <https://rt.cpan.org/Ticket/Display.html?id=4628>
{
    local $@;
    eval
    {
        my $set1 = SetArrayTest->new( qw( abc def ghi jkl mno ) );
        my $set2 = SetArrayTest->new( qw( def jkl pqr ) );
        my @set3 = $set1 - $set2;
    };
    if( $@ )
    {
        fail( "Unexpected error in overloaded operator context: $@" );
    }
    else
    {
        pass( "No segfault in overloaded operator context; returns undef" );
    }
}

# NOTE: address the Want issue No 68350: Segfault in Overloaded Operator '>' (May 20, 2011)

{
    my $rv;
    local $@;
    eval
    {
        my $o = bless( \my $x, 'OverloadTest' );
        # print +($o > 4), "\n";
        my $rv = +($o > 4);

        # Hide it from CPAN
        package
            OverloadTest;
        use overload '>' => \&gt;
        use Test::More;
        use Wanted;
        sub gt
        {
            my $bool = Wanted::want('BOOL');
            if( $bool )
            {
                return(1);
            }
        }
    };
    if( $@ )
    {
        fail( "Unexpected error in overloaded operator context: $@" );
    }
    else
    {
        is( $rv, undef, "No segfault in overloaded operator context; returns undef" );
    }
}

done_testing();

# NOTE: test package SetArrayTest
# Hide it from CPAN
package
    SetArrayTest;
use Wanted;
use overload '-' => sub
{
    my( $self, $other ) = @_;
    want('SCALAR'); # This caused the segfault in Want
    return( $self );
};

sub new
{
    my( $class, @items ) = @_;
    bless( [@items], $class );
}

__END__
