#!/usr/bin/perl -w

# Copyright 2011, 2012, 2014 Kevin Ryde

# This file is part of Test-VariousBits.
#
# Test-VariousBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Test-VariousBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Test-VariousBits.  If not, see <http://www.gnu.org/licenses/>.

use strict;

# uncomment this to run the ### lines
use Smart::Comments;

my $verbose = 0;
my $ignore_alpha_version_gt = 1;
my $warning_count;
my $stacktraces;
my $stacktraces_count = 0;

sub import {
  my $class = shift;
  foreach my $arg (@_) {
    if ($arg eq '-verbose') {
      $verbose++;
    } else {
      diag("WarnFail unrecognised option: ",$arg);
    }
  }
  $class->install;
}
sub unimport {
  my ($class) = @_;
  $class->uninstall;
}

my $installed = 0;
my $old_warn_handler;

sub install {
  my ($class) = @_;
  if (! $installed) {
    $installed = 1;
    if ($verbose) {
      $class->diag("WarnFail: install __WARN__ handler");
    }
    $old_warn_handler = $SIG{'__WARN__'};
    $SIG{'__WARN__'} = $class->can('warn_handler');
  }
}

sub uninstall {
  my ($class) = @_;
  if ($installed) {
    $installed = 0;

    if (defined $SIG{'__WARN__'}
        && $SIG{'__WARN__'} == $class->can('warn_handler')) {
      if ($verbose) {
        $class->diag("WarnFail restore __WARN__ handler");
      }
      $SIG{'__WARN__'} = $old_warn_handler;
    } else {
      if ($verbose) {
        $class->diag("WarnFail \$SIG{__WARN__} has changed again, cannot restore");
      }
    }
  }
}

sub warn_handler {
  my ($msg) = @_;
  # don't error out for cpan alpha version number warnings
  unless ($ignore_alpha_version_gt
          && defined $msg
          && $msg =~ /^Argument "[0-9._]+" isn't numeric in numeric gt/) {
    $warning_count++;
    if ($stacktraces_count < 3 && eval { require Devel::StackTrace }) {
      $stacktraces_count++;
      $stacktraces .= "\n" . Devel::StackTrace->new->as_string() . "\n";
    }
  }
  if ($old_warn_handler) {
    goto &$old_warn_handler;
  } else {
    warn @_;
  }
}

END {
  __PACKAGE__->end;
}
sub end {
  my ($class) = @_;

  if ($warning_count) {
    $class->diag("Saw $warning_count warning(s):");
    if (defined $stacktraces) {
      $class->diag($stacktraces);
    } else {
      $class->diag('(no backtrace, Devel::StackTrace not available)');
    }
    $class->diag('Exit code 1 for warnings');
    $? ||= 1;

    $warning_count = 0;
    undef $stacktraces;
  }
}

# diag($str, $str, ...)
sub diag {
  if (eval { Test::More->can('diag') }) {
    Test::More::diag (@_);
  } else {
    my $msg = join('', map {defined($_)?$_:'[undef]'} @_)."\n";
    $msg =~ s/^/# /mg;
    print STDERR $msg;
  }
}

1;
__END__
