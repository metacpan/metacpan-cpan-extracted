requires 'perl', '5.008005';
requires 'strict';
requires 'warnings';
requires 'utf8';
requires 'overload';
requires 'Carp';
requires 'List::Util';

on 'test' => sub {
    requires 'Test::More', '0.88';
};

on 'configure' => sub {
    requires 'Module::Build';
    requires 'Module::Build::Pluggable';
    requires 'Module::Build::Pluggable::CPANfile';
};

on 'develop' => sub {
    recommends 'Test::Perl::Critic';
    recommends 'Test::Pod::Coverage';
    recommends 'Test::Pod';
    recommends 'Test::NoTabs';
    recommends 'Test::Perl::Metrics::Lite';
    recommends 'Test::Vars';
};
