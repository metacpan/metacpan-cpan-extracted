requires 'perl', '5.008001';

requires 'Moo';
requires 'JSON';
requires 'REST::Client';
requires 'Role::REST::Client';
requires 'Data::Serializer';
requires 'Types::Standard';

on 'test' => sub {
    requires 'Test::More';
    requires 'Test::Perl::Critic';
    requires 'Perl::Critic::Policy::TestingAndDebugging::RequirePackageStricture';
    requires 'Perl::Critic::Policy::TestingAndDebugging::RequirePackageWarnings';
    requires 'Minilla';
};

on 'develop' => sub {
    requires 'Minilla';
    recommends 'Devel::NYTProf';
};
