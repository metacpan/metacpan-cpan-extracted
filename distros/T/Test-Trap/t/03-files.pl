#!perl -T

BEGIN { $_ = defined && /(.*)/ && $1 for @ENV{qw/ TMPDIR TEMP TMP /} } # taint vs tempfile
use Test::More;
use IO::Handle;
use File::Temp qw( tempfile );
use Data::Dump qw(dump);
use strict;
use warnings;

our $strategy; # to be set in the requiring test script ...
our $class; # may be set in the requiring test script, otherwise:
BEGIN {
  $class ||= "Test::Trap::Builder::$strategy";
  local $@;
  eval qq{ use $class };
  if (exists &{"$class\::import"}) {
    plan tests => 1 + 6*10 + 5*3 + 11; # 10 runtests; 3 inner_tests; another bunch ...
  }
  else {
    plan skip_all => "$strategy strategy not supported; skipping";
  }
}

# This is an ugly bunch of tests, but for regression's sake, I'll
# leave it as-is.

# One problem is that warn() (or rather, the default __WARN__ handler)
# will print on the previous STDERR if the current STDERR is closed.

# Another problem is that the __WARN__ handler has not always been
# properly restored on exit from a trap.  Ouch.

BEGIN {
  use_ok( 'Test::Trap', '$T', lc ":flow:stdout($strategy):stderr($strategy):warn" );
}

STDERR: {
  close STDERR;
  my ($errfh, $errname) = tempfile( UNLINK => 1 );
  open STDERR, '>', $errname;
  STDERR->autoflush(1);
  print STDOUT '';
  sub stderr () { local $/; no warnings 'io'; local *ERR; open ERR, '<', $errname or die; <ERR> }
  END { close STDERR; close $errfh }
}

sub diagdie {
  my $msg = shift;
  diag $msg;
  die $msg;
}

my ($noise, $noisecounter) = ('', 0);
sub runtests(&@) { # runs the trap and performs 6 tests
  my($code, $return, $warn, $stdout, $stderr, $desc) = @_;
  my $n = ++$noisecounter . $/;
  warn $n or diagdie "Cannot warn()!";
  STDERR->flush or diagdie "Cannot flush STDERR!";
  print STDERR $n or diagdie "Cannot print on STDERR!";
  STDERR->flush or diagdie "Cannot flush STDERR!";
  $noise .= "$n$n";
  $warn = do { local $" = "[^`]*`"; qr/\A@$warn[^`]*\z/ };
  my @r = eval { &trap($code) }; # bypass prototype
  my $e = $@;
SKIP: {
    ok( !$e, "$desc: No internal exception" ) or do {
      diag "Got internal exception: '$e'";
      skip "$desc: Internal exception -- bad state", 5;
    };
    is_deeply( $T->return, $return, "$desc: Return" );
    like( join("`", @{$T->warn}), $warn, "$desc: Warnings" );
    is( $T->stdout, $stdout, "$desc: STDOUT" );
    like( $T->stderr, $stderr, "$desc: STDERR" );
    is( stderr, $noise, ' -- no uncaptured STDERR -- ' );
  }
}

my $inner_trap;
sub inner_tests(@) { # performs 5 tests
  my($return, $warn, $stdout, $stderr, $desc) = @_;
  $warn = do { local $" = "[^`]*`"; qr/\A@$warn[^`]*\z/ };
SKIP: {
    ok(eval{$inner_trap->isa('Test::Trap')}, "$desc: The object" )
      or skip 'No inner trap object!', 4;
    is_deeply( $inner_trap->return, $return, "$desc: Return" );
    like( join("`", @{$inner_trap->warn}), $warn, "$desc: Warnings" );
    is( $inner_trap->stdout, $stdout, "$desc: STDOUT" );
    like( $inner_trap->stderr, $stderr, "$desc: STDERR" );
  }
  undef $inner_trap; # catch those simple mistakes.
}

runtests { 5 }
  [5], [],
  '', qr/\A\z/,
  'No output';

runtests { my $t; print "Test printing '$t'"; 2}
  [2], [ qr/^Use of uninitialized value.* in concatenation \Q(.) or string at / ],
  "Test printing ''", qr/^Use of uninitialized value.* in concatenation \Q(.) or string at /,
  'Warning';

runtests { close STDERR; my $t; print "Test printing '$t'"; 2}
  [2], [ qr/^Use of uninitialized value.* in concatenation \Q(.) or string at / ],
  "Test printing ''", qr/\A\z/,
  'Warning with closed STDERR';

runtests { warn "Testing stderr trapping\n"; 5 }
  [5], [ qr/^Testing stderr trapping$/ ],
  '', qr/^Testing stderr trapping$/,
  'warn()';

runtests { close STDERR; warn "Testing stderr trapping\n"; 5 }
  [5], [ qr/^Testing stderr trapping$/ ],
  '', qr/\A\z/,
  'warn() with closed STDERR';

runtests {
  warn "Outer 1st\n";
  my @r = trap { warn "Testing stderr trapping\n"; 5 };
  binmode(STDERR); # XXX: masks a real weakness -- we do not simply restore the original!
  $inner_trap = $T;
  warn "Outer 2nd\n";
  @r
} [5], [ qr/Outer 1st/, qr/Outer 2nd/ ],
  '', qr/^Outer 1st\nOuter 2nd$/,
  'warn() in both traps';
inner_tests
  [5], [ qr/^Testing stderr trapping$/ ],
  '', qr/^Testing stderr trapping$/,
  ' -- the inner trap -- warn()';

runtests { print STDERR "Test printing"; 2}
  [2], [],
  '', qr/^Test printing\z/,
  'print() on STDERR';

runtests { close STDOUT; print "Testing stdout trapping\n"; 6 }
  [6], [ qr/^print\Q() on closed filehandle STDOUT at / ],
  '', qr/^print\Q() on closed filehandle STDOUT at /,
  'print() with closed STDOUT';

runtests { close STDOUT; my @r = trap { print "Testing stdout trapping\n"; (5,6) }; $inner_trap = $T; @r }
  [5, 6], [],
  '', qr/\A\z/,
  'print() in inner trap with closed STDOUT';
inner_tests
  [5, 6], [ qr/^print\Q() on closed filehandle STDOUT at / ],
  '', qr/^print\Q() on closed filehandle STDOUT at /,
  ' -- the inner trap -- print() with closed STDOUT';

runtests { close STDERR; my @r = trap { warn "Testing stderr trapping\n"; 2 }; $inner_trap = $T; @r }
  [2], [],
  '', qr/\A\z/,
  'warn() in inner trap with closed STDERR';
inner_tests
  [2], [ qr/^Testing stderr trapping$/ ],
  '', qr/\A\z/,
  ' -- the inner trap -- warn() with closed STDERR';

# regression test for the ', <$fh> line 1.' bug:
trap {
    trap {};
    warn "no newline";
};
unlike $T->stderr, qr/, \S+ line 1\./, 'No "<$f> line ..." stuff, please';

# regression test for preservation of PerlIO layers:
SKIP: {
  skip 'Lacking PerlIO', 4 unless eval "use PerlIO; 1";
  my @io = PerlIO::get_layers(*STDOUT);
  trap { binmode STDOUT, ':utf8' }; # or whatever, really
  is_deeply( [PerlIO::get_layers(*STDOUT)], \@io, 'STDOUT still has the original layers.')
    or diag(dump(\@io));
  binmode STDOUT;
  my @raw = PerlIO::get_layers(*STDOUT);
  trap { binmode STDOUT, ':utf8' }; # or whatever, really
  is_deeply( [PerlIO::get_layers(*STDOUT)], \@raw, 'STDOUT is still binmoded.')
    or diag(dump([PerlIO::get_layers(*STDOUT)], \@raw));
  binmode STDOUT, ':crlf';
  my @crlf = PerlIO::get_layers(*STDOUT);
  trap { binmode STDOUT, ':utf8' }; # or whatever, really
  is_deeply( [PerlIO::get_layers(*STDOUT)], \@crlf, 'STDOUT still has the crlf layer(s).')
    or diag(dump([PerlIO::get_layers(*STDOUT)], \@crlf));
  binmode STDOUT;
  my @tmp = @io;
  $_ eq $tmp[0] ? shift @tmp : last for PerlIO::get_layers(*STDOUT);
  binmode STDOUT, $_ for @tmp;
  is_deeply( [PerlIO::get_layers(*STDOUT)], \@io, 'Sanity check: STDOUT now again has the original layers.')
    or diag(dump([PerlIO::get_layers(*STDOUT)], \@io));
}

# test the $! handling:
my $errnum = 11; # "Resource temporarily unavailable" locally -- sounds good :-P
my $errstring = do { local $! = $errnum; "$!" };
my $erros = do { local $! = $errnum; $^E };
my ($errsym) = do { local $! = $errnum; grep { $!{$_} } keys(%!) };
{
  local $! = $errnum;
  trap {};
  my ($sym) = grep { $!{$_} } keys(%!);
  {
    # rt.cpan.org #105125: Test::More::is() does not preserve $^E, so ...
    my $postbang = $!+0;
    my $postos   = $^E;
    local($!, $^E);
    is $postbang,$errnum, "$strategy trap doesn't change errno (remains $errnum/$errstring)";
    is $postos, $erros,  "$strategy trap doesn't change extended OS error (remains $erros)";
    is $sym,    $errsym, "$strategy trap doesn't change the error symbol (remains $errsym)";
  }
}

{
  local $! = $errnum;
  trap {
    $! = 0;
    $^E = '';
  };
  my ($sym) = grep { $!{$_} } keys(%!);
  {
    # rt.cpan.org #105125: Test::More::is() does not preserve $^E, so ...
    my $postbang = $!+0;
    my $postos   = $^E;
    local($!, $^E);
    is $postbang,0, "Errno-unsetting trap unsets errno (it's not localized)";
    is $postos, '', "Errno-unsetting trap unsets extended OS error (it's not localized)";
    is $sym, undef, "Errno-unsetting trap unsets the error symbol (it's not localized)";
  }
}

1;
