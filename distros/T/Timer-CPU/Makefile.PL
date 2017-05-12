use strict;

use ExtUtils::MakeMaker;


my %args = (
    NAME => 'Timer::CPU',
    VERSION_FROM => 'lib/Timer/CPU.pm',
    PREREQ_PM => {
      'XSLoader' => 0,
    },
    LIBS => [],
    DEFINE => '',
    LICENSE => 'perl',
    OBJECT => 'CPU.o',
    dist => {
      PREOP => 'perldoc -uT lib/Timer/CPU.pm > README.pod; pod2text README.pod > $(DISTVNAME)/README',
    },
);


my $eummv = eval ($ExtUtils::MakeMaker::VERSION);
if ($eummv >= 6.45) {
    $args{META_MERGE} = {
        resources => {
            repository => 'git://github.com/hoytech/Timer-CPU.git',
            bugtracker => 'https://github.com/hoytech/Timer-CPU/issues',
        },
    };
}

WriteMakefile(%args);
