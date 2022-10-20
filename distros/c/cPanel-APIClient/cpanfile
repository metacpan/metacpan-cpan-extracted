requires 'parent';
requires 'Call::Context';
requires 'X::Tiny';
requires 'URI::Escape';
requires 'JSON';

on configure => sub {
    requires 'ExtUtils::MakeMaker::CPANfile';
};

on test => sub {
    requires 'autodie';
    requires 'mro';
    requires 'FindBin';
    requires 'Test::Fatal';
    requires 'Test::More';
    requires 'Test::Deep';
    requires 'Test::FailWarnings';
    requires 'Test::Class';

    requires 'Test::MockModule' => '0.170';
    requires 'Promise::ES6' => 0.23;

    recommends 'Net::Curl::Promiser';
    recommends 'AnyEvent';
    recommends 'IO::Async';
    recommends 'IPC::Run';

    # We omit Mojolicious because it requires a newer Perl version
    # than we do.
};
