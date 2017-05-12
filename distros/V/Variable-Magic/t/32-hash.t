#!perl -T

use strict;
use warnings;

use Test::More tests => (2 * 27 + 9) + 2 * (2 * 5 + 5) + 1;

use Variable::Magic qw<
 cast dispell
 VMG_UVAR
 VMG_COMPAT_HASH_DELETE_NOUVAR_VOID
>;

use lib 't/lib';
use Variable::Magic::TestWatcher;

my $wiz = init_watcher
        [ qw<get set len clear free copy dup local fetch store exists delete> ],
        'hash';

my %n = map { $_ => int rand 1000 } qw<foo bar baz qux>;
my %h = %n;

watch { cast %h, $wiz } { }, 'cast';

my $s = watch { $h{foo} } +{ (fetch => 1) x VMG_UVAR },
                       'assign element to';
is $s, $n{foo}, 'hash: assign element to correctly';

my %b;
watch { %b = %h } { }, 'assign to';
is_deeply \%b, \%n, 'hash: assign to correctly';

$s = watch { \%h } { }, 'reference';

my @b = watch { @h{qw<bar qux>} }
                  +{ (fetch => 2) x VMG_UVAR }, 'slice';
is_deeply \@b, [ @n{qw<bar qux>} ], 'hash: slice correctly';

# exists

watch { exists $h{bar} } +{ (exists => 1) x VMG_UVAR },'exists in void context';

for (1 .. 2) {
 $s = watch { exists $h{bar} } +{ (exists => 1) x VMG_UVAR },
                                                "exists in scalar context ($_)";
 ok $s, "hash: exists correctly ($_)";
}

# delete

watch { delete $h{bar} } +{
 ((delete => 1) x !VMG_COMPAT_HASH_DELETE_NOUVAR_VOID, copy => 1) x VMG_UVAR
}, 'delete in void context';

for (1 .. 2) {
 $s = watch { delete $h{baz} } +{ (delete => 1, copy => 1) x VMG_UVAR },
                                                "delete in scalar context ($_)";
 my $exp = $_ == 1 ? $n{baz} : undef;
 is $s, $exp, "hash: delete correctly ($_)";
}

# clear

watch { %h = () } { clear => 1 }, 'empty in list context';

watch { $h{a} = -1; %h = (b => $h{a}) }
           +{ (fetch => 1, store => 2, copy => 2) x VMG_UVAR, clear => 1 },
           'empty and set in void context';

watch { %h = (a => 1, d => 3) }
               +{ (store => 2, copy => 2) x VMG_UVAR, clear => 1 },
               'assign from list in void context';

@b = watch { %h = (a => 1, d => 3) }
               +{ (exists => 2, store => 2, copy => 2) x VMG_UVAR, clear => 1 },
               'assign from list in void context';

watch { %h = map { $_ => 1 } qw<a b d>; }
               +{ (store => 3, copy => 3) x VMG_UVAR, clear => 1 },
               'assign from map in void context';

watch { $h{d} = 2 } +{ (store => 1) x VMG_UVAR },
                    'assign old element';

watch { $h{c} = 3 } +{ (store => 1, copy => 1) x VMG_UVAR },
                    'assign new element';

$s = watch { %h } { }, 'buckets';

@b = watch { keys %h } { }, 'keys';
is_deeply [ sort @b ], [ qw<a b c d> ], 'hash: keys correctly';

@b = watch { values %h } { }, 'values';
is_deeply [ sort { $a <=> $b } @b ], [ 1, 1, 2, 3 ], 'hash: values correctly';

watch { while (my ($k, $v) = each %h) { } } { }, 'each';

watch {
 my %b = %n;
 watch { cast %b, $wiz } { }, 'cast 2';
} { free => 1 }, 'scope end';

watch { undef %h } { clear => 1 }, 'undef';

watch { dispell %h, $wiz } { }, 'dispell';

SKIP: {
 my $SKIP;

 if (!VMG_UVAR) {
  $SKIP = 'uvar magic';
 } else {
  local $@;
  unless (eval { require B; require B::Deparse; 1 }) {
   $SKIP = 'B and B::Deparse';
  }
 }
 if ($SKIP) {
  $SKIP .= ' required to test uvar/clear interaction fix';
  skip $SKIP => 2 * ( 2 * 5 + 5);
 }

 my $bd = B::Deparse->new;

 my %h1 = (a => 13, b => 15);
 my %h2 = (a => 17, b => 19);

 my @tests = (
  [ \%h1 => 'first hash'  => (14, 16) ],
  [ \%h2 => 'second hash' => (18, 20) ],
 );

 for my $test (@tests) {
  my ($h, $desc, @exp) = @$test;

  watch { &cast($h, $wiz) } { }, "cast clear/uvar on $desc";

  my $code   = sub { my $x = $h->{$_[0]}; ++$x; $x };
  my $before = $bd->coderef2text($code);
  my $res;

  watch { $res = $code->('a') } { fetch => 1 }, "fetch constant 'a' from $desc";
  is $res, $exp[0], "uvar: fetch constant 'a' from $desc was correct";

  my $after = $bd->coderef2text($code);
  is $before, $after,
                "uvar: code deparses correctly after constant fetch from $desc";

  my $key = 'b';
  watch { $res = $code->($key) } { fetch => 1 },"fetch variable 'b' from $desc";
  is $res, $exp[1], "uvar: fetch variable 'b' from $desc was correct";

  $after = $bd->coderef2text($code);
  is $before, $after,
                "uvar: code deparses correctly after variable fetch from $desc";

  watch { %$h = () } { clear => 1 }, "fixed clear for $desc";

  watch { &dispell($h, $wiz) } { }, "dispell clear/uvar from $desc";

  ok(!(B::svref_2object($h)->FLAGS & B::SVs_RMG()),
                               "$desc no longer has the RMG flag set");
 }
}
