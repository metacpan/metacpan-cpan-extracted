use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

# Find the xs_jit.c file
my $xs_jit_c = 'lib/XS/JIT/xs_jit.c';
my $xs_jit_builder_c = 'lib/XS/JIT/xs_jit_builder.c';
die "Cannot find $xs_jit_c" unless -f $xs_jit_c;
die "Cannot find $xs_jit_builder_c" unless -f $xs_jit_builder_c;

my %WriteMakefileArgs = (
    NAME             => 'XS::JIT',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/XS/JIT.pm',
    ABSTRACT_FROM    => 'lib/XS/JIT.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.008003',
    macro => { TARFLAGS => "--format=ustar -c -v -f" },
    # XS configuration - JIT.xs in root (standard), Builder.xs handled by postamble
    XSOPT            => '-noprototypes',
    INC              => '-I. -Ilib/XS/JIT',
    # Include xs_jit.o in the object files to link (builder.o goes to its own .so)
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
    # .def windows specific
    clean => { FILES => 'XS-JIT-* lib/XS/JIT/*.o lib/XS/*.o *.o blib/arch/auto/XS/JIT/Builder/* lib/XS/JIT/Builder.def' },
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
    my $xs_jit_builder_o = 'lib/XS/JIT/xs_jit_builder$(OBJ_EXT)';
    my $xs_jit_builder_c = 'lib/XS/JIT/xs_jit_builder.c';
    my $xs_jit_builder_h = 'lib/XS/JIT/xs_jit_builder.h';
    my $builder_xs = 'lib/XS/JIT/Builder.xs';
    my $builder_c = 'lib/XS/JIT/Builder.c';
    my $builder_o = 'lib/XS/JIT/Builder$(OBJ_EXT)';
    my $builder_so = 'blib/arch/auto/XS/JIT/Builder/Builder.$(DLEXT)';
    my $builder_def = 'lib/XS/JIT/Builder.def';
    
    # -iwithsysroot is Apple Clang-specific; use -I on other platforms
    my $inc_flag = ($^O eq 'darwin') ? '-iwithsysroot' : '-I';
    
    # On Windows, we need a separate .def file for Builder.dll
    # Generate it now so it's available for the build
    my $builder_export_list = '';
    my $builder_def_rule = '';
    if ($^O eq 'MSWin32') {
        $builder_export_list = $builder_def;
        # Generate Builder.def file for Windows
        $builder_def_rule = <<"DEF_RULE";
# Generate Builder.def for Windows
$builder_def :
\t\$(NOECHO) \$(ECHO) "LIBRARY Builder" > $builder_def
\t\$(NOECHO) \$(ECHO) "EXPORTS" >> $builder_def
\t\$(NOECHO) \$(ECHO) "boot_XS__JIT__Builder" >> $builder_def

DEF_RULE
    }

    return <<"MAKE";
$builder_def_rule
# Compile xs_jit.c to object file
$xs_jit_o : $xs_jit_c $xs_jit_h
	\$(CCCMD) \$(CCCDLFLAGS) $inc_flag "\$(PERL_INC)" \$(PASTHRU_DEFINE) \$(DEFINE) -c -o $xs_jit_o $xs_jit_c

# Compile xs_jit_builder.c to object file
$xs_jit_builder_o : $xs_jit_builder_c $xs_jit_builder_h
	\$(CCCMD) \$(CCCDLFLAGS) $inc_flag "\$(PERL_INC)" \$(PASTHRU_DEFINE) \$(DEFINE) -c -o $xs_jit_builder_o $xs_jit_builder_c

# Make sure xs_jit object is built before linking main module
\$(INST_DYNAMIC) : $xs_jit_o

# Compile Builder.xs to Builder.c
$builder_c : $builder_xs
\t\$(XSUBPPRUN) \$(XSPROTOARG) \$(XSUBPPARGS) -prototypes $builder_xs > $builder_c

# Compile Builder.c to object file
$builder_o : $builder_c $xs_jit_builder_h
	\$(CCCMD) \$(CCCDLFLAGS) $inc_flag "\$(PERL_INC)" -Ilib/XS/JIT \$(PASTHRU_DEFINE) \$(DEFINE) -c -o $builder_o $builder_c

# Link Builder.so/dll - on Windows use Builder.def instead of EXPORT_LIST
$builder_so : $builder_o $xs_jit_builder_o $builder_export_list
\t\$(NOECHO) \$(MKPATH) blib/arch/auto/XS/JIT/Builder
\t\$(LD) \$(LDDLFLAGS) -o $builder_so $builder_o $xs_jit_builder_o \$(OTHERLDFLAGS) \$(MYEXTLIB) \$(PERL_ARCHIVE) \$(LDLOADLIBS) $builder_export_list \$(PERL_ARCHIVE_AFTER)

# Build Builder as part of dynamic target
dynamic :: $builder_so

# Install header files
install :: install_xs_jit_headers

install_xs_jit_headers :
\t\$(NOECHO) \$(MKPATH) "\$(DESTINSTALLSITEARCH)/auto/XS/JIT"
\t\$(NOECHO) \$(CP) $xs_jit_h "\$(DESTINSTALLSITEARCH)/auto/XS/JIT/xs_jit.h"
\t\$(NOECHO) \$(CP) $xs_jit_builder_h "\$(DESTINSTALLSITEARCH)/auto/XS/JIT/xs_jit_builder.h"
\t\$(NOECHO) \$(ECHO) "Installed headers to \$(DESTINSTALLSITEARCH)/auto/XS/JIT/"

MAKE
}
