requires 'perl',                  '5.008006';
requires 'PPI',                   '1.215';
requires 'Test::Builder::Module', '0.98';
requires 'Sub::Identify',         0;
requires 'Module::Load',          0;
requires 'Exporter',              0;
requires 'parent',                0;
requires 'Carp',                  0;
requires 'ExtUtils::Manifest',    0;
recommends 'Compiler::Lexer',     '0.13';

on 'test' => sub {
    requires 'Test::Builder::Tester', '1.22';
    requires 'Test::More',            '0.98';
    requires 'FindBin',               0;
};

on 'configure' => sub {
    requires 'CPAN::Meta',          0;
    requires 'CPAN::Meta::Prereqs', 0;
    requires 'Module::Build',       0;
};

on develop => sub {
    requires 'Test::Perl::Critic', 0;
};
