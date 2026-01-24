use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

# Find the xs_jit.c file
my $xs_jit_c = 'lib/XS/JIT/xs_jit.c';
die "Cannot find $xs_jit_c" unless -f $xs_jit_c;

my %WriteMakefileArgs = (
    NAME             => 'XS::JIT',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/XS/JIT.pm',
    ABSTRACT_FROM    => 'lib/XS/JIT.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.008003',
    macro => { TARFLAGS   => "--format=ustar -c -v -f" },
    # XS configuration
    XSOPT            => '-noprototypes',
    INC              => '-I.',
    # Include xs_jit.o in the object files to link
    OBJECT           => '$(O_FILES) lib/XS/JIT/xs_jit$(OBJ_EXT)',

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Digest::MD5' => '0',
        'DynaLoader'  => '0',
        'Config'      => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'XS-JIT-* lib/XS/JIT/*.o lib/XS/*.o *.o' },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);

# Custom targets for compiling xs_jit.c and installing header
package MY;

sub postamble {
    my $self = shift;
    my $xs_jit_o = 'lib/XS/JIT/xs_jit$(OBJ_EXT)';
    my $xs_jit_c = 'lib/XS/JIT/xs_jit.c';
    my $xs_jit_h = 'lib/XS/JIT/xs_jit.h';

    return <<"MAKE";

# Compile xs_jit.c to object file
$xs_jit_o : $xs_jit_c $xs_jit_h
\t\$(CCCMD) \$(CCCDLFLAGS) "-I\$(PERL_INC)" \$(PASTHRU_DEFINE) \$(DEFINE) -c -o $xs_jit_o $xs_jit_c

# Make sure xs_jit.o is built before linking
\$(INST_DYNAMIC) : $xs_jit_o

# Install header file
install :: install_xs_jit_header

install_xs_jit_header :
\t\$(NOECHO) \$(MKPATH) "\$(DESTINSTALLSITEARCH)/auto/XS/JIT"
\t\$(NOECHO) \$(CP) $xs_jit_h "\$(DESTINSTALLSITEARCH)/auto/XS/JIT/xs_jit.h"
\t\$(NOECHO) \$(ECHO) "Installed xs_jit.h to \$(DESTINSTALLSITEARCH)/auto/XS/JIT/"

MAKE
}
