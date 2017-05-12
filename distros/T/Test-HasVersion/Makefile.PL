
use ExtUtils::MakeMaker;

my $EUMM_VERSION = eval $ExtUtils::MakeMaker::VERSION;

WriteMakefile(
    NAME         => 'Test::HasVersion',
    VERSION_FROM => 'HasVersion.pm',
    PREREQ_PM    => {
        'Test::Builder'       => 0,
        'ExtUtils::MakeMaker' => 0,
        'File::Find'          => 0,

        # required for testing
        'Test::More'            => 0,
        'Test::Builder::Tester' => 1.04,
        'File::Spec'            => 0,
    },
    EXE_FILES => ['bin/test_version'],

    ($] >= 5.005 ? (
            ABSTRACT_FROM => 'HasVersion.pm',
            AUTHOR        => 'Adriano R. Ferreira <ferreira@cpan.org>'
    ) : ()),
    ($EUMM_VERSION >= 6.30_01 ? (
            LICENSE => 'perl',
    ) : ()),
    ($EUMM_VERSION > 6.4501 ? (
            META_MERGE => {
                resources => {
                    repository => 'http://github.com/aferreira/cpan-Test-HasVersion',
		}
            },
    ) : ()),

);

