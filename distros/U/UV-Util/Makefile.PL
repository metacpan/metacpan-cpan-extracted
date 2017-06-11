use ExtUtils::MakeMaker 7.12;

use File::Spec ();

my $lib_location = '-D_POSIX_C_SOURCE=200112 -I. -I../..';
warn("Please tell us how to find your libUV installation by setting PERL_LIBUV_PATH");
if (my $loc = $ENV{PERL_LIBUV_PATH}) {
    if (-e $loc && -d _ && -r _) {
        $lib_location .= " -I$loc"
    }
    else {
        warn("PERL_LIBUV_PATH does not point to a readable directory");
    }
}

WriteMakefile(
    NAME              => 'UV::Util',
    VERSION_FROM      => 'lib/UV/Util.pm',
    ABSTRACT_FROM     => 'lib/UV/Util.pm',
    AUTHOR            => 'Chase Whitener <capoeirab@cpan.org>',
    LICENSE           => 'perl',
    #CCFLAGS           => '-Wall -std=c99',
    #OPTIMIZE          => '-O3',
    LIBS              => ['-luv'], # e.g., '-lm'
    DEFINE            => $lib_location, # e.g., '-DHAVE_SOMETHING'
    #INC               => $lib_location, # e.g., '-I. -I/usr/include/other'
    # OBJECT            => '$(O_FILES)',
    META_MERGE   => {
        dynamic_config => 0,
        'meta-spec'    => {version => 2},
        no_index       => {directory => ['examples', 't']},
        prereqs        => {runtime => {requires => {perl => '5.008001'}}},
        resources      => {
            bugtracker => {web => 'https://github.com/genio/p5-UV-Util'},
            repository => {
                type => 'git',
                url  => 'https://github.com/genio/p5-UV-Util.git',
                web  => 'https://github.com/genio/p5-UV-Util',
            },
            x_IRC => 'irc://irc.perl.org/#perl'
        },
    },
    test              => {
        "TESTS" => "t/*.t",
    },
    XSMULTI           => 1,
    MIN_PERL_VERSION  => "5.008001",
    BUILD_REQUIRES => {
        "ExtUtils::MakeMaker" => "7.12",
    },
    CONFIGURE_REQUIRES => {
        "ExtUtils::MakeMaker" => "7.12",
        "File::Spec" => 0,
    },
    PREREQ_PM => {
        "Carp" => 0,
        "Exporter" => 0,
        "strict" => 0,
        "warnings" => 0,
    },
    TEST_REQUIRES => {
        "ExtUtils::MakeMaker" => "7.12",
        "Test::More" => "0.94"
    },
);
