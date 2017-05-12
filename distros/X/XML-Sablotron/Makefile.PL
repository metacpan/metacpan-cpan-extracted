#
# The contents of this file are subject to the Mozilla Public
# License Version 1.1 (the "License"); you may not use this file
# except in compliance with the License. You may obtain a copy of
# the License at http://www.mozilla.org/MPL/
# 
# Software distributed under the License is distributed on an "AS
# IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
# implied. See the License for the specific language governing
# rights and limitations under the License.
# 
# The Original Code is the XML::Sablotron module.
# 
# The Initial Developer of the Original Code is Ginger Alliance Ltd.
# Portions created by Ginger Alliance are 
# Copyright (C) 1999-2000 Ginger Alliance Ltd. 
# All Rights Reserved.
# 
# Contributor(s): o Matt Sergeant
#                 o Nicolas Trebst, science+computing ag
#                   n.trebst@science-computing.de
# 
# Alternatively, the contents of this file may be used under the
# terms of the GNU General Public License Version 2 or later (the
# "GPL"), in which case the provisions of the GPL are applicable 
# instead of those above.  If you wish to allow use of your 
# version of this file only under the terms of the GPL and not to
# allow others to use your version of this file under the MPL,
# indicate your decision by deleting the provisions above and
# replace them with the notice and other provisions required by
# the GPL.  If you do not delete the provisions above, a recipient
# may use your version of this file under either the MPL or the
# GPL.
# 

use ExtUtils::MakeMaker;
use English;
use Config;
use strict;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $expat_libpath = '';
my $expat_incpath = '';

my @replacement_args;


foreach (@ARGV) {
  if (/^EXPAT(LIB|INC)PATH=(.+)/) {
    if ($1 eq 'LIB') {
      $expat_libpath = $2;
    }
    else {
      $expat_incpath = $2;
    }
  }
  else {
    push(@replacement_args, $_);
  }
}

@ARGV = @replacement_args;

unless ($expat_libpath) {
  # Test for existence of libexpat
  my $found = 0;
 if ($] >= 5.008001) {
    require ExtUtils::Liblist;		# Buggy before this
    my ($list) = ExtUtils::Liblist->ext('-lexpat');
    $found = 1 if $list =~ /-lexpat\b/;
 } else {
  foreach (split(/\s+/, $Config{libpth})) {
    if (-f "$_/libexpat." . $Config{so}) {
      $found = 1;
      last;
    }
  }
 }

  unless ($found) {
      die <<'Expat_Not_Installed;';

Expat must be installed prior to building XML::Sablotron and I can't find #'
it in the standard library directories. You can download expat from:

http://sourceforge.net/projects/expat/

If expat is installed, but in a non-standard directory, then use the
following options to Makefile.PL:

    EXPATLIBPATH=...  To set the directory in which to find libexpat

For example:

    perl Makefile.PL EXPATLIBPATH=/home/me/lib EXPATINCPATH=/home/me/include

Note that if you build against a shareable library in a non-standard location
you may (on some platforms) also have to set your LD_LIBRARY_PATH environment
variable at run time for perl to find the library.

Expat_Not_Installed;
  }
}

#the same thing for sablotron
my $sablot_libpath = '';
my $sablot_incpath = '';

@replacement_args = ();

foreach (@ARGV) {
  if (/^SABLOT(LIB|INC)PATH=(.+)/) {
    if ($1 eq 'LIB') {
      $sablot_libpath = $2;
    }
    else {
      $sablot_incpath = $2;
    }
  }
  else {
    push(@replacement_args, $_);
  }
}

@ARGV = @replacement_args;

unless ($sablot_libpath) {
  # Test for existence of libexpat
  my $found = 0;
 if ($] >= 5.008001) {
    require ExtUtils::Liblist;		# Buggy before this
    my ($list) = ExtUtils::Liblist->ext('-lsablot');
    $found = 1 if $list =~ /-lsablot\b/;
 } else {
  foreach (split(/\s+/, $Config{libpth})) {
    if (-f "$_/libsablot." . $Config{so}) {
      $found = 1;
      last;
    }
  }
 }

  unless ($found) {
    die <<'Sablot_Not_Installed;';

Sablot must be installed prior to building XML::Sablotron and I can't find #'
it in the standard library directories. You can download Sablotron from:

http://www.gingerall.cz

If Sablotron is installed, but in a non-standard directory, then use the
following options to Makefile.PL:

    SABLOTLIBPATH=...  To set the directory in which to find libexpat

    SABLOTINCPATH=...  To set the directory in which to find expat.h

For example:

    perl Makefile.PL SABLOTLIBPATH=/home/me/lib SABLOTINCPATH=/home/me/include

Note that if you build against a shareable library in a non-standard location
you may (on some platforms) also have to set your LD_LIBRARY_PATH environment
variable at run time for perl to find the library.

Sablot_Not_Installed;
  }
}

#linking javascript
@replacement_args = ();
my ($js_libpath, $js_libname);
foreach (@ARGV) {
    if (/^JSLIB(PATH|NAME)=(.+)/) {
	if ($1 eq 'PATH') {
	    $js_libpath = $2;
	} else {
	    $js_libname = $2;
	}
    } else {
	push @replacement_args, $_;
    }
}
@ARGV = @replacement_args;

$js_libname = 'js' unless $js_libname;

my $js_found = undef;
unless ($js_libpath) {
    # Test for existence of libexpat
 if ($] >= 5.008001) {
    require ExtUtils::Liblist;		# Buggy before this
    my ($list) = ExtUtils::Liblist->ext("-l$js_libname");
    $js_found = 1 if $list =~ /-l\Q$js_libname\E\b/;
 } else {
    foreach (split(/\s+/, $Config{libpth})) {
	if (-f "$_/lib$js_libname." . $Config{so}) {
	    $js_found = 1;
	    last;
	}
    }
 }
}

our $libs = ' ';

if ($js_found || $js_libpath) {
    $libs = "-l$js_libname $libs" if $js_libname;
    $libs = "-L$js_libpath $libs" if $js_libpath;
}

#sablot and expat libraries
$libs = "-lsablot -lexpat $libs";
unless ($^O eq 'MSWin32') {
    $libs = "$libs -lm";
}

$libs = "-L$expat_libpath $libs"
  if $expat_libpath;
$libs = "-L$sablot_libpath $libs"
  if $sablot_libpath;

my $inc = "-I$expat_incpath"
  if $expat_incpath;
$inc = "-I$sablot_incpath $inc"
  if $sablot_incpath;

our @extras;
push(@extras, INC => $inc) if $inc;

push(@extras, CAPI => 'TRUE')
    if ($PERL_VERSION >= 5.005 and $OSNAME eq 'MSWin32');

#analyze the ramining args
@replacement_args = ();
foreach (@ARGV) {
    if (/^LIBS=(.*)/) {
	$libs .= " $1";
    } else {
	push @replacement_args, $_;
    }
}
@ARGV = @replacement_args;

my $O_FILES = "common$Config{obj_ext}";

WriteMakefile(
	      NAME	=> 'XML::Sablotron',
	      AUTHOR    => 'Pavel Hlavnicka (pavel@gingerall.cz)',
	      ABSTRACT  => 'Sablotron XSLT processor wrapper',
	      VERSION_FROM => 'Sablotron.pm', 
	      DEFINE	=> '-DPERL_POLLUTE',
	      clean     => {'FILES' => "log.xsl", },
	      dist	=> {COMPRESS => 'gzip', SUFFIX => 'tar.gz'},
	      DIR       => [qw( DOM Situation SXP Processor )],
	      LIBS      => $libs, 
	      OBJECT	=> q( $(O_FILES) ),
#              OPTIMIZE  => ' ',
#     CCFLAGS => '-g',
	      depend => { 'Sablotron.c' => q(DOM/DOM.h DOM/DOM.xsh Processor/Processor.h Processor/Processor.xsh Processor/Handler_stubs.h SXP/SXP.h SXP/SXP.xsh Situation/Situation.h Situation/Situation.xsh Situation/DOMhandler_stubs.h ) },
	      @extras,
);


__END__

