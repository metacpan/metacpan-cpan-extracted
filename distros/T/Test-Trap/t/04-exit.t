#!perl -T
# -*- mode: cperl ; compile-command: "cd .. ; ./Build ; prove -vb t/04-*.t" -*-

BEGIN { $_ = defined && /(.*)/ && $1 for @ENV{qw/ TMPDIR TEMP TMP /} } # taint vs tempfile
use Test::More tests => 9;
use strict;
use warnings;

my ($done_exit, $ready_for_exit);
BEGIN {
  *CORE::GLOBAL::exit = sub(;$) {
    ok($ready_for_exit, "The outer CORE::GLOBAL::exit isn't called too early");
    $done_exit++;
    CORE::exit(@_ ? shift : 0);
  };
}
END{
  ok($done_exit, "The final test: The outer CORE::GLOBAL::exit is eventually called");
}

BEGIN {
  use_ok( 'Test::Trap' );
}

# test the $! handling:
my $errnum = 11; # "Resource temporarily unavailable" locally -- sounds good :-P
my $errstring = do { local $! = $errnum; "$!" };
my $erros = do { local $! = $errnum; $^E };
my ($errsym) = do { local $! = $errnum; grep { $!{$_} } keys(%!) };

$! = $errnum;

trap { exit };
is( $trap->exit, 0, "Trapped the first exit");
trap {
  *CORE::GLOBAL::exit = sub(;$) {
    fail("Should be overridden");
    CORE::exit(@_ ? shift : 0);
  };
  trap { exit };
  is( $trap->exit, 0, "Trapped the inner exit");
};
like( $trap->stderr, qr/^Subroutine (?:CORE::GLOBAL::)?exit redefined at \Q${\__FILE__} line/, 'Override warning' );

my ($sym) = grep { $!{$_} } keys(%!);
is $!+0, $errnum, "These traps don't change errno (remains $errnum/$errstring)";
is $^E, $erros,  "These traps don't change extended OS error (remains $erros)";
is $sym, $errsym, "These traps don't change the error symbol (remains $errsym)";

$ready_for_exit++;

exit;
