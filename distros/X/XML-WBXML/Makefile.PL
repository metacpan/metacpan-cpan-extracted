use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'XML::WBXML',
    AUTHOR        => [ 'David Glasser <glasser@bestpractical.com>', 'Mikhail Ivanov <m.ivanych@gmail.com>', ],
    VERSION_FROM  => 'lib/XML/WBXML.pm',                                                                            # finds $VERSION
    ABSTRACT_FROM => 'lib/XML/WBXML.pm',                                                                            # retrieve abstract from module
    LICENSE       => 'perl_5',
    PREREQ_PM     => {},                                                                                         # e.g., Module::Name => 1.1
    LIBS          => ['-lwbxml2'],                                                                               # e.g., '-lm'
    DEFINE        => '',                                                                                         # e.g., '-DHAVE_SOMETHING'
    INC           => '-I.',                                                                                      # e.g., '-I. -I/usr/include/other'

    # Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            license     => [ 'http://dev.perl.org/licenses/' ],
            bugtracker  => {
                web    => 'https://github.com/ivanych/XML-WBXML/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/ivanych/XML-WBXML.git',
                web  => 'https://github.com/ivanych/XML-WBXML',
            },
        },
    },
);
