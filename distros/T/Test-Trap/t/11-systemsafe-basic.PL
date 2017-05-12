#!perl
# -*- mode: cperl ; compile-command: "cd .. ; ./Build ; prove -vb t/11-*.t" -*-
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
# -*- mode: cperl ; compile-command: "cd .. ; ./Build ; prove -vb t/11-*.t" -*-;

BEGIN { $_ = defined && /(.*)/ && $1 for @ENV{qw/ TMPDIR TEMP TMP /} } # taint vs tempfile
use Test::More;
use strict;
use warnings;

CODA

print $fh <DATA>;

exit 0;

__DATA__

use File::Temp qw( tempfile );

use Test::Trap::Builder::SystemSafe;

use Test::Trap qw( trap $T :flow:stderr(systemsafe):stdout(systemsafe):warn );

BEGIN {
  # silence some warnings that make coverage reports hard to get at
  if ($Storable::VERSION) {
    eval {
      eval { no warnings; Storable::retrieve('.') }; # silly, but hopefully safe ...
      my $_r = \&Storable::_retrieve;
      no warnings 'redefine';
      *Storable::_retrieve = sub {
	no warnings;
	local $SIG{__WARN__} = sub {};
	$_r->(@_);
      };
    };
  }
  if ($Devel::Cover::DB::Structure::VERSION) {
    eval {
      my $d = \&Devel::Cover::DB::Structure::digest;
      no warnings 'redefine';
      *Devel::Cover::DB::Structure::digest = sub {
	no warnings;
	local $SIG{__WARN__} = sub {};
	$d->(@_);
      };
    };
  }
}

# Protect against tainted PATH &c ...
$ENV{PATH} = '';
$ENV{CDPATH} = '';
$ENV{ENV} = '';
$ENV{BASH_ENV} = '';

my ($PERL) = $^X =~ /^([\w.\/:\\~-]+)$/;
if ($PERL) {
  plan tests => 3 + 6*6 + 4;
}
else {
  plan skip_all => "Odd perl path: $^X";
}


my $desc = "fdopen()ed file handle";
SKIP: {
  skip 'These tests are irrelevant on old perls', 3 if $] < 5.008;
  open my $fh, '>&=STDOUT' or die "Cannot fdopen STDOUT: '$!'";
  exit diag "Got fileno " . fileno($fh) unless fileno($fh)==1;

  # Basic error situation: STDOUT cannot be reopened on fd-1:
  eval { trap { system $PERL, '-e', 'binmode STDOUT; binmode STDERR; warn qq(0123456789Warning\n); print qq(Printing\n)'; exit 1 } };
  like( $@, qr/^\QCannot get the desired descriptor, '1' (could it be that it is fdopened and so still open?)/, "$desc: exception string" );
  is( fileno STDOUT, undef, "$desc: STDOUT should be left closed by now")
    or exit diag "Got STDOUT with fd " . fileno(STDOUT);
  is( fileno STDERR, 2, "$desc: STDERR fileno should be unchanged");

  unless (fileno(STDOUT) or open STDOUT, '>&=' . fileno $fh) {
    exit diag "Cannot fdopen fno ".fileno($fh).": '$!'";
  }
  if (fileno $fh and !close $fh) {
    exit diag "Cannot close: '$!'";
  }
}

$desc = "simple fork test";
trap {
  fork ? wait : do { warn "0123456789Warning\n"; print "Printing\n" };
  exit 1;
};
is( $T->exit, 1, "$desc: exit(1)" );
is( $T->stdout, "Printing\n", "$desc: system() STDOUT" );
is( $T->stderr, "0123456789Warning\n", "$desc: system() STDERR" );
is( join("\n", @{$T->warn}), '', "$desc: No warnings" );

# Have the file handles been re-opened on the right descriptors?
is( fileno STDOUT, 1, "$desc: STDOUT fileno should be unchanged");
is( fileno STDERR, 2, "$desc: STDERR fileno should be unchanged");

# Basic messing-up -- protect the handles with an outer trap:
trap {
  for (1..5) {
    my $desc = "Take $_";
    my $OUTFNO = 1;
    my $EXPECT = "Printing\n";
    if ($_ > 2) {
      close STDIN;
      $desc .= ' - STDIN closed';
    }
    if ($_ > 3) {
      close STDOUT;
      undef $OUTFNO;
      $EXPECT = '';
      $desc .= ' - STDOUT closed';
    }

    # Output from forked-off processes?
    trap {
      my @args = ($PERL, '-e', 'binmode STDOUT; binmode STDERR; warn qq(0123456789Warning\n); print qq(Printing\n)');
      system @args and die "system @args failed with $?";
      exit 1;
    };
    is( $T->exit, 1, "$desc: exit(1)" )
      or $T->diag_all;
    is( $T->stdout, $EXPECT, "$desc: system() STDOUT" );
    is( $T->stderr, "0123456789Warning\n", "$desc: system() STDERR" );
    is( join("\n", @{$T->warn}), '', "$desc: No warnings" );

    # Have the file handles been re-opened on the right descriptors?
    is( fileno STDOUT, $OUTFNO, "$desc: STDOUT fileno should be unchanged");
    is( fileno STDERR, 2, "$desc: STDERR fileno should be unchanged");
  }
};

SKIP: {
  use Config;
  unless ($Config{d_fork}) {
    skip 'Need a real fork()', 4;
  }
  # For coverage: Output from forked-off processes?
  my $me;
  trap {
    trap {
      $me = fork ? 'parent' : 'child';
      print "\u$me print\n";
      warn "\u$me warning\n";
      trap { 1 };
      wait, exit $$ if $me eq 'parent';
    };
    # On windows, in the child pseudo-process, this dies on leaving
    # the trap (fd 2 is not availible, because it is open in another
    # thread).  I don't think anything can be done about it.
    CORE::exit(0) if $me eq 'child';
    is( $T->exit, $$, "Trapped the parent exit" );
    like( $T->stdout, qr/^(Parent print\nChild print\n|Child print\nParent print\n)/, 'STDOUT from both processes!' );
    like( $T->stderr, qr/^(Parent warning\nChild warning\n|Child warning\nParent warning\n)/, 'STDERR from both processes!' );
    is_deeply( $T->warn, ["Parent warning\n"], 'Warnings from the parent only' );
  };
}

exit;
