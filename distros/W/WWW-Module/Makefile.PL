use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Module',
    AUTHOR              => 'Nigel Gourlay <nwetters@cpan.org>',
    VERSION_FROM        => 'lib/WWW/Module.pm',
    ABSTRACT_FROM       => 'lib/WWW/Module.pm',
    PL_FILES            => {},
    PREREQ_PM => {
	'Carp'          => 0,
	'Data::Dumper'  => 0,
	'File::HomeDir' => 0,
	'File::Spec'    => 0,
	'CPAN'          => 0,
	'Test::More'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Module-*' },
);
