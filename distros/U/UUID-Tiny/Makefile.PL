use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'UUID::Tiny',
    AUTHOR              => 'Christian Augustin <mail@caugustin.de>',
    VERSION_FROM        => 'lib/UUID/Tiny.pm',
    ABSTRACT_FROM       => 'lib/UUID/Tiny.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
    	'Carp'         => 0,
    	'Digest::MD5'  => 0,
		'MIME::Base64' => 0,
		'Time::HiRes'  => 0,
		'POSIX'        => 0,
        'Test::More'   => 0,
        'IO::File'     => 0,
        ($] < 5.010000 ? ( 'Digest::SHA1' => 0) :()), # only require Digest::SHA1 on 5.8
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'UUID-Tiny-*' },
);
