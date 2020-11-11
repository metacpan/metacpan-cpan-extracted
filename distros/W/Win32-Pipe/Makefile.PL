use 5.006; #perl 5.6 required by use warnings;
use strict;
use warnings;
use Config qw(%Config);
use ExtUtils::MakeMaker;

unless ($^O eq "MSWin32" || $^O eq "cygwin") {
    die "OS unsupported\n";
}

my %param = (
    NAME          => 'Win32::Pipe',
    VERSION_FROM  => 'Pipe.pm',
    OBJECT        => 'Cpipe$(OBJ_EXT) Pipe$(OBJ_EXT)',
    XS            => { 'Pipe.xs' => 'Pipe.cpp' },
);
$param{NO_META} = 1 if eval "$ExtUtils::MakeMaker::VERSION" >= 6.10_03;
$param{INC} = '-GX' if $Config{'cc'} =~ /^cl/i;
WriteMakefile(%param);

sub MY::xs_c {
    '
.xs.cpp:
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) $(XSPROTOARG) $(XSUBPPARGS) $*.xs >xstmp.c && $(MV) xstmp.c $*.cpp
';
}
