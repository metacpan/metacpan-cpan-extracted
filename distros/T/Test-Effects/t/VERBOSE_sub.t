use Test::Effects;

plan tests => 1;

effects_ok {
    print 'stdout';
    say {*STDERR} 'stderr';
    warn  'warning';
    die   'died';
}
VERBOSE {
    stdout => "stdout",
    stderr => qr{stderr\nwarning \s+ at}x,
    warn   => [qr{\A warning \s+ at}x],
    die    => qr{\A died \s+ at}x,
}
=> 'VERBOSE works';


