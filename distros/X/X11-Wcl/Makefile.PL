#!/usr/bin/perl

use ExtUtils::MakeMaker;

#$Verbose = 100;
# maximum number of PERL Xt*Proc functions of each type that can be
# created
$NUM_XTPROCS = 25;

if (-d "/usr/lpp/bos.acct") {
	$MY_OS = "AIX";
	$MY_OS_VERSION = "4";
} elsif (-d "/usr/lpp/bos") {
	$MY_OS = "AIX";
	$MY_OS_VERSION = "3";
} elsif (-f "/usr/sbin/sam") {
	$MY_OS = "HPUX";
	$MY_OS_VERSION = "10";
} elsif (-f "/proc/version") {
	$MY_OS = "LINUX";
	$MY_OS_VERSION = "2";
} else {
	$MY_OS = "UNKNOWN";
	$MY_OS_VERSION = "0";
	warn "not ported to this operating system";
}

WriteMakefile(
	'INC'		=>	'-I/usr/local/include -I/usr/X11R6/include -I/usr/contrib/X11R5/include',
	'LIBS'		=>	['-L/usr/local/lib -L/usr/lib -L/lib -L/usr/X11R6/lib -L/usr/lib/X11R4 -lXmp -lWc -lMisc -lXm -lXmu -lXt -lX11'],
#	'LINKTYPE'	=>	'static',
	'NAME'		=>	'X11::Wcl',
	'OBJECT'	=>	'Wcl_wrap.o',
	'OPTIMIZE'	=>	'-I.',
	'PM'		=>	{'Wcl.pm' => '$(INST_LIBDIR)/Wcl.pm'},
	'VERSION_FROM'	=>	'Wcl.pm',
	'clean'	=>	{FILES => 'Wcl.i Wcl_wrap.c Wcl_wrap.html'},
);

sub MY::remove_I
{
	my($inherited) = @_;

	# c89 compiler under AIX 4 is finicky about -I that references
	# non-existent directory
	my $x = $inherited;
	if ($x =~ m@^INC\s*=\s*((\S.*)?\S)\s*$@m) {
		$x = $1;
		my $left = $`;
		my $right = $';
		$x =~ s@(?!\w)-I(\S+)@(-d "$1") ? "-I$1" : ""@eg;
		$inherited = $left . "INC = $x" . $right;
	}

	$inherited;
}

sub MY::const_config
{
	my($inherited) = shift->MM::const_config(@_);

	$inherited = MY::remove_I($inherited);

	if ($MY_OS eq "AIX") {
		# need c89 compiler, for prototypes
		my $x = $inherited;
		if ($x =~ m@^CC\s*=\s*((\S.*)?\S)\s*$@m) {
			my $left = $`;
			my $right = $';
			$inherited = $left . "CC = c89\n" . $right;
		}
	}

	$inherited;
}

sub MY::constants
{
	my($inherited) = shift->MM::constants(@_);

	$inherited = MY::remove_I($inherited);

	$inherited;
}

sub MY::cflags
{
	my($inherited) = shift->MM::cflags(@_);

	# tell code what OS it is compiling under
	$inherited =~
		s@^(CCFLAGS)\s*=\s*((\S.*)?\S)\s*$@$1 = -D${MY_OS}_VERSION=$MY_OS_VERSION $2@m;

	if ($MY_OS eq "AIX") {
		# AIX needs -D_NO_PROTO stripped, so swig sees prototypes
		my $x = $inherited;
		if ($x =~ m@^CCFLAGS\s*=\s*((\S.*)?\S)\s*$@m) {
			$x = $1;
			my $left = $`;
			my $right = $';
			$x =~ s@(?!\w)-D_NO_PROTO\b@@g;
			$inherited = $left . "CCFLAGS = $x" . $right;
		}
	} elsif ($MY_OS eq "LINUX") {
		# my SMP machine sometimes crashes without something like this
#		$inherited =~ s@^(CCFLAGS)\s*=\s*((\S.*)?\S)\s*$@$1 = -pipe $2@m;
	}

	$inherited;
}

sub MY::postamble
{
	my $x = <<\EOF;
Wcl.pm.orig :
	cat Wcl.pm >Wcl.pm.orig
Wcl.pm : Wcl_wrap.c
Wcl_wrap.c : Wcl-i Wcl-i2 Wcl.pm.orig Wcl-gen
	cat Wcl-i >Wcl.i
	CC='$(CC)' CCFLAGS='$(INC) $(CCFLAGS) $(OPTIMIZE)' $(FULLPERL) Wcl-gen Wcl-i NUM_XTPROCS >>Wcl.i
	cat Wcl-i2 >>Wcl.i
	swig -package 'X11::Wcl' -module 'Wcl' -perl5 -dhtml -shadow Wcl.i
	cat Wcl.pm.orig >> Wcl.pm
	perl -p -i -e 's#package Wcl;#package X11::Wcl;#' Wcl.pm
	perl -p -i -e 's#bootstrap Wcl;#bootstrap X11::Wcl;#' Wcl.pm
	perl -p -i -e 's#boot_Wcl#boot_X11__Wcl#' Wcl_wrap.c
	perl -p -i -e 's#PASS_THROUGH_SWIG_##g' Wcl_wrap.c Wcl_wrap.html
EOF
	$x =~ s@NUM_XTPROCS@$NUM_XTPROCS@g;
	$x;
}
