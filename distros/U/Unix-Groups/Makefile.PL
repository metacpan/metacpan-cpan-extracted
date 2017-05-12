use 5.008008;
use ExtUtils::MakeMaker;

exit 0 if $ENV{AUTOMATED_TESTING} and $^O ne 'linux';

exit 0
    if ($ENV{AUTOMATED_TESTING} and
	system q{echo -e '#include <sys/types.h>\n#include <unistd.h>\n#include <grp.h>' |
                 gcc -xc -E - >/dev/null 2>&1});

WriteMakefile(
    NAME              => 'Unix::Groups',
    VERSION_FROM      => 'lib/Unix/Groups.pm',
    PREREQ_PM         => {},
    ABSTRACT_FROM  => 'lib/Unix/Groups.pm',
    AUTHOR         => 'Torsten Förtsch <torsten.foertsch@gmx.net>',
    dist           => {
		       COMPRESS => 'gzip -9f',
		       PREOP    => './mk_README.sh',
 		      },
    LIBS              => [''],
    DEFINE            => '',
    INC               => '-I.',
);
