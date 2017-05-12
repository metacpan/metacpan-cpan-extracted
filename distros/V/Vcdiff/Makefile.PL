use strict;

use ExtUtils::MakeMaker;


my %args = (
    NAME => 'Vcdiff',
    VERSION_FROM => 'lib/Vcdiff.pm',
    PREREQ_PM => {
      'Symbol' => 0,
      'Carp' => 0,
      'File::Temp' => 0, ## Just for the test suite
    },
    LICENSE => 'perl',
    dist => {
      PREOP => 'perldoc -uT $(VERSION_FROM) > README.pod; pod2text README.pod > $(DISTVNAME)/README',
    },
);


my $eummv = eval ($ExtUtils::MakeMaker::VERSION);
if ($eummv >= 6.45) {
    $args{META_MERGE} = {
        resources => {
            repository => 'git://github.com/hoytech/Vcdiff.git',
            bugtracker => 'https://github.com/hoytech/Vcdiff/issues',
        },
    };
}

WriteMakefile(%args);
