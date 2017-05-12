use strict;
use warnings;
use Test::More tests => 1;

defined ( my $pid = fork() ) or die "Can not create a child process";

if ($pid != 0) {
    require Win32::MMF::Shareable;

    tie my $s, 'Win32::MMF::Shareable', 'scalar';
    tie my $t, 'Win32::MMF::Shareable', 'sig';

    while (!$t) {};

    is( $s, 'Hello world', 'Multi-process sharedmem OK' );
} else {
    require Win32::MMF::Shareable;

    tie my $s, 'Win32::MMF::Shareable', 'scalar';
    tie my $t, 'Win32::MMF::Shareable', 'sig';

    $s = 'Hello world';
    $t = 1;

    select undef, undef, undef, 0.5;

    exit(0);
}

