on $_ => sub {
    requires 'Devel::CheckLib';
} for qw(configure build);
# these are configure deps, but cpanm has a hard time picking them up

on runtime => sub {
    requires 'namespace::autoclean', '0.16';
    requires 'AnyEvent';
    requires 'Carp';
    requires 'Module::Runtime';
    requires 'Moo';
    requires 'Scope::Guard';
    requires 'Throwable';
    requires 'XSLoader';
};

on test => sub {
    requires 'namespace::clean';
    requires 'AnyEvent::Future';
    requires 'Storable';
    requires 'Test::Class::Moose', '0.55';
    requires 'Test::LeakTrace';
    requires 'Test::More';
    requires 'Try::Tiny';
};

on develop => sub {
    requires 'Digest::SHA';
    requires 'FindBin::libs';
    requires 'Module::Install::CPANfile';
    requires 'Module::Install::ExtraTests';
    requires 'Module::Install::ReadmePodFromPod';
    requires 'Module::Install::XSUtil';
    requires 'Test::Fatal';
    requires 'Test::Pod';
    requires 'Test::Strict';
};

feature 'async-interrupt', 'Async::Interrupt support' => sub {
    requires 'Async::Interrupt';
};

feature 'io-async', 'IO::Async support' => sub {
    requires 'IO::Async::Handle';
};

feature 'mojo', 'Mojolicious support' => sub {
    requires 'Mojolicious';
    requires 'Future::Mojo';
};

feature 'poe', 'POE support' => sub {
    requires 'POE';
    requires 'POE::Future';
};
