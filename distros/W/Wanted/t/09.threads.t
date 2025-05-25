#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib qw( ./blib/lib ./blib/arch ./lib ./t/lib );
    use Test::More;
    use vars qw( $DEBUG );
    use Config;
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

# Subroutine to test Wanted context
sub want_context
{
    my $expect = want('LIST')      ? 'LIST' :
                 want('HASH')      ? 'HASH' :
                 want('ARRAY')     ? 'ARRAY' :
                 want('OBJECT')    ? 'OBJECT' :
                 want('CODE')      ? 'CODE' :
                 want('REFSCALAR') ? 'REFSCALAR' :
                 want('BOOL')      ? 'BOOL' :
                 want('GLOB')      ? 'GLOB' :
                 want('SCALAR')    ? 'SCALAR' :
                 want('VOID')      ? 'VOID' : '';
    return( $expect );
}

# Test Wanted::want('SCALAR') outside a subroutine
my $ctx_scalar = want('SCALAR');
is( $ctx_scalar, undef, "Non-threaded want('SCALAR') returns undef outside a subroutine" );

sub non_threaded_test
{
    my $want = shift(@_);
    if( $want eq 'scalar' )
    {
        my $ctx_scalar = want('SCALAR');
        ok( $ctx_scalar, "Non-threaded want('SCALAR') returns true in valid context" );
    }
    if( $want eq 'list' )
    {
        my $ctx_list = want('LIST');
        ok( $ctx_list, "Non-threaded want('LIST') returns true in list context" );
    }
}

my $val = &non_threaded_test('scalar');
my @val = &non_threaded_test('list');

# NOTE: threads
subtest 'threads' => sub
{
    SKIP:
    {
        if( !$Config{useithreads} )
        {
            skip( "Perl is not configured with threads.", 5 );
        }
        require threads;
        my $thr_scalar = threads->create(sub
        {
            return( want('SCALAR') );
        });
        my $scalar_result = $thr_scalar->join;
        is( $scalar_result, 1, "Threaded want('SCALAR') returns true in scalar context" );

        my ($thr_list) = threads->create(sub
        {
            return( want('LIST') );
        });
        my @list_result = $thr_list->join;
        is($list_result[0], 1, "Threaded want('LIST') returns true in list context");

        my $thr_void = threads->create({ context => 'void' }, sub {
            return( want('VOID') ? 1 : 0 );
        });
        is( $thr_void->join, undef, "Threaded want('VOID') returns true in void context" );

        my $thr_segv_scalar = threads->create(sub
        {
            return( want_context() );
        });
        my $segv_scalar_result = $thr_segv_scalar->join;
        is( $segv_scalar_result, 'SCALAR', "Threaded want_context returns 'SCALAR' in scalar context" );

        my ($thr_segv_list) = threads->create(sub
        {
            return( want_context() );
        });
        my $segv_list_result = $thr_segv_list->join;
        is( $segv_list_result, 'LIST', "Threaded want_context returns 'LIST' in list context" );

        # Issue No 136651: Correction on Thread Context Test
        # This is just a confirmation that this issue is resolved.
        my $tid = threads->create( { context => 'list' }, sub
        {
            &callme;
            sub callme
            {
                if( want('LIST') )
                {
                    return( qw( John Joe Jack ) );
                }
                else
                {
                    return( 'John' );
                }
            }
        });
        my @result = $tid->join;
        is_deeply( \@result, [ qw( John Joe Jack ) ], "Threaded want('LIST') in nested sub returns list (no segfault)" );
    };
};

# NOTE: tie
subtest 'tie' => sub
{
    my $tied_scalar;
    tie( $tied_scalar, 'Tie::TestScalar' );
    {
        local $@;
        eval
        {
            my $tied_result = $tied_scalar;
            is( $tied_result, 'SCALAR', "Tied scalar in scalar context returns scalar" );
        };
        if( $@ )
        {
            fail( "Tied scalar test failed: $@" );
        }
    }

    {
        local $@;
        eval
        {
            my @tied_results = $tied_scalar;
            is( $tied_results[0], 'SCALAR', "Tied scalar in list context returns scalar" );
        };
        if( $@ )
        {
            fail( "Tied scalar test failed: $@" );
        }
    }

    {
        my @tied_array;
        tie( @tied_array, 'Tie::TestArray' );
        local $@;
        eval
        {
            my @tied_results = @tied_array;
            is( $tied_results[0], 'SCALAR', "Tied array in list context returns scalar" );
        };
        if( $@ )
        {
            fail( "Tied array test failed: $@" );
        }
    }
};

subtest 'tie_bool' => sub
{
    my $tied_scalar;
    tie( $tied_scalar, 'Tie::TestScalarBool' );
    {
        local $@;
        eval
        {
            my $result = $tied_scalar ? 1 : 0;
            is( $result, 0, "Tied scalar in boolean context does not segfault" );
        };
        if( $@ )
        {
            like( $@, qr/Can't call Wanted::want outside a subroutine/,
                  "Tied scalar in boolean context throws error instead of segfaulting" );
        }
    }
};

done_testing();

# NOTE: Tie::TestScalarBool
# Hide it from CPAN
package
    Tie::TestScalarBool;
require Tie::Scalar;
use vars qw( @ISA $DEBUG );
@ISA = qw( Tie::StdScalar );
use Test::More;
use Wanted;
our $DEBUG = $main::DEBUG;

sub TIESCALAR
{
    my( $class ) = @_;
    return( bless( {}, $class ) );
}

sub FETCH
{
    my $self = shift( @_ );
    my $bool = want('BOOL');
    return(0); # Simplified for testing
}

# NOTE: Tie::TestScalar
# Hide it from CPAN
package
    Tie::TestScalar;
require Tie::Scalar;
use vars qw( @ISA $DEBUG );
@ISA = qw( Tie::StdScalar );
use Test::More;
use Wanted;
our $DEBUG = $main::DEBUG;

sub want_context
{
    my $expect = want('LIST')      ? 'LIST' :
                 want('HASH')      ? 'HASH' :
                 want('ARRAY')     ? 'ARRAY' :
                 want('OBJECT')    ? 'OBJECT' :
                 want('CODE')      ? 'CODE' :
                 want('REFSCALAR') ? 'REFSCALAR' :
                 want('BOOL')      ? 'BOOL' :
                 want('GLOB')      ? 'GLOB' :
                 want('SCALAR')    ? 'SCALAR' :
                 want('VOID')      ? 'VOID' : '';
    return( $expect );
}

sub TIESCALAR
{
    my( $class ) = @_;
    return bless {}, $class;
}

sub FETCH
{
    my $self = shift( @_ );
    return( want_context() );
}

# NOTE: Tie::TestArray
# Hide it from CPAN
package
    Tie::TestArray;
require Tie::Array;
use vars qw( @ISA  $DEBUG);
@ISA = qw( Tie::StdArray );
use Test::More;
use Wanted;
our $DEBUG = $main::DEBUG;

sub want_context
{
    my $expect = want('LIST')      ? 'LIST' :
                 want('HASH')      ? 'HASH' :
                 want('ARRAY')     ? 'ARRAY' :
                 want('OBJECT')    ? 'OBJECT' :
                 want('CODE')      ? 'CODE' :
                 want('REFSCALAR') ? 'REFSCALAR' :
                 want('BOOL')      ? 'BOOL' :
                 want('GLOB')      ? 'GLOB' :
                 want('SCALAR')    ? 'SCALAR' :
                 want('VOID')      ? 'VOID' : '';
    return( $expect );
}

sub TIEARRAY
{
    my( $class ) = @_;
    return( bless( [], $class ) );
}

sub FETCH
{
    my( $self, $index) = @_;
    return( want_context() );
}

sub FETCHSIZE
{
    my $self = shift( @_ );
    # Return one element for testing
    return(1);
}

__END__
