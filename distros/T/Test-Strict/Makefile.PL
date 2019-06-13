use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

my %conf = (
    NAME          => "Test::Strict",
    AUTHOR        => 'Pierre Denis <pdenis@cpan.org>',
    VERSION_FROM  => 'lib/Test/Strict.pm',
    ABSTRACT_FROM => 'lib/Test/Strict.pm',
    MIN_PERL_VERSION => 5.006,
    PREREQ_PM        => {
        'Test::Builder' => 0.01,
        'File::Spec'    => 0.01,
        'FindBin'       => 0.01,
        'File::Find'    => 0.01,
        'File::Temp'    => 0.01,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Test-Strict-*' },
);

if (eval { ExtUtils::MakeMaker->VERSION(6.3002) }) {
    $conf{LICENSE} = 'perl';
}

if (eval { ExtUtils::MakeMaker->VERSION(6.46) }) {
    $conf{META_MERGE} = {
        'meta-spec' => { version => 2 },
        provides    => {
            'Test::Strict' => { file => 'lib/Test/Strict.pm', version => '0.49' },
        },
        resources   => {
            repository  => {
                type    => 'git',
                url     => 'http://github.com/manwar/Test-Strict.git',
                web     => 'http://github.com/manwar/Test-Strict',
                license => 'http://dev.perl.org/licenses/',
            },
            bugtracker  => {
                web => 'http://github.com/manwar/Test-Strict',
            },
        },
        x_contributors => [
            'Gabor Szabo <szabgab@cpan.org>',
            'Peter Vereshagin <veresc@cpan.org>',
            'Graham Knop <haarg@cpan.org>',
            'Mohammad S Anwar <manwar@cpan.org>',
            'Robert Rothenberg <rrwo@cpan.org>',
        ],
    };
}

my %configure_requires = ('ExtUtils::MakeMaker' => '6.64');
my %build_requires = ();
my %test_requires  = (
    'Test::More' => '1.00',
    'File::Temp' => '0.01',
    'IO::Scalar' => 0,
);

if (eval { ExtUtils::MakeMaker->VERSION(6.52) }) {
    $conf{CONFIGURE_REQUIRES} = \%configure_requires;
} else {
    %{$conf{PREREQ_PM}} = (%{$conf{PREREQ_PM}}, %configure_requires);
}

if (eval { ExtUtils::MakeMaker->VERSION(6.5503) }) {
    $conf{BUILD_REQUIRES} = \%build_requires;
} else {
    %{$conf{PREREQ_PM}} = (%{$conf{PREREQ_PM}}, %build_requires);
}

if (eval { ExtUtils::MakeMaker->VERSION(6.64) }) {
    $conf{TEST_REQUIRES} = \%test_requires;
} else {
    %{$conf{PREREQ_PM}} = (%{$conf{PREREQ_PM}}, %test_requires);
}

WriteMakefile(%conf);
