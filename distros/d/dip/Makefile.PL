use strict;
use warnings;
use ExtUtils::MakeMaker 6.30;
my $from = 'lib/dip.pm';
WriteMakefile(
    ABSTRACT_FROM      => $from,
    AUTHOR             => 'Marcel Gruenauer <marcel@cpan.org>',
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => '6.58' },
    LICENSE            => 'perl',
    NAME               => 'dip',
    EXE_FILES          => ["bin/dip"],
    PREREQ_PM          => {
        'Aspect'          => '1.02',
        'Carp'            => '0',
        'Data::Dumper'    => '0',
        'File::Slurp'     => '0',
        'Getopt::Long'    => '0',
        'Term::ANSIColor' => '0',
        'Time::HiRes'     => '0',
        'autodie'         => '0',
    },
    VERSION_FROM => $from,
    test         => { TESTS => 't/*.t' }
);
