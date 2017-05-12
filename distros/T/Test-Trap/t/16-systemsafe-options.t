#!perl -T
# -*- mode: cperl ; compile-command: "cd .. ; ./Build ; prove -vb t/16-*.t" -*-

BEGIN {
  $_ = defined && /(.*)/ && $1 for @ENV{qw/ TMPDIR TEMP TMP /}; # taint vs tempfile
  use Test::More;
  eval "use PerlIO ()";
  plan skip_all => "PerlIO required for systemsafe-preserve and other options" if $@;
  eval "use Encode::Byte ()";
  plan skip_all => "Encode::Byte required to test at least Latin-2" if $@;
}

use Test::More tests => 3*2*5;

use strict;
use warnings;

# For compatibility with perl <= 5.8.8, :crlf must be applied before :utf8.
use Test::Trap::Builder::SystemSafe utf8   => { io_layers => ':crlf:utf8' };
use Test::Trap::Builder::SystemSafe both   => { io_layers => ':crlf:utf8', preserve_io_layers => 1 };
use Test::Trap::Builder::SystemSafe latin2 => { io_layers => ':encoding(iso-8859-2)' };
use Test::Trap qw/ $basic    basic    :output(systemsafe)          /;
use Test::Trap qw/ $preserve preserve :output(systemsafe-preserve) /;
use Test::Trap qw/ $utf8     utf8     :output(utf8)                /;
use Test::Trap qw/ $both     both     :output(both)                /;
use Test::Trap qw/ $latin2   latin2   :output(latin2)              /;

my @layers = qw(basic preserve utf8 both latin2);

our($trap);
sub trap(&);

# For RT #102271:
# The STDOUT may actually have a utf8 layer, from PERL_UNICODE or PERL5OPT or whatever.
# So, check it:
my $original_utf8 = grep { /utf8/ } PerlIO::get_layers(*STDOUT);

# Test 1: ł (l stroke); no messing with STDOUT
for my $glob (@layers) {
  no strict 'refs';
  local *trap = *$glob;
  trap { print "\x{142}" };
  if ($glob =~ /utf8|both|latin2/ or $original_utf8 && $glob eq 'preserve') {
    # it should work
    $trap->stdout_is("\x{142}", "SystemSafe '$glob' strategy handles l stroke");
    $trap->stderr_is('', "\t(no warning)");
  }
  else {
    $trap->stdout_is("\xC5\x82", "SystemSafe '$glob' strategy doesn't handle l stroke");
    $trap->stderr_like(qr/^Wide character in print.*$/, "\t(and warns)");
  }
}

# Test 2: π (pi); STDOUT binmoded to utf8
binmode STDOUT, ':raw:utf8';
for my $glob (@layers) {
  no strict 'refs';
  local *trap = *$glob;
  trap { print "\x{3C0}" };
  if ($glob =~ /utf8|preserve|both/) {
    # it should work
    $trap->stdout_is("\x{3C0}", "SystemSafe '$glob' strategy handles pi");
    $trap->stderr_is('', "\t(no warning)");
  }
  elsif ($glob eq 'latin2') {
    $trap->stdout_like(qr/^\\x\{0?3c0\}\z/, "SystemSafe '$glob' strategy doesn't handle pi; falls back to \\x notation");
    $trap->stderr_like(qr/^"\\x\{0?3c0\}" does not map to iso-8859-2 .*$/, "\t(and warns)");
  }
  else {
    $trap->stdout_is("\xCF\x80", "SystemSafe '$glob' strategy doesn't handle pi");
    $trap->stderr_like(qr/^Wide character in print.*$/, "\t(and warns)");
  }
}

# Test 3: ‰\n% (per mille, newline, per cent); STDOUT binmoded to latin2
binmode STDOUT, ':raw:encoding(iso-8859-2)';
for my $glob (@layers) {
  no strict 'refs';
  local *trap = *$glob;
  trap { print "\x{2030}\n%" };
  if ($glob =~ /utf8/) {
    # it should work
    $trap->stdout_is("\x{2030}\n%", "SystemSafe '$glob' strategy handles per mille");
    $trap->stderr_is('', "\t(no warning)");
  }
  elsif ($glob =~ /preserve|both|latin2/) {
    $trap->stdout_is("\\x{2030}\n%", "SystemSafe '$glob' strategy doesn't handle per mille; falls back to \\x notation");
    $trap->stderr_like(qr/^\Q"\x{2030}"\E does not map to iso-8859-2 .*$/, "\t(and warns)");
  }
  else {
    $trap->stdout_is("\xE2\x80\xB0\n%", "SystemSafe '$glob' strategy doesn't handle per mille");
    $trap->stderr_like(qr/^Wide character in print.*$/, "\t(and warns)");
  }
}
