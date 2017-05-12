use Test::Effects;

plan tests => 4;

effects_ok {
    print 'stdout';
    say {*STDERR} 'stderr';
    warn  'warning';
    die   'died';
}
{
    stdout => "stdout",
    stderr => qr{stderr\nwarning \s+ at}x,
    warn   => [qr{\A warning \s+ at}x],
    die    => qr{\A died \s+ at}x,
}
=> 'Not in scope';

{
    use Test::Effects::VERBOSE;

    effects_ok {
        print 'stdout';
        say {*STDERR} 'stderr';
        warn  'warning';
        die   'died';
    }
    {
        stdout => "stdout",
        stderr => qr{stderr\nwarning \s+ at}x,
        warn   => [qr{\A warning \s+ at}x],
        die    => qr{\A died \s+ at}x,
    }
    => 'In scope';

    no Test::Effects::VERBOSE;

    effects_ok {
        print 'stdout';
        say {*STDERR} 'stderr';
        warn  'warning';
        die   'died';
    }
    {
        stdout => "stdout",
        stderr => qr{stderr\nwarning \s+ at}x,
        warn   => [qr{\A warning \s+ at}x],
        die    => qr{\A died \s+ at}x,
    }
    => 'In scope (after no)';

}

effects_ok {
    print 'stdout';
    say {*STDERR} 'stderr';
    warn  'warning';
    die   'died';
}
{
    stdout => "stdout",
    stderr => qr{stderr\nwarning \s+ at}x,
    warn   => [qr{\A warning \s+ at}x],
    die    => qr{\A died \s+ at}x,
}
=> 'Back out of scope';




