#!perl
# -*- mode: cperl ; compile-command: "cd .. ; ./Build ; prove -vb t/08-*.t" -*-
use strict;
use warnings;

use Config;

my $code  = '';
my $flags = '';

# Thank you, http://search.cpan.org/src/DAGOLDEN/Class-InsideOut-1.02/t/05_forking.t

# If Win32, fork() is done with threads, so we need various things
if ( $^O =~ /^(?:MSWin32|NetWare|WinCE)\z/ ) {

  $code .= <<'COVERAGE';
# don't run this at all under Devel::Cover
if ( $ENV{HARNESS_PERL_SWITCHES} &&
     $ENV{HARNESS_PERL_SWITCHES} =~ /Devel::Cover/ ) {
  plan skip_all => 'Devel::Cover not compatible with Win32 pseudo-fork';
}
COVERAGE

  # skip if threads not available for some reasons
  if ( ! $Config{useithreads} ) {
    $code .= <<NOTHREADS;
plan skip_all => "Win32 fork() support requires threads";
NOTHREADS
  }

  # skip if perl < 5.8
  if ( $] < 5.008 ) {
    $code .= <<NOTHREADS;
plan skip_all => "Win32 fork() support requires perl 5.8";
NOTHREADS
  }
}
elsif (!$Config{d_fork}) {
  $code .= <<NOFORK;
plan skip_all => 'Fork tests are irrelevant without fork()';
NOFORK
}
else {
  $flags = ' -T';
  $code .= <<DIAG
BEGIN {
  diag('Real fork; taint checks enabled');
}
DIAG
}

(my $file = __FILE__) =~ s/\.PL$/.t/;
open my $fh, '>', $file or die "Cannot open '$file': '$!'";

print $fh "#!perl$flags\n", <<'CODA', $code;
# -*- mode: cperl ; compile-command: "cd .. ; ./Build ; prove -vb t/08-*.t" -*-;

BEGIN { $_ = defined && /(.*)/ && $1 for @ENV{qw/ TMPDIR TEMP TMP /} } # taint vs tempfile
use Test::More tests => 15;
use strict;
use warnings;

CODA

print $fh <DATA>;

exit 0;

__DATA__

my $flag;
BEGIN {
  *CORE::GLOBAL::exit = sub(;$) {
    if ($flag) {
      pass("The final test: The outer CORE::GLOBAL::exit is eventually called");
    }
    else {
      fail("The outer CORE::GLOBAL::exit is called too soon!");
    }
    CORE::exit(@_ ? shift : 0);
  };
}

BEGIN {
  use_ok( 'Test::Trap' );
}

# check that the setup works -- the exit is still trapped:
trap { exit };
is( $trap->exit, 0, "Trapped the first exit");

# check that the exit from the forked-off process reverts to the inner
# CORE::GLOBAL::exit, not the outer
trap {
  *CORE::GLOBAL::exit = sub(;$) {
    pass("The inner CORE::GLOBAL::exit is called from the child");
    CORE::exit(@_ ? shift : 0);
  };
  trap {
    fork;
    exit;
  };
  wait; # let the child finish first
  # Increment the counter correctly ...
  my $Test = Test::More->builder;
  $Test->current_test( $Test->current_test + 1 );
  is( $trap->exit, 0, "Trapped the inner exit");
};
like( $trap->stderr, qr/^Subroutine (?:CORE::GLOBAL::)?exit \Qredefined at ${\__FILE__} line/, 'Override warning' );

trap {
  trap{
    trap {
      fork;
      exit;
    };
    wait;
    is( $trap->exit, 0, "Trapped the inner exit" );
  }
};
is( $trap->leaveby, 'return', 'Should return just once, okay?' );

# Output from forked-off processes?
my $me;
trap {
  $me = fork ? 'parent' : 'child';
  print "\u$me print\n";
  warn "\u$me warning\n";
  wait, exit $$ if $me eq 'parent';
};
CORE::exit(0) if $me eq 'child';
is( $trap->exit, $$, "Trapped the parent exit" );
like( $trap->stdout, qr/^(Parent print\nChild print\n|Child print\nParent print\n)/, 'STDOUT from both processes!' );
like( $trap->stderr, qr/^(Parent warning\nChild warning\n|Child warning\nParent warning\n)/, 'STDERR from both processes!' );
is_deeply( $trap->warn, ["Parent warning\n"], 'Warnings from the parent only' );

# STDERR from forked-off processes, with a closed STDIN & STDOUT?
trap {
  close STDOUT;
  trap {
    my $me = fork ? 'parent' : 'child';
    print "\u$me print\n";
    warn "\u$me warning\n";
    wait, exit $$ if $me eq 'parent';
    CORE::exit(0);
  };
  is( $trap->exit, $$, "Trapped the parent exit" );
  is( $trap->stdout, '', 'STDOUT from both processes is nil -- the handle is closed!' );
  like( $trap->stderr, qr/\A(?=.*^Parent warning$)(?=.*^Child warning$)/ms, 'STDERR from both processes!' );
};

$flag++; # the exit test will now pass -- in the forked-off processes it will fail!
exit;
