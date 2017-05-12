use strict;
use warnings;
use Test::More tests => 14;

BEGIN {
    use_ok( 'Win32::MMF::Shareable' );
}

isa_ok( my $ns = tie(my $s, 'Win32::MMF::Shareable', 'scalar'), 'Win32::MMF::Shareable', 'Tie OK - Scalar' );
isa_ok( tie(my @s, 'Win32::MMF::Shareable', 'list'), 'Win32::MMF::Shareable', 'Tie OK - List' );
isa_ok( tie(my @t, 'Win32::MMF::Shareable', 'list'), 'Win32::MMF::Shareable', 'Tie OK - List 2' );
isa_ok( tie(my %s, 'Win32::MMF::Shareable', 'hash'), 'Win32::MMF::Shareable', 'Tie OK - Hash' );

$s = 'Hello world';
is( $s, 'Hello world', 'Tied Scalar store/fetch OK' );

$s = undef;
is( $ns->namespace->findvar('scalar'), '', 'Tie Scalar undef OK' );

push @s, 'Hello world';
is ( pop(@s), 'Hello world', 'Tied List push/pop OK' );

@s = ();
is(@s, 0, 'Tied List clear OK');

@s = qw/ a b c d /;
my @n = @s[1,3];
is ( $n[1], 'd', 'Tied List slice OK' );

is ( $t[1], 'b', 'Tied List byref OK' );

%s = ( a => 1, b => 2, c => 3, d => 4 );
is ( $s{c}, 3, 'Tied Hash store/fetch 1 OK' );

$s{e} = 5;
is ( $s{e}, 5, 'Tied Hash store/fetch 2 OK' );

@s = qw/ a b /;
@s{@s} = qw/ 2 1 /;
ok ( $s{b} == 1 && $s{a} == 2, 'Tied Hash slice OK' ) or die "Tie Hash slice failure";


