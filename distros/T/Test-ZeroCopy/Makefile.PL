use strict;

use ExtUtils::MakeMaker;


my %args = (
    NAME => 'Test::ZeroCopy',
    VERSION_FROM => 'lib/Test/ZeroCopy.pm',
    PREREQ_PM => {
    },
    LIBS => [],
    DEFINE => '',
    OBJECT => 'ZeroCopy.o',
    LICENSE => 'perl',
    dist => {
      PREOP => 'pod2text $(VERSION_FROM) > $(DISTVNAME)/README',
    },
);


my $eummv = eval ($ExtUtils::MakeMaker::VERSION);

if ($eummv >= 6.45) {
    $args{META_MERGE} = {
        resources => {
            repository => 'git://github.com/hoytech/Test-ZeroCopy.git',
            bugtracker => 'https://github.com/hoytech/Test-ZeroCopy/issues',
        },
    };
}

$args{$eummv >= 6.64 ? 'TEST_REQUIRES' : 'PREREQ_PM'}->{'String::Slice'} = 0;

WriteMakefile(%args);
