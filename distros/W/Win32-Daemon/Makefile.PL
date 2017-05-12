use strict;
use warnings;

use Config qw(%Config);
use ExtUtils::MakeMaker;

unless ($^O eq "MSWin32" || $^O eq "cygwin") {
    die "OS unsupported\n";
}

require Win32;

my %param = (
    NAME          => 'Win32::Daemon',
    VERSION_FROM  => 'Daemon.pm',
    DEFINE        => '-DPERL_NO_GET_CONTEXT',
    OBJECT        => 'CCallbackList$(OBJ_EXT) CCallbackTimer$(OBJ_EXT) Constant$(OBJ_EXT) CWinStation$(OBJ_EXT) Daemon$(OBJ_EXT) ServiceThread$(OBJ_EXT)',
    XS            => { 'Daemon.xs' => 'Daemon.cpp' },
);
$param{INC} .= ' -EHsc' if $Config{'cc'} =~ /^cl/i;
$param{NO_META} = 1 if eval "$ExtUtils::MakeMaker::VERSION" >= 6.10_03;
WriteMakefile(%param);

sub MY::xs_c {
    '
.xs.cpp:
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) $(XSPROTOARG) $(XSUBPPARGS) $*.xs >xstmp.c && $(MV) xstmp.c $*.cpp
';
}
