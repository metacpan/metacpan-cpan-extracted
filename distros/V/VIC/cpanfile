requires 'Capture::Tiny';
requires 'File::ShareDir', '1.00';
requires 'File::Spec';
requires 'File::Which';
requires 'Getopt::Long';
requires 'List::MoreUtils';
requires 'List::Util';
requires 'Moo', '1.003';
requires 'Pegex', '0.75';
requires 'namespace::clean';
requires 'perl', 'v5.14.0';
recommends 'Alien::gputils', '0.07';
recommends 'App::Prove';
recommends 'XXX';

on configure => sub {
    requires 'ExtUtils::MakeMaker', '6.64';
};

on build => sub {
    requires 'File::Spec';
    requires 'File::Which';
    requires 'Module::Build';
    requires 'Pegex', '0.75';
    requires 'Test::More';
    requires 'Test::Lib';
    requires 'B::Hooks::EndOfScope';
};

on develop => sub {
    requires 'Test::CPAN::Meta';
    requires 'Test::MinimumVersion::Fast', '0.04';
    requires 'Test::PAUSE::Permissions', '0.04';
    requires 'Test::Pod', '1.41';
    requires 'Test::Spellunker', 'v0.2.7';
    requires 'Module::BumpVersion';
    requires 'Software::License';
};
