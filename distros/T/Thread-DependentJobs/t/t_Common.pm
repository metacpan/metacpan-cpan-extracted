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
my %defaults;
BEGIN {
  $defaults{'${^WARNING_BITS}'} = ${^WARNING_BITS}//"u";
  $defaults{'$^H'} = $^H//"u";
  $defaults{'%^H'} = hash2str(\%^H);
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

# oops, btw, etc. are simplified versions of the same-named subs
# in Spreadsheet::Edit::Log . They are *not* exported by default to
# avoid conflict if the real Spreadsheet::Edit::Log has been imported.
# (FUTURE: If Spreadsheet::Edit::Log is split into a stand-alone module,
# we could just use it; but I don't want to drag all of Spreadsheet::Edit
# in just for these few functions)

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
    for my $var ('${^WARNING_BITS}', '$^H', '%^H') {
      my $r = eval "\\$var" // die;
      my $curr = ref($r) eq "SCALAR" ? ($$r//"u") :
                 ref($r) eq "HASH"   ? hash2str($r) : oops;
      if ($curr ne $defaults{$var}) {
        carp "$var was set by an earlier pragma before importing ", __PACKAGE__,
             " (might now be un-done)\n"
      }
    }
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

  use Path::Tiny 0.146 ();
  Path::Tiny->import::into($target, qw/path/);

  require List::AllUtils;
  List::AllUtils->import::into($target,
    qw/reduce min max first firstidx any all none sum0/);


  require Scalar::Util;
  Scalar::Util->import::into($target, qw/blessed reftype looks_like_number
                                         weaken isweak refaddr/);

  require Cwd;
  Cwd->import::into($target, qw/getcwd abs_path fastgetcwd fast_abs_path/);

  require Guard;
  Guard->import::into($target, qw(scope_guard guard));

  use Data::Dumper::Interp 7.012 ();
#OTOH, we _do_ want show stringified value of things like Path::Tiny
#  unless (Cwd::abs_path(__FILE__) =~ /Data-Dumper-Interp/) {
#    # Unless we are testing DDI
#    no warnings 'once';
#    # Don't follow overloads e.g. stringify
#    $Data::Dumper::Interp::Objects = {overloads => "ignore"};
#  }

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
