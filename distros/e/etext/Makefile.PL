# Makefile.PL for Tk::eText, the CPAN distribution "etext".
use 5.010;		# the tests use the defined-or operator
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Tk::MMutil;
use Tk::Config ();

# The eText widget is a self-contained (tk4.0b3-derived, block-enabled)
# text widget compiled against the headers of the installed Perl/Tk.
# It is linked into its own shared object and talks to Tk through the
# pTk "vtable" mechanism, like Tk's own loadable widgets.

my $tk  = Tk::MMutil::installed_tk();
my $ptk = Tk::MMutil::findpTk($tk);

my @c = map { "$_.c" } qw(tkText tkTextBTree tkTextDisp tkTextIndex
			  tkTextMark tkTextTag tkTextWind tkTextImage tkTextUndo
			  pperlGlue);

my %args = (
    NAME	  => 'Tk::eText',
    DISTNAME	  => 'etext',		# the distribution's name on CPAN since 1997
    VERSION_FROM  => 'eText.pm',
    XS_VERSION	  => MM->parse_version('eText.pm'),
    # (Not ABSTRACT_FROM: MakeMaker would look for "etext - ...", after DISTNAME.)
    ABSTRACT	  => 'A Tk text widget with nestable "blocks" (editable formulas)',
    AUTHOR	  => 'Ilya Zakharevich <ilyaz@cpan.org>',
    LICENSE	  => 'perl_5',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
	'ExtUtils::MakeMaker' => '6.64',
	'Tk'		      => '804.027',	# Tk::MMutil, Tk::Config, the headers
    },
    PREREQ_PM	  => { 'Tk' => '804.027' },
    TEST_REQUIRES => { 'Test::More' => '0.88' },
    META_MERGE	  => {
	'meta-spec'    => { version => 2 },
	dynamic_config => 0,
	resources      => {
	    homepage   => 'https://github.com/ilyaz-ai/etext',
	    repository => {
		type => 'git',
		url  => 'https://github.com/ilyaz-ai/etext.git',
		web  => 'https://github.com/ilyaz-ai/etext',
	    },
	    bugtracker => { web => 'https://github.com/ilyaz-ai/etext/issues' },
	},
	keywords       => [qw(Tk text widget block formula equation editor)],
	# utils/ bundles FreezeThaw and Text::TeX for the demo (they are
	# on CPAN in their own right): not to be indexed from here.
	no_index       => { directory => [qw(utils demo)] },
    },
    C		  => [ @c, 'eText.c' ],
    H		  => [ qw(tkText.h pperl.h eTextSyms.h) ],
    OBJECT	  => '$(O_FILES)',
    INC		  => "-I. -I$tk -I$ptk $Tk::Config::xinc",
    DEFINE	  => '-DLangIsPerl',
    LIBS	  => [ "$Tk::Config::xlib -lX11" ],
    DIR		  => [],
    # eTextSyms.PL regenerates the (committed) symbol-prefix header; it
    # must only be run by hand, never by MakeMaker's default *.PL rule.
    PL_FILES	  => {},
    depend	  => { '$(O_FILES)' => 'tkText.h pperl.h eTextSyms.h' },
    dist	  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean	  => { FILES => 'etext-* MANIFEST.bak' },
);

# Each of these keys appeared with the ExtUtils::MakeMaker version named;
# an older one warns about keys it does not know and ignores them, so
# they are dropped for it, with the requirements they carried folded into
# PREREQ_PM (which every version understands).
my $mm = $ExtUtils::MakeMaker::VERSION;
my %since = (
    LICENSE		=> 6.31,
    META_MERGE		=> 6.46,
    MIN_PERL_VERSION	=> 6.48,
    CONFIGURE_REQUIRES	=> 6.52,
    TEST_REQUIRES	=> 6.64,
);
for my $key (sort keys %since) {
    next if $mm >= $since{$key};
    my $gone = delete $args{$key};
    if ($key eq 'TEST_REQUIRES' || $key eq 'CONFIGURE_REQUIRES') {
	for my $module (keys %$gone) {
	    $args{PREREQ_PM}{$module} = $gone->{$module}
		unless exists $args{PREREQ_PM}{$module};
	}
    }
}

Tk::MMutil::TkExtMakefile(%args);
