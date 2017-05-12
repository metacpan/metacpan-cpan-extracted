use strict;
use warnings;
use ExtUtils::MakeMaker;

my %params = (
    NAME => 'Test::UseAllModules',
    VERSION_FROM => 'lib/Test/UseAllModules.pm',
    ABSTRACT_FROM => 'lib/Test/UseAllModules.pm',
    AUTHOR => 'Kenichi Ishigaki <ishigaki@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
        'Exporter'           => 0,
        'ExtUtils::Manifest' => 0,
        'Test::More'         => '0.60',
        'Test::Builder'      => '0.30',
    },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/charsbar/test-useallmodules',
    },
  },
);

my $eumm = eval $ExtUtils::MakeMaker::VERSION;
delete $params{LICENSE}    if $eumm < 6.31;
delete $params{META_MERGE} if $eumm < 6.46;

WriteMakefile(%params);
