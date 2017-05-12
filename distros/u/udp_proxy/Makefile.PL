#!/usr/bin/perl

use 5.008_008;
use ExtUtils::MakeMaker;

my $CC = 'g++';

WriteMakefile(
    NAME                => 'udp_proxy',
    VERSION_FROM        => 'lib/udp_proxy.pm', # finds $VERSION
    PREREQ_PM           => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM       => 'lib/udp_proxy.pm', # retrieve abstract from module
    AUTHOR              => 'Pavel V. Cherenkov <pcherenkov@gmail.com>', # perl module, not actual udpxy author
    META_ADD            => {
        resources           => {
            license             => 'http://www.gnu.org/licenses/',
            repository          => ( 'http://udpxy.svn.sourceforge.net/svnroot/udpxy/trunk/chipmunk/' ),
        },
    },
    LIBS                => [''], # e.g., '-lm'
    DEFINE              => '', # e.g., '-x c++', '-DHAVE_SOMETHING'
    INC                 => '-I.', # e.g., '-I. -I/usr/include/other'
    CC                  => $CC,
    LD                  => '$(CC)',
    CCFLAGS             => '-x c',
    TYPEMAPS            => [ 'perlobject.map' ],
    C                   => ['udp_proxy.c',
                            grep { $_ !~ /sloop_\w\.\w/ } glob('"*.c"')],
    OBJECT              => '$(O_FILES)', # link all the C files too
);

package MY;

sub c_o {
    my $inherited = shift->SUPER::c_o(@_);
    $inherited =~ s/\$\((?:XS_)?DEFINE_VERSION\)//g;
    $inherited =~ s/(\.c\$\(OBJ_EXT\):([\r\n]*)).*/${1}\t\$(CC) -x \$(shell test \$* = \$(NAME) && echo "c++" || echo "c") -c \$(PASTHRU_INC) \$(INC) \$(OPTIMIZE) \$(PERLTYPE) \$(MPOLLUTE) \$(CCCDLFLAGS) "-I\$(PERL_INC)" \$(PASTHRU_DEFINE) \$(DEFINE) \$*.c/g;
    $inherited;
}

sub const_cccmd {
    my $inherited = shift->SUPER::const_cccmd(@_);
    $inherited =~ s/\$\((?:XS_)?DEFINE_VERSION\)//g;
    $inherited;
}
