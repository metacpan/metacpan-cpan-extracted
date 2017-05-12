use 5.010;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'ruby-collections-perl',
    AUTHOR           => q{Wei-Ming Wu <wnameless@gmail.com>, Chia-Hsuan Lee <k75228kimo@gmail.com>},
    VERSION_FROM     => 'lib/Ruby/Collections.pm',
    ABSTRACT_FROM    => 'lib/Ruby/Collections.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.65_01,
    },
    BUILD_REQUIRES => {
        'Test::More'      => 0.98,
        'Test::Exception' => 0.31, 
        'Test::Output'    => 1.01,
    },
    PREREQ_PM => {
    	'Scalar::Util'         => 1.27,
    	'Math::Combinatorics'  => 0.09,
    	'Set::CrossProduct'    => 1.95,
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Ruby-Collections-*' },
);
