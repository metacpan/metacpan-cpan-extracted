requires 'perl', '5.008005';
requires 'namespace::clean';
requires 'strictures', '2';

requires 'Array::Utils';
requires 'JSON';
requires 'Moo';
requires 'REST::Client';
requires 'Role::REST::Client';
requires 'Types::Standard';

on test => sub {
    requires 'Pod::Coverage::TrustPod';
    requires 'Test::CPAN::Meta';
    requires 'Test::More';
    requires 'Test::Warn';
    requires 'Test::Kwalitee';
    requires 'Test::HasVersion';
    requires 'Test::DistManifest';
    requires 'Test::Pod::Coverage';
};

on 'develop' => sub {
    requires 'App::CISetup';
    requires 'App::Software::License';
    requires 'Dist::Milla';
    recommends 'Devel::NYTProf';
};
