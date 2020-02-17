requires 'Best', '0.11';
requires 'Data::Dumper';
requires 'File::Spec';
requires 'Getopt::Long', '2.5';
requires 'Keyword::Declare', '0.001006';
requires 'List::Util::MaybeXS', '1.500002';
requires 'Scalar::Util', '1.39';
requires 'YAML';
requires 'perl', '5.012';
requires 'vars';
recommends 'YAML::XS';

on configure => sub {
    requires 'Config';
    requires 'ExtUtils::MakeMaker';
    requires 'File::Spec';
};

on build => sub {
    requires 'Carp';
    requires 'Exporter';
    requires 'Import::Into';
    requires 'Pod::Markdown';
    requires 'Test::More';
    requires 'parent';
    requires 'rlib';
};

on test => sub {
    requires 'App::Prove';
    requires 'Capture::Tiny';
    requires 'Exporter::Renaming';
    requires 'Test2::Tools::Compare';
    requires 'Test::Fatal';
    requires 'Test::Kit', '2.14';
    requires 'Try::Tiny', '0.07';
    requires 'constant';
    requires 'rlib';
};

on develop => sub {
    requires 'App::RewriteVersion';
    requires 'DateTime';
    requires 'File::Globstar';
    requires 'File::Grep';
    requires 'Module::Metadata', '1.000016';
};
