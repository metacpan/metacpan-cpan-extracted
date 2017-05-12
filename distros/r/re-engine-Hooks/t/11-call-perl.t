#!perl -T

use strict;
use warnings;

use blib 't/re-engine-Hooks-TestDist';

use Test::More tests => 2 * 2;

# Those tests must be ran inside eval STRING because the test distribution
# can hold only one callback at a time.

my @nodes;

eval <<'TEST1';
my $rx = do {
 use re::engine::Hooks::TestDist 'custom' => sub { push @nodes, @_ };
 qr/.(?:a|o).*/;
};

{
 local $@;
 eval {
  "foo" =~ $rx;
 };
 is $@, '', 'calling perl code in the exec hook does not croak';
 is_deeply \@nodes, [ qw<REG_ANY TRIE STAR END> ],
            'calling perl code in the exec hook works correctly';
}
TEST1
die $@ if $@;

eval <<'TEST2';
my $res;

my $rx = do {
 use re::engine::Hooks::TestDist 'custom' => sub { $res += ("durp" =~ /.urp/) };
 qr/.(?:a|o).*/;
};

{
 local $@;
 eval {
  "foo" =~ $rx;
 };
 is $@, '', 'a regexp match in the exec hook does not croak';
 is $res, scalar(@nodes), 'a regexp match in the exec hook works correctly';
}
TEST2
die $@ if $@;
