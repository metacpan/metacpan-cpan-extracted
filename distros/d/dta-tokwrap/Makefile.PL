#!/usr/bin/perl
use Config;
use ExtUtils::MakeMaker;
use 5.010; ##-- in case old EU::MM doesn't grok MIN_PERL_VERSION
use strict;
use utf8;

##----------------------------------------------------------------------
## sanity checks
BEGIN {
  die("OS $^O not supported") if ($^O =~ /win32/i);
}

##-- always re-generate MYMETA.*
foreach my $f (qw(META.yml META.json MYMETA.yml MYMETA.json)) {
  (!-e $f)
    or unlink($f)
    or warn("$0: WARNING: failed to unlink $f: $!");
}

##-- workaround for irritating "/some/symlinked/file is encountered a second time at File/Find.pm line 79." errors
##   under ExtUtils::MakeMaker 7.1002 (see also RT bug #99018)
#*ExtUtils::MakeMaker::_check_files = sub {};
#*ExtUtils::MakeMaker::check_manifest = sub {};
do "./find.hack" if (-e "./find.hack");


##----------------------------------------------------------------------
## dummy MakeMaker
WriteMakefile
  (
   NAME		=> 'DTA::TokWrap',
   DISTNAME     => 'dta-tokwrap',
   AUTHOR       => 'Bryan Jurish <moocow@cpan.org>',
   ABSTRACT	=> 'Utility suite for DTA-style XML corpus tokenization',
   VERSION_FROM	=> 'DTA-TokWrap/TokWrap/Version.pm',
   LICENSE      => 'perl_5',
   MIN_PERL_VERSION => 5.010, ##-- v5.10.0

   PREREQ_PM    => {
		    'XML::Parser' => 0,
		    'XML::LibXML' => 0,
		    'XML::LibXSLT' => 0,
		    'Encode'=>0,
		    'Time::HiRes'=>1.9711,
		    'Getopt::Long'=>0,
		    'Pod::Usage'=>0,
		    'Env::Path' =>0.18,
		    'File::Basename'=>0,
		    'Cwd'=>0,
		    'Log::Log4perl'=>1.20,
		    'Algorithm::BinarySearch::Vec'=>0.05, ##-- only really required for for dtatw-get-ddc-attrs.perl
		    ##
		    'Test::More'=>0,
		   },

   ##-- don't let EU::MM recurse -- let automake handle the actual build
   DIR => [],
  );
rename("Makefile","Makefile_mm")
  or warn("$0: WARNING: failed to rename ExtUtils::MakeMaker's Makefile to Makefile_mm: $!");


##----------------------------------------------------------------------
## autoconf-style configure (also creates DTA-TokWrap/TokWrap/Version.pm)

##-- avoid heinous errors if running a non-standard perl
## - example http://www.cpantesters.org/cpan/report/ae09febc-353f-11e9-a0cc-de79a423f08d
## - thanks to Slaven Rezić for spotting the problem
$ENV{PERL}      = $^X;

##-- shamelessly lift compiler flags used for perl itself
## - this gets us e.g. -I/usr/local/include on freebsd
$ENV{CPPFLAGS} .= " ".$Config{cppflags};
$ENV{LDFLAGS}  .= " ".$Config{ldflags};

##-- guts
-e "./configure"
  or system(qw(autoreconf --install --verbose --force .))==0
  or die("$0: ERROR: autoreconf failed: $!");
system(qw(sh ./configure --disable-doc),@ARGV)==0
  or die("$0: ERROR: autotools ./configure failed: $!");
