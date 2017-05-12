requires 'PPI::Document',         '1.215';
requires 'PPI::Dumper',           '1.215';
requires 'Test::Builder::Module', '0.98';
requires 'parent';
requires 'perl', '5.008005';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
};

on test => sub {
    requires 'Test::Builder::Tester', '1.22';
    requires 'Test::More',            '0.98';
    requires 'Module::Load';
};

on develop => sub {
    requires 'Test::LocalFunctions', '0.21';
    requires 'Test::Perl::Critic';
    requires 'Test::Vars';
};
