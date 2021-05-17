use strict;
use warnings;

use Config qw(%Config);
use ExtUtils::MakeMaker;

unless ($^O eq "MSWin32" || $^O eq "cygwin") {
    die "OS unsupported\n";
}

require Win32;

my %param = (
    NAME          => 'Win32::Process',
    VERSION_FROM  => 'Process.pm',
    XS            => { 'Process.xs' => 'Process.cpp' },
);
$param{INC}     = '-GX' if $Config{'cc'} =~ /^cl/i;
$param{DEFINE}  = '-DSTRICTLY_WINDOWS95' unless Win32::IsWinNT();
$param{NO_META} = 1 if eval "$ExtUtils::MakeMaker::VERSION" >= 6.10_03;
WriteMakefile(%param);

sub MY::xs_c {
    '
.xs.cpp:
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) $(XSPROTOARG) $(XSUBPPARGS) $*.xs >xstmp.c && $(MV) xstmp.c $*.cpp
';
}

