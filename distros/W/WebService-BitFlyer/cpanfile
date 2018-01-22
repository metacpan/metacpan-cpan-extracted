requires 'perl', '5.008005';
requires 'strict';
requires 'warnings';
requires 'Carp';
requires 'HTTP::Tiny';
requires 'URI::Query';
requires 'Digest::SHA';
requires 'Class::Accessor::Lite';
requires 'JSON';

on 'test' => sub {
    requires 'Test::More', '0.88';
    requires 'Test::AllModules';
};

on 'configure' => sub {
    requires 'Module::Build' , '0.40';
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
