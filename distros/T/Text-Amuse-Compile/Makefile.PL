use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Text::Amuse::Compile',
    AUTHOR           => q{Marco Pessotto <melmothx@gmail.com>},
    VERSION_FROM     => 'lib/Text/Amuse/Compile.pm',
    ABSTRACT_FROM    => 'lib/Text/Amuse/Compile.pm',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'File::Temp' => 0,
        'PDF::API2' => 0,
    },
    PREREQ_PM => {
        # ours
        'Text::Amuse' => 1.80,
        'PDF::Imposition' => 0.23,
        'EBook::EPUB::Lite' => 0.71,
        # needed
        'Moo' => 1,
        'Type::Tiny' => 1,
        'Template::Tiny' => 1.12, # version in wheezy
        'IPC::Run' => 0,
        'Archive::Zip' => 0, # alread a requirement of EBook::EPUB
        'Path::Tiny' => 0,
        'JSON::MaybeXS' => 0,
    },
    EXE_FILES => [
        'bin/muse-compile.pl',
        'bin/muse-create-font-file.pl',
       ],
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Text-Amuse-Compile-*' },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/melmothx/text-amuse-compile',
            homepage => 'http://amusewiki.org',
            x_IRC => 'irc://irc.libera.chat/#amusewiki',
            x_WebIRC => 'https://web.libera.chat/#amusewiki',
           },
    },

);

# Local Variables:
# cperl-indent-parens-as-block: t
# End:
