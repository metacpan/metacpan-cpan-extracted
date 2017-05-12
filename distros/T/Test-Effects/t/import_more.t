use Test::Effects tests => 1, import => [':more'];

effects_ok {
    print 'stdout';
    say {*STDERR} 'stderr';
    warn  'warning';
    ok 1;
    VERBOSE({});
}
{
    stdout => "stdout",
    stderr => qr{stderr\nwarning \s+ at}x,
    warn   => [qr{\A warning \s+ at}x],
    die    => qr{\AUndefined subroutine &main::VERBOSE called},
}
=> 'import more works';


