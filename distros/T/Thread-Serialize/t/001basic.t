BEGIN {                                # Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use strict;
use warnings;

my %Loaded;
BEGIN {
     $Loaded{threads}= eval "use threads; 1";
     $Loaded{forks}=   eval "use forks; 1" if !$Loaded{threads};
}

use Thread::Serialize; # can't fake bare import call yet with Test::More
use Test::More;

diag "threads loaded" if $Loaded{threads};
diag "forks loaded"   if $Loaded{forks};
ok( $Loaded{threads} || $Loaded{forks}, "thread-like module loaded" );

my $class= 'Thread::Serialize';
can_ok( $class, qw( freeze thaw ) );
ok( !defined( $Thread::Serialize::no_external_perl ),
 "Check flag being unset" );

test();

delete $INC{'Thread/Serialize.pm'};
$Thread::Serialize::no_external_perl = 1;
{
    local $SIG{__WARN__}= sub {};  # don't want to see warnings ever
    require Thread::Serialize;
}
is( $Thread::Serialize::no_external_perl,'Signature obtained locally',
 "Check flag being set and changed" );

test();

done_testing( 3 + 6 + 1 + 6 );

#-------------------------------------------------------------------------------
# Good for 6 tests

sub test {
    my $scalar= '1234';
    my $frozen= freeze($scalar);
    is( thaw($frozen), $scalar,                       'check contents' );

    my @array= qw(a b c);
    $frozen= freeze(@array);
    is( join( '', thaw($frozen) ), join( '',@array ), 'check contents' );

    $frozen= freeze( \@array );
    is( join( '', @{ thaw($frozen) } ), join( '', @array ), 'check contents' );

    $frozen= freeze();
    is( join( '', thaw($frozen) ), '',                'check contents' );

    $frozen= freeze(undef);
    ok( !defined( thaw($frozen) ),                    'check contents' );

    my %hash= ( a => 'A', b => 'B', c => 'C' );
    $frozen= freeze( \%hash );
    is( join( '', sort %{ thaw($frozen) } ), join( '', sort %hash ),
      'check contents' );
} #test
#-------------------------------------------------------------------------------
