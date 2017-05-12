use 5.006;
use strict;
use warnings;

use Config qw(%Config);
use ExtUtils::MakeMaker qw(&WriteMakefile &neatvalue);

unless ($^O eq "MSWin32" || $^O eq "cygwin") {
    die "OS unsupported\n";
}

my $INSTDIR = grep(/INSTALLDIRS=perl/i, @ARGV) ? "lib" : "site\\lib";

my %param =
(
    NAME         => 'Win32::OLE',
    VERSION_FROM => 'lib/Win32/OLE.pm',
    XS           => { 'OLE.xs' => 'OLE.cpp' },
    # Without the next line MakeMaker will not export the bootstrap function
    # (because we are using FUNCLIST too).
    DL_FUNCS     => { 'Win32::OLE' => [] },
    clean        => { FILES => 'test.xls' },
);
my $FUNCLIST = [qw(SetSVFromVariant SetSVFromVariantEx SetVariantFromSV CreatePerlObject)];
$param{FUNCLIST} = $FUNCLIST if eval "$ExtUtils::MakeMaker::VERSION" >= 5.4302;
$param{NO_META} = 1 if eval "$ExtUtils::MakeMaker::VERSION" >= 6.10_03;
WriteMakefile(%param);

sub MY::xs_c {
    '
.xs.cpp:
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) $(XSPROTOARG) $(XSUBPPARGS) $*.xs >xstmp.c && $(MV) xstmp.c $*.cpp
';
}

sub MY::dlsyms {
    my($self,%attribs) = @_;

    my($funcs) = $attribs{DL_FUNCS} || $self->{DL_FUNCS} || {};
    my($vars)  = $attribs{DL_VARS} || $self->{DL_VARS} || [];
    my($imports)  = $attribs{IMPORTS} || $self->{IMPORTS} || {};
    my(@m);
    (my $boot = $self->{NAME}) =~ s/:/_/g;

    if (not $self->{SKIPHASH}{'dynamic'}) {
	push(@m,"
$self->{BASEEXT}.def: Makefile.PL
",
     q!	$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" -MExtUtils::Mksymlists \\
     -e "Mksymlists('NAME' => '!, $self->{NAME},
     q!', 'DLBASE' => '!,$self->{DLBASE},
     q!', 'DL_FUNCS' => !,neatvalue($funcs),
     q!, 'FUNCLIST' => !,neatvalue($FUNCLIST),
     q!, 'IMPORTS' => !,neatvalue($imports),
     q!, 'DL_VARS' => !, neatvalue($vars), q!);"
!);
    }
    join('',@m);
}
