requires 'Pod::Simple::Methody';
requires 'PPI::Tokenizer';
requires 'Test::Builder::Module';
requires 'Test::More', '0.98';
requires 'parent';
requires 'perl', '5.008005';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
};

on test => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Builder::Tester';
};

on develop => sub {
    requires 'Test::LocalFunctions';
    requires 'Test::Perl::Critic';
    requires 'Test::UsedModules';
    requires 'Test::Vars';
};
