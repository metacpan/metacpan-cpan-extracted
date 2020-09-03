use strict;
use warnings;

use Config qw(%Config);
use ExtUtils::MakeMaker;

unless ($^O eq "MSWin32" || $^O eq "cygwin") {
    die "OS unsupported\n";
}

my %param = (
    NAME          => 'Win32::ODBC',
    VERSION_FROM  => 'ODBC.pm',
    OBJECT        => 'CMom$(OBJ_EXT) Constant$(OBJ_EXT) CResults$(OBJ_EXT) ODBC$(OBJ_EXT)',
    XS            => { 'ODBC.xs' => 'ODBC.cpp' },
);
$param{INC} = '-GX'                     if $Config{'cc'} =~ /^cl/i;
$param{INC} = '-I$Config{incpath}\\mfc' if $Config{'cc'} =~ /^bcc32/i;
$param{NO_META} = 1 if eval "$ExtUtils::MakeMaker::VERSION" >= 6.10_03;
WriteMakefile(%param);

package MY;
use Config qw(%Config);

sub const_loadlibs {
    my ($self) = @_;
    if ($^O eq "MSWin32" && $Config{cc} =~ /^gcc/i) {
	$self->{LDLOADLIBS} .= " -lodbccp32";

    }
    return $self->SUPER::const_loadlibs;
}

sub xs_c {
    '
.xs.cpp:
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) $(XSPROTOARG) $(XSUBPPARGS) $*.xs >xstmp.c && $(MV) xstmp.c $*.cpp
';
};
