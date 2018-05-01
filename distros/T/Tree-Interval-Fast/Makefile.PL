use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Tree::Interval::Fast',
    AUTHOR           => q{Alessandro Vullo <avullo@cpan.org>},
    VERSION_FROM     => 'lib/Tree/Interval/Fast.pm',
    ABSTRACT_FROM    => 'lib/Tree/Interval/Fast.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.008',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
	'Test::More' => '0',
	'Test::Deep' => '0',	       
	'Test::LeakTrace' => '0'
    },
    PREREQ_PM => {
        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
    },
    META_MERGE => {
	'meta-spec' => { version => 2 },
        resources => {
        repository => {
            type => 'git',
            url  => 'https://github.com/avullo/Tree-Interval-Fast.git',
            web  => 'https://github.com/avullo/Tree-Interval-Fast',
        },
     },
},	      
    LIBS      => [''],   # e.g., '-lm',
    DEFINE    => '-DENABLE_DEBUG', # e.g., '-DHAVE_SOMETHING'	      
    INC       => '-Iitree',     # e.g., '-I/usr/include/other'
    MYEXTLIB  => 'itree/libitree$(LIB_EXT)',
    'C'        => [ qw( Tree-Interval-Fast.c ) ],
    'XS'       => { 'Tree-Interval-Fast.xs' => 'Tree-Interval-Fast.c' },
    'OBJECT'   => 'Tree-Interval-Fast.o',	      
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Tree-Interval-Fast-*' },
);

sub MY::postamble {
'
$(MYEXTLIB): itree/Makefile
	cd itree && $(MAKE) $(PASSTHRU)
';
}
