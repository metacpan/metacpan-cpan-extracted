use 5.010;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

if (-e '/usr/share/zoneinfo') {
} elsif (-e '/usr/lib/zoneinfo') {
} elsif (($ENV{TZDIR}) && (-e $ENV{TZDIR})) {
} else {
	die "Olson database could not be detected";
}

my $pack_q_ok = 0;

eval { my $q = pack 'q>', 2 ** 33; my $p = unpack 'q>', $q; $pack_q_ok = 1; };

WriteMakefile(
    NAME             => 'Time::Zone::Olson',
    AUTHOR           => q{David Dick <ddick@cpan.org>},
    VERSION_FROM     => 'lib/Time/Zone/Olson.pm',
    ABSTRACT_FROM    => 'lib/Time/Zone/Olson.pm',
    LICENSE          => 'perl',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
	'strict' => 0,
	'warnings' => 0,
    },
    TEST_REQUIRES => {
	'Carp' => 0,
        'Config' => 0,
	'DirHandle' => 0,
        'Digest::SHA' => 0,
	'English' => 0,
	'File::Find' => 0,
	'FileHandle' => 0,
	'File::Spec' => 0,
	$pack_q_ok == 0 ? ( 'Math::Int64' => 0 ) : (),
	'POSIX' => 0,
	'strict' => 0,
        'Test::More' => 0,
        'Time::Local' => 0,
	'warnings' => 0,
    },
    PREREQ_PM => {
	'Carp' => 0,
        'Config' => 0,
	'DirHandle' => 0,
	'English' => 0,
	'FileHandle' => 0,
	'File::Spec' => 0,
	$pack_q_ok == 0 ? ( 'Math::Int64' => 0 ) : (),
	'POSIX' => 0,
	'strict' => 0,
	'warnings' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Time-Zone-Olson-*' },
);
