use ExtUtils::MakeMaker;

##----------------------------------------------------------------------
## Configuration
##----------------------------------------------------------------------
use Alien::Unicruft;
my %prereq = (
	      'ExtUtils::MakeMaker' => 6.52, ##-- for CONFIGURE_REQUIRES
	      'Alien::Unicruft' => 0.001,
	     );

##-- ensure mininum libunicruft version
use version;
my $unicruft_min_version = "0.21";
my ($UX_INC,$UX_LIBS);
if (Alien::Unicruft->install_type ne 'system') {
  my $unicruft_alien_version = (Alien::Unicruft->can('pkgconfig')
				? Alien::Unicruft->pkgconfig('unicruft')->keyword('Version') ##-- RT bug #124235 with Alien::Base v0.41
				: (Alien::Unicruft->can('config')
				   ? Alien::Unicruft->config('version')			 ##-- Alien::Base >= v0.41
				   : undef));
  die("Failed to determine \$unicruft_alien_version") if (!defined($unicruft_alien_version));

  (my $v_alien = $unicruft_alien_version) =~ s/\-/_/g;
  die("Required library libunicruft >= v$unicruft_min_version not found; we have v$unicruft_alien_version\n")
    if (version->parse($v_alien) < version->parse($unicruft_min_version));

  $UX_INC  = Alien::Unicruft->cflags;
  $UX_LIBS = Alien::Unicruft->libs;
  #print STDERR "DEBUG: got v_alien=$v_alien; INC={$UX_INC} ; LIBS=${UX_LIBS}\n";
}
elsif (system("pkg-config --atleast-version=${unicruft_min_version} unicruft") != 0) {
  die("Required library libunicruft >= v$unicruft_min_version not found; we have v", `pkg-config --modversion unicruft`);
}
else {
  $UX_INC  = join(' ', map { $s=`pkg-config --cflags-only-I $_`; chomp($s); $s } qw(unicruft));
  $UX_LIBS = join(' ', map { $s=`pkg-config --libs $_`; chomp($s); $s } qw(unicruft));

  #print STDERR "DEBUG: got system pkg-config flags INC={$UX_INC}, LIBS={$UX_LIBS}\n";
}


##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------
WriteMakefile
  (
   NAME		=> 'Unicruft',
   #DISTNAME	=> 'unicruft-perl',
   DISTNAME	=> 'Unicruft',
   AUTHOR       => 'Bryan Jurish <moocow@cpan.org>',
   ABSTRACT	=> 'Perl interface to unicruft transliteration library',
   VERSION_FROM	=> 'Unicruft.pm',
   LICENSE      => 'perl',

   ##-- prerequisites
   CONFIGURE_REQUIRES => \%prereq,
   PREREQ_PM => \%prereq,

   ##-- user variables
   #CC           => 'c++',   ##-- your c++ compiler
   LIBS         => $UX_LIBS,      ##-- additional librariese
   INC          => $UX_INC,       ##-- additional includes
   DEFINE       => '-DHAVE_CONFIG_H',     ##-- additional defines
   CCFLAGS      => '',          ##-- additional flags
   OPTIMIZE    => '-O2 -pipe', ##-- optimization flags
   #OBJECT      => 'Gfsm.o GfsmPerl.o',

   ##-- install these
   EXE_FILES => [glob("bin/*.perl")],

   ##-- DEBUG
   #MAKEAPERL=>1,
   ##LINKTYPE=>'static',
   #MAP_TARGET=>'ucperl',
   ##INCLUDE_EXT=>[qw(Encode DynaLoader Exporter)], ##-- ??? doesn't work ???
   #CCFLAGS=>'-g',
   ##-- /DEBUG

   ##-- stuff that probably doesn't need to be changed
   #XSOPT        => '-C++',
   #TYPEMAPS     => ['perlobject.map', 'typemap'],
  );


#-----------------------------------------------------------------------
# Extensions
#-----------------------------------------------------------------------

##---------------------------------------------------------------
sub MY::constants {
  package MY;
  my $css = 'moopod.css';
  my $inherited = shift->SUPER::constants(@_);
  $inherited .= (
		 ###-- constants: html css
		 "\n"
		 ."CSS ?= $css\n"
		);
  return $inherited;
}

##---------------------------------------------------------------
sub MY::depend {
  package MY;
  my $inherited = shift->SUPER::depend(@_);
  $inherited .= (
		 ###-- depends -> README.txt
		 "\n\n"
		 ."dist: README.txt\n"
		 ."\n"
		 ."create_distdir: README.txt\n"
		 #."distdir_am: README.txt\n"
		 ."\n"
		 ."distcheck: README.txt\n"
		 ."\n"
		 ."manicheck: README.txt\n"
		 ."\n"
		);
  return $inherited;
}

##---------------------------------------------------------------
sub MY::special_targets {
  package MY;
  my $inherited = shift->SUPER::special_targets(@_);
  $inherited .=
"
.SUFFIXES: .pm .pod .rpod .man .txt .html

.pm.html:
\tpod2html --css=\$(CSS) --infile=\$< --outfile=\$@

.pm.txt:
\tpod2text \$< \$@

.pod.html:
\tpod2html --css=\$(CSS) --infile=\$< --outfile=\$@

.pod.txt:
\tpod2text \$< \$@

.rpod.html:
\tpod2html --css=\$(CSS) --infile=\$< --outfile=\$@

.rpod.txt:
\tpod2text \$< \$@

";
  return $inherited;
}

##---------------------------------------------------------------
sub MY::manifypods {
  package MY;
  my $inherited = shift->SUPER::manifypods(@_);
  my $out = $inherited;

  my $new = $inherited;
  my $html_ns_sep = ".";
  $new =~ s/.*(?=^manifypods\b)//sm;
  $new =~ s/\n\n.*//s;
  my ($deps0,$rules0) = split(/(?<!\\)\n/, $new, 2);
  my ($deps,$rules);

  ##-----------------------
  ## html
  my $htmlvars ='

##--- pod -> HTML

.SUFFIXES: .html

INST_CSS ?= ../../$(CSS)
POD2HTMLFLAGS ?= --css="$(INST_CSS)" --backlink --podroot=blib --podpath=script --header
POD2HTML ?= pod2html $(POD2HTMLFLAGS)

INST_HTMLDIR ?= blib/html

HTML_EXT ?= html
HTML1EXT ?= $(HTML_EXT)
HTML3EXT ?= $(HTML_EXT)

##-- lifted from MakeMaker blibdir section
$(INST_HTMLDIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_HTMLDIR)
	$(NOECHO) $(CHMOD) 755 $(INST_HTMLDIR)
	$(NOECHO) $(TOUCH) $(INST_HTMLDIR)$(DFSEP).exists

';
  ($deps,$rules) = ($deps0,$rules0);
  $deps =~ s/^manifypods\b/htmlifypods/;
  $deps .= "\\\n\t".'$(INST_HTMLDIR)$(DFSEP).exists';
  $rules =~ s/POD2MAN/POD2HTML/g;
  $rules =~ s/MAN(\d)EXT/HTML$1EXT/g;
  $rules =~ s/INST_MAN\dDIR/INST_HTMLDIR/g;
  $rules =~ s/^\s+\$\(NOECHO\).*?\n//smg;
  $rules =~ s/::/${html_ns_sep}/sg if ($html_ns_sep ne '::');
  $rules =~ s/\\\n/\n/sg;
  my $hackit = ("\\\n"
		."\t | ".'$(PERL) -p'." \\\n"
		."\t   ".'-e\'sub hackhref {($$href=shift)=~s|^/*||; $$href=~s|^script/||; $$href=~s|/|'.$html_ns_sep.'|g; $$href;}\''." \\\n"
		."\t   ".'-e\'s/<a href="([^"]*)/\'\\\'\'<a href="\'\\\'\'.hackhref($$1)/eg;\''
               );
  #$hackit = ' | cat - ';
  $rules =~ s/\t\s+(\S+)\s+(\S+)/\t\$(POD2HTML) --infile=$1 ${hackit} \\\n\t > $2 || (rm -f $2 && false)/sg;
  $out .= $htmlvars.$deps."\n".$rules."\n\n";

  ##-----------------------
  ## text
  my $text_ns_sep = $html_ns_sep;
  my $textvars ='

##--- pod -> txt
.SUFFIXES: .txt

POD2TEXT ?= pod2text

INST_TEXTDIR ?= blib/txt
TEXT_EXT ?= txt
TEXT1EXT ?= $(TEXT_EXT)
TEXT3EXT ?= $(TEXT_EXT)

##-- lifted from MakeMaker blibdir section
$(INST_TEXTDIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_TEXTDIR)
	$(NOECHO) $(CHMOD) 755 $(INST_TEXTDIR)
	$(NOECHO) $(TOUCH) $(INST_TEXTDIR)$(DFSEP).exists

';
  ($deps,$rules) = ($deps0,$rules0);
  $deps =~ s/^manifypods\b/textifypods/;
  $deps .= "\\\n\t".'$(INST_TEXTDIR)$(DFSEP).exists';
  $rules =~ s/POD2MAN/POD2TEXT/g;
  $rules =~ s/MAN(\d)EXT/TEXT$1EXT/g;
  $rules =~ s/INST_MAN\dDIR/INST_TEXTDIR/g;
  $rules =~ s/^\s+\$\(NOECHO\).*?\n//smg;
  $rules =~ s/::/${text_ns_sep}/sg if ($text_ns_sep ne '::');
  $rules =~ s/\\\n/\n/sg;
  $rules =~ s/\t\s+(\S+)\s+(\S+)/\t\$(POD2TEXT) $1 $2/sg;
  $rules .= "\n\ntxtifypods: textifypods\n\n";
  $out .= $textvars.$deps."\n".$rules."\n\n";

  ##-----------------------
  ## pod
  my $pod_ns_sep = $html_ns_sep;
  my $podvars ='

##--- pod+perl -> pod

.SUFFIXES: .pod

POD2POD ?= podselect -section ""

INST_PODDIR ?= blib/pod
POD_EXT ?= pod
POD1EXT ?= $(POD_EXT)
POD3EXT ?= $(POD_EXT)

##-- lifted from MakeMaker blibdir section
$(INST_PODDIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_PODDIR)
	$(NOECHO) $(CHMOD) 755 $(INST_PODDIR)
	$(NOECHO) $(TOUCH) $(INST_PODDIR)$(DFSEP).exists

';
  ($deps,$rules) = ($deps0,$rules0);
  $deps =~ s/^manifypods\b/podifypods/;
  $deps .= "\\\n\t".'$(INST_PODDIR)$(DFSEP).exists';
  $rules =~ s/POD2MAN/POD2POD/g;
  $rules =~ s/MAN(\d)EXT/POD$1EXT/g;
  $rules =~ s/INST_MAN\dDIR/INST_PODDIR/g;
  $rules =~ s/^\s+\$\(NOECHO\).*?\n//smg;
  $rules =~ s/::/${pod_ns_sep}/sg if ($pod_ns_sep ne '::');
  $rules =~ s/\\\n/\n/sg;
  $rules =~ s/\t\s+(\S+)\s+(\S+)/\t\$(POD2POD) $1 > $2/sg;
  $out .= $podvars.$deps."\n".$rules."\n\n";

  ##-- return
  return $out;
}

##---------------------------------------------------------------
sub MY::distdir {
  package MY;
  my $inherited = shift->SUPER::distdir(@_);
  my $local =
'
##-- distdir_am: hacked create_distdir for superordinate automake
DISTDIR_AM ?= $(DISTNAME).am
distdir_am:
	$(RM_RF) $(DISTDIR_AM)
	$(PERLRUN) "-MExtUtils::Manifest=manicopy,maniread" \\
	  -e "manicopy(maniread(),\'$(DISTDIR_AM)\', \'$(DIST_CP)\');"

PMLIST_AM ?= ../doc/pm_list
pm_list: $(PMLIST_AM)
$(PMLIST_AM): $(TO_INST_PM)
	echo "$(TO_INST_PM)" | xargs -n 1 echo | grep -v "\.in$$" > $@
';
  return $inherited.$local;
}

##---------------------------------------------------------------
sub MY::postamble {
  package MY;
  my $inherited = shift->SUPER::postamble(@_);
  return $inherited;
}
