requires 'perl', '5.008001';

requires 'Moo';
requires 'JSON';
requires 'REST::Client';
requires 'Role::REST::Client';
requires 'Data::Serializer';
requires 'Types::Standard';

on 'test' => sub {
    requires 'Devel::Cover';
    requires 'Devel::Cover::Report::Coveralls';
    requires 'Devel::Cover::Report::Codecov';
    requires 'Test::More';
    requires 'Test::Perl::Critic';
    requires 'Test::Pod';
    requires 'Test::Pod::Coverage';
    requires 'Pod::Coverage::TrustPod';
};

on 'develop' => sub {
    requires 'App::CISetup';
    requires 'App::Software::License';
    requires 'Minilla';
    recommends 'Devel::NYTProf';
};
