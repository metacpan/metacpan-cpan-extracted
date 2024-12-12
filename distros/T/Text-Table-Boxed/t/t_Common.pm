# License: Public Domain or CC0
# See https://creativecommons.org/publicdomain/zero/1.0/
# The author, Jim Avera (jim.avera at gmail) has waived all copyright and
# related or neighboring rights to the content of this file.
# Attribution is requested but is not required.
#
# PLEASE NOTE that the above applies to THIS FILE ONLY.  Other files in the
# same distribution or in other collections may have more restrictive terms.

# Common setup stuff, not specifically for test cases.
# This file is intended to be identical in all my module distributions.

package t_Common;

sub hash2str($) { my $h=shift; join("",map{" ${_}=>".($h->{$_}//"u")} sort keys %$h) }
my ($default_warnbits, $default_pragmas);
BEGIN {
  $default_warnbits = ${^WARNING_BITS}//"u";
  $default_pragmas = ($^H//"u").":".hash2str(\%^H);
}

use strict;

# Do not fatalize decode warnings (under category 'utf8') because various smokers
# can have restrictive stdout encodings.
use warnings  FATAL => 'all';
use warnings  NONFATAL => qw(
        utf8
        exec
        recursion
        internal
        malloc
        newline
        experimental
        deprecated
        portable
      );
#no warnings "once";

use feature qw/say state/;

require Exporter;
use parent 'Exporter';
our @EXPORT = qw/mytempfile mytempdir/;
our @EXPORT_OK = qw/oops btw btwN/;

use Import::Into;
use Carp;

sub oops(@) {
  my $pkg = caller;
  my $pfx = "\noops";
  $pfx .= " in pkg '$pkg'" unless $pkg eq 'main';
  $pfx .= ":\n";
  if (defined(&Spreadsheet::Edit::logmsg)) {
    # Show current apply sheet & row if any.
    @_=($pfx, &Spreadsheet::Edit::logmsg(@_));
  } else {
    @_=($pfx, @_);
  }
  push @_,"\n" unless $_[-1] =~ /\R\z/;
  goto &Carp::confess
}

# "By The Way" messages showing file:linenum of the call
sub btw(@) { unshift @_,0; goto &btwN }
sub btwN($@) {
  my $N=shift;
  my ($fn, $lno) = (caller($N))[1,2];
  $fn =~ s/.*[\\\/]//;
  $fn =~ s/(.)\.[a-z]+$/$1/a;
  local $_ = join("",@_);
  s/\n\z//s;
  printf STDERR "%s:%d: %s\n", $fn, $lno, $_;
}

sub import {
  my $target = caller;

  state $imported_previously;
  unless ($imported_previously++) {
    # It seems like test cases using Test::More are re-started from
    # the beginning when Test::More is first loaded, and at that point
    # some non-default pragma is in effect.  I can't figure any other
    # reason why we would be imported twice, with non-default settings
    # the 2nd time.

    # Check that the user did not already say "no warnings ..." or somesuch
    # I was previously confused about how to do this,
    # see https://rt.cpan.org/Ticket/Display.html?id=147618
    my $users_warnbits = ${^WARNING_BITS}//"u";
    my $users_pragmas = ($^H//"u").":".hash2str(\%^H);
    carp "Detected 'use/no warnings/strict' done before importing ",
          __PACKAGE__, "\n(they might be un-done)\n"
      if ($users_pragmas ne $default_pragmas
            || $users_warnbits ne $default_warnbits);
  }
  strict->import::into($target);
  #warnings->import::into($target);
  warnings->import::into($target, FATAL => 'all'); # blowing up a test is ok

  #As of perl 5.39.8 multiple 'use' specifying Perl version is deprecated
  #use 5.010;  # say, state
  #use 5.011;  # cpantester gets warning that 5.11 is the minimum acceptable
  use 5.018;  # lexical_subs
  require feature;
  # Perl 5.18.0 seems to require the "no experimental..." before the "use feature"
  warnings->unimport::out_of($target, "experimental::lexical_subs");
  feature->import::into($target, qw/state say current_sub lexical_subs fc/);

  # die if obsolete or dangerous syntax is used
  require indirect;
  indirect->unimport::out_of($target);

  require multidimensional;
  multidimensional->unimport::out_of($target);

  require autovivification;
  # A bug makes
  #   "no autovivification warn anything..." wrongly flag
  #   "my %hash; delete $hash{nonexistentkey}"
  # This happens with Perl 5.24.0 and autovivification v0.18
  # but not with Perl5.34.0 and same autovivification.
  # So just disable autoviv but don't enable warnings...
  autovivification->unimport::out_of($target, qw/fetch store exists delete/);

  # Avoid regex performance penalty in Perl <= 5.18 if
  # $PREMATCH $MATCH or $POSTMATCH are imported (fixed in perl 5.20).
  require English;
  English->import::into($target, '-no_match_vars' );

  # Stuff I often use

  require utf8;
  utf8->import::into($target);

  require Carp;
  Carp->import::into($target);

  require File::Basename;
  File::Basename->import::into($target, qw/basename dirname/);

  require File::Path;
  File::Path->import::into($target, qw/make_path rmtree/);

  require File::Spec;
  require File::Spec::Functions;
  # Do *not* import 'devnull' as it doesn't really work on Windows,
  # at least not as the input to File::Copy::copy (fails with "No such file")
  File::Spec::Functions->import::into($target, qw/
    canonpath catdir catfile curdir rootdir updir
    no_upwards file_name_is_absolute tmpdir splitpath splitdir
    abs2rel rel2abs case_tolerant/);

  require Path::Tiny;
  Path::Tiny->import::into($target, qw/path/);

  require List::Util;
  List::Util->import::into($target, qw/reduce min max first any all none sum0/);



  require Scalar::Util;
  Scalar::Util->import::into($target, qw/blessed reftype looks_like_number
                                         weaken isweak refaddr/);

  require Cwd;
  Cwd->import::into($target, qw/getcwd abs_path fastgetcwd fast_abs_path/);

  require Guard;
  Guard->import::into($target, qw(scope_guard guard));

  use Data::Dumper::Interp 6.006 ();
  unless (Cwd::abs_path(__FILE__) =~ /Data-Dumper-Interp/) {
    # unless we are testing DDI
    Data::Dumper::Interp->import::into($target,
                                       qw/:DEFAULT rdvis rvis addrvis_digits/);
    $Data::Dumper::Interp::Useqq = 'unicode'; # omit 'controlpic' to get \t etc.
  }

  # chain to Exporter to export any other importable items
  goto &Exporter::import
}

use File::Temp 0.23 ();

sub mytempfile { ##DEPRECATED
  Path::Tiny->tempfile(@_); # does everything we used to do
}
sub mytempdir {  ##DEPRECATED
  Path::Tiny->tempdir(@_); # does everything we used to do
}

# prevent direct use of File::Temp with it's confusing arguments
# by exporting these conflicting stubs
sub tempfile { confess "use Path::Tiny->tempfile(...) instead" }
sub tempdir  { confess "use Path::Tiny->tempdir(...) instead" }

1;
