BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 16;

use Thread::Serialize; # can't fake bare import call yet with Test::More
use_ok( 'Thread::Serialize' );
can_ok( 'Thread::Serialize',qw(
 freeze
 thaw
) );
ok( !defined( $Thread::Serialize::no_external_perl ),
 "Check flag being unset" );

test();

delete $INC{'Thread/Serialize.pm'};
$Thread::Serialize::no_external_perl = 1;
require Thread::Serialize;
is( $Thread::Serialize::no_external_perl,'Signature obtained locally',
 "Check flag being set and changed" );

test();

sub test {
    my $scalar = '1234';
    my $frozen = freeze( $scalar );
    is( thaw($frozen),$scalar,			'check contents' );

    my @array = qw(a b c);
    $frozen = freeze( @array );
    is( join('',thaw($frozen)),join('',@array),	'check contents' );

    $frozen = freeze( \@array );
    is( join('',@{thaw($frozen)}),join('',@array),	'check contents' );

    $frozen = freeze();
    is( join('',thaw($frozen)),'',			'check contents' );

    $frozen = freeze( undef );
    ok( !defined( thaw($frozen) ),			'check contents' );

    my %hash = (a => 'A', b => 'B', c => 'C');
    $frozen = freeze( \%hash );
    is( join('',sort %{thaw($frozen)}),join('',sort %hash),'check contents' );
} #test
