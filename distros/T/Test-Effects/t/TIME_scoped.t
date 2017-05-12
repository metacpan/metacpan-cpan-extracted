use Test::Effects;

plan tests => 4;

effects_ok {
    sleep 1;
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
=> 'Not in scope';

{
    use Test::Effects::TIME;

    effects_ok {
        sleep 1;
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
    => 'In scope';

    no Test::Effects::TIME;

    effects_ok {
        sleep 1;
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
    => 'In scope (after no)';

}

effects_ok {
    sleep 1;
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
=> 'Back out of scope';

done_testing();
