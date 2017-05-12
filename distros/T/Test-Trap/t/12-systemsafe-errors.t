#!perl -T
# -*- mode: cperl ; compile-command: "cd .. ; ./Build ; prove -vb t/12-*.t" -*-

BEGIN { $_ = defined && /(.*)/ && $1 for @ENV{qw/ TMPDIR TEMP TMP /} } # taint vs tempfile
use Test::More tests => 10;
use strict;
use warnings;

# A whole lot simpler testing -- we're now just checking that all the
# error situations are caught and behave sensibly.  Okay, it's not
# that simple -- just simpler than the implementation ...

my $errnum = 11; # "Resource temporarily unavailable" locally -- sounds good :-P
my $errstring = do { local $! = $errnum; "$!" };

{
  my $fileno = fileno STDIN;
  die "STDIN not on fd 0"
    unless defined $fileno and $fileno == 0;
};

our ($when_to_fail, $when_to_persist);
my ($glob, $mode, @what);
BEGIN {
  # make the open calls in SystemSafe.pm fail or just fdopen STDIN in
  # different situations:
  *Test::Trap::Builder::SystemSafe::open = # silence warnings
  *Test::Trap::Builder::SystemSafe::open = sub (*;$@) {
    ($glob, $mode, @what) = @_;
    unless (@what) {
      ($mode, @what) = $mode =~ /^([>&=]*)\s*(.*)/s;
    }
    if ($when_to_persist and $when_to_persist->()) {
      eval { open $_[0], '<&=STDIN' } or CORE::exit diag "Cannot fdopen STDIN; STDIN fd: ". fileno STDIN;
      for (fileno $_[0]) {
	defined or CORE::exit diag "fdopen STDIN gives undefined fd";
	$_ == 0 or CORE::exit diag "fdopen STDIN gives fd $_";
      }
      return 1;
    }
    if ($when_to_fail and $when_to_fail->()) {
      $! = $errnum;
      return;
    }
    my $return;
    if (@_ > 2) {
      $return = open $_[0], $_[1], @_[2..$#_];
    }
    elsif (defined $_[0]){
      $return = open $_[0], $_[1];
    }
    else {
      $return = open my $fh, $_[1];
      $_[0] = $fh;
    }
    return $return;
  };
}

use Test::Trap::Builder::SystemSafe;
use Test::Trap qw( trap $T :flow:stderr(systemsafe):stdout(systemsafe):warn );
use Test::Trap qw( protect $P );

SKIP: {
  skip 'These tests are broken on old perls', 3 if $] < 5.008;

  protect { # return fd 0 again and again on appending
    local $when_to_persist = sub { $mode eq '>>' };
    eval { trap { 1 } };
    like( $@, qr/^\QGetting several files opened on fileno 0 at ${\__FILE__}/, 'Persisting on STDIN' );
  };

  protect { # return fd 0 once(!) on appending
    my $count = 1;
    local $when_to_persist = sub { $mode eq '>>' and !--$count };
    eval { trap { 1 } };
    like( $@, qr/^Getting fileno \d+; \Qexpecting 0 at ${\__FILE__}/, "Mixed-up filenos" );
  };

  protect { # return fd 0 once(!) on appending -- then fail!
    my $count = 1;
    local $when_to_persist = sub { $mode eq '>>' and !--$count };
    local $when_to_fail = sub { $mode eq '>>' and $count == -1 };
    eval { trap { 1 } };
    like( $@, qr/^Cannot open \S+ \Qfor stdout: '$errstring' at ${\__FILE__}/, 'Delayed append to tempfile' );
  };
}

protect { # fail on the first dup() -- stdout, coming in
  my $count = 1;
  local $when_to_fail = sub { $mode eq '>&' and !--$count };
  eval { trap { 1 } };
  like( $@, qr/^Cannot dup '\d+' \Qfor stdout: '$errstring' at ${\__FILE__}/, 'First dup() -- setting up STDOUT' );
};

protect { # fail on the second dup() -- stderr, coming in
  my $count = 2;
  local $when_to_fail = sub { $mode eq '>&' and !--$count }; # second dup()
  eval { trap { 1 } };
  like( $@, qr/^Cannot dup '\d+' \Qfor stderr: '$errstring' at ${\__FILE__}/, 'Second dup() -- setting up STDERR' );
};

protect { # fail on the third dup() -- stderr, going out
  my $count = 3;
  local $when_to_fail = sub { $mode eq '>&' and !--$count };
  eval { trap { 1 } };
  like( $@, qr/^Cannot dup '\d+' \Qfor stderr: '$errstring' at ${\__FILE__}/, 'Third dup() -- restoring STDERR' );
};

protect { # fourth dup() -- stdout, going out
  my $count = 4;
  local $when_to_fail = sub { $mode eq '>&' and !--$count };
  eval { trap { 1 } };
  like( $@, qr/^Cannot dup '\d+' \Qfor stdout: '$errstring' at ${\__FILE__}/, 'Fourth dup() -- restoring STDOUT' );
};

protect { # fail on first opening the stderr tempfile for append
  my $count = 1;
  local $when_to_fail = sub { $mode eq '>>' and !--$count };
  eval { trap { 1 } };
  like( $@, qr/^Cannot open \S+ \Qfor stdout: '$errstring' at ${\__FILE__}/, 'First append to tempfile' );
};

SKIP: {
  protect {
    skip 'Need PerlIO', 1 unless eval 'use PerlIO; 1';
    local *STDOUT;
    open STDOUT, '>', \ my $buffer;
    eval { trap { 1 } };
    like( $@, qr/^\QSystemSafe only works with real file descriptors; aborting at ${\__FILE__}/, 'Negative fileno' );
  };
}

SKIP: {
  protect {
    skip 'Need IO::Scalar', 1 unless eval 'use IO::Scalar; 1';
    local *STDOUT;
    tie *STDOUT, 'IO::Scalar', \my $s;
    eval { trap { 1 } };
    like( $@, qr/^\QSystemSafe only works with real file descriptors; aborting at ${\__FILE__}/, 'Tied handle' );
  };
}
