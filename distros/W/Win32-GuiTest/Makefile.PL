#!/usr/bin/perl
#
# $Id: Makefile.PL,v 1.4 2010/05/27 13:31:25 int32 Exp $
#

use Config;
use ExtUtils::MakeMaker;

my $DEBUG = grep { m/^--debug$/ } @ARGV;
my $can_compile = $^O =~ /win32|cygwin/i;

warn "** This module can only work under Win32\n" unless $can_compile;
	
# generate Win32/GuiTest/Examples.pm
do 'eg/make_eg.pl';

my @make = (
	NAME				=> 'Win32::GuiTest',
	VERSION_FROM			=> 'lib/Win32/GuiTest.pm',
	$can_compile ? (
	OBJECT				=> 'GuiTest$(OBJ_EXT) DibSect$(OBJ_EXT)'  ,
	XS				=> { 'GuiTest.xs' => 'GuiTest.cpp' },
	) : ( C => [], XS => {},),
	TYPEMAPS			=> ['perlobject.map' ],
	( $DEBUG ? (
		(( $^O =~ /cygwin/i) ? (
			CCFLAGS		=> '-MD -DWIN32 -Z7 -DDEBUG -D_DEBUG',
			OPTIMIZE	=> '-Od'
		) : (
			CCFLAGS 	=> '-g',
		))
	) : ()),
	(( $^O =~ /cygwin/i) ? (
			CC              => 'g++',
			LD		=> 'g++',
			LDDLFLAGS	=> "-shared $Config{ccflags}",
			LIBS		=> ['-L/usr/lib/w32api -lgdi32'],
	) : ()),
	ABSTRACT_FROM			=> 'lib/Win32/GuiTest.pm',
	AUTHOR				=> 'Dennis K. Paulsen (ctrondlp@cpan.org), Ernesto Guisado (erngui@acm.org)',

        META_MERGE        => {
                resources => {
                        repository => 'http://github.com/dk/Win32-GuiTest',
                },
                no_index  => {
                        directory  => [qw(eg Recorder)],
                        file       => [qw(Makefile.PL makedist.pl)],
                },
        },
);


WriteMakefile(@make);

package MY;

sub xs_c {
    '
.xs.cpp:
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) $(XSPROTOARG) $(XSUBPPARGS) $*.xs >xstmp.c && $(MV) xstmp.c $*.cpp
';
}

sub distdir
{
	my $t = shift-> SUPER::distdir(@_);
	$t =~ s/(create_distdir distmeta)/my_create_predist $1/;
	$t . '

my_create_predist:
	@pod2text lib/Win32/GuiTest.pm > README
';
}

