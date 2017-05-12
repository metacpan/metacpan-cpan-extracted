use strict;

use ExtUtils::MakeMaker;

my $PLEDGE_CHECK = <<EOC

#include <unistd.h>

int main() {
    pledge("", NULL);
    return 0;
}

EOC
;

system("echo '$PLEDGE_CHECK' | cc -x c - > /dev/null 2>&1");
die "ERROR: unable to find pledge, platform not supported" if $?;

WriteMakefile(
    NAME              => 'Unix::Pledge',
    VERSION_FROM      => 'lib/Unix/Pledge.pm',
    PREREQ_PM         => {},
    AUTHOR            => 'Richard Farr',
    LICENSE           => 'perl',
    dist => {
        PREOP => 'pod2text $(VERSION_FROM) > $(DISTVNAME)/README',
    },
    META_MERGE => {
        resources => {
            repository => 'git://github.com/rfarr/Unix-Pledge.git',
            bugtracker => 'https://github.com/rfarr/Unix-Pledge/issues',
        },
    },
);
