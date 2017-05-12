use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefile_args = (
    NAME             => 'Text::JSON::Nibble',
    AUTHOR           => q{Paul G Webster <daemon@cpan.org>},
    VERSION_FROM     => 'lib/Text/JSON/Nibble.pm',
    ABSTRACT_FROM    => 'lib/Text/JSON/Nibble.pm',
    LICENSE          => 'BSD',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 0,
        resources => {
            bugtracker => { web => 'https://gitlab.com/paul-g-webster/PL-Text-JSON-Nibble/issues' },
            repository => {
                type => 'git',
                url => 'https://gitlab.com/paul-g-webster/PL-Text-JSON-Nibble.git',
                web => 'https://gitlab.com/paul-g-webster/PL-Text-JSON-Nibble',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Text-JSON-Nibble-*' },
);

delete $WriteMakefile_args{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31') };
delete $WriteMakefile_args{META_MERGE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.46') };
delete $WriteMakefile_args{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48') };
delete $WriteMakefile_args{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52') };

unless (eval { ExtUtils::MakeMaker->VERSION('6.64') }) {
    my $test_requires = delete $WriteMakefile_args{TEST_REQUIRES};
    $WriteMakefile_args{PREREQ_PM}{$_} = $test_requires->{$_} for keys %$test_requires;
}

WriteMakefile(%WriteMakefile_args);
