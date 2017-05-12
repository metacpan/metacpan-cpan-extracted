use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::Editor::Easy',
    AUTHOR              => 'Sebastien Grommier <sgrommier@free.fr>',
    VERSION_FROM        => 'lib/Text/Editor/Easy.pm',
    ABSTRACT_FROM       => 'lib/Text/Editor/Easy.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'IO::File' => 0,
        'Scalar::Util' => 0,
        'Data::Dump' => 0,
	'Devel::Size' => 0,
	'Thread::Queue' => 0,
	'Time::HiRes' => 0,
	'File::Basename' => 0,
	'Tk' => 0,
	'Syntax::Highlight::Perl::Improved' => 0,
	'Fcntl' => 0,
	'SDBM_File' => 0,
    'File::Spec' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-Editor-Easy-*' },
);
