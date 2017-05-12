#!perl -T

# Test the capabilities of the running perl.
use Test::More tests => 93;
use feature 'switch';
use warnings;
use strict;

# Apparently ~~ is a moving target, so testing your perl for support.
ok(undef ~~ undef, 'undef ~~ undef');
ok(undef ~~ [1,undef], 'undef ~~ [1,undef]');
{ no warnings 'uninitialized';
  ok(!(undef ~~ /2/), '!(undef ~~ /2/)');
}
ok(2 ~~ /2/, '2 ~~ /2/');
ok(eval {grep 2 ~~ $_, [qr/2/]}, 'eval {grep 2 ~~ $_, [qr/2/]}');
ok(eval {grep 2 ~~ $_, [1,qr/2/]}, 'eval {grep 2 ~~ $_, [1,qr/2/]}');
ok(eval {grep 2 ~~ $_, [qr/2/,1]}, 'eval {grep 2 ~~ $_, [qr/2/,1]}');
ok(eval {grep 2 ~~ $_, [1,qr/2/,undef]},
  'eval {grep 2 ~~ $_, [1,qr/2/,undef]}');
ok(eval {grep 2 ~~ $_, [undef,qr/2/,1]},
  'eval {grep 2 ~~ $_, [undef,qr/2/,1]}');
ok(2 ~~ [qr/2/], '2 ~~ [qr/2/]');
ok(2 ~~ [1,qr/2/], '2 ~~ [1,qr/2/]');
ok(2 ~~ [qr/2/,1], '2 ~~ [qr/2/,1]');
ok(2 ~~ [1,qr/2/,undef], '2 ~~ [1,qr/2/,undef]');
ok(2 ~~ [undef,qr/2/,1], '2 ~~ [undef,qr/2/,1]');
ok(undef ~~ [1,qr/2/,undef], 'undef ~~ [1,qr/2/,undef]');
ok(1 ~~ [1,qr/2/,undef], '1 ~~ [1,qr/2/,undef]');
ok(undef ~~ [undef,qr/2/,1], 'undef ~~ [undef,qr/2/,1]');
ok(1 ~~ [undef,qr/2/,1], '1 ~~ [undef,qr/2/,1]');

ok(1==1, '1==1');
ok(!(1==0), '!(1==0)');
ok(eval {return 1==1}, 'eval {return 1==1}');
ok(eval {return !(1==0)}, 'eval {return !(1==0)}');
TODO: {
local $TODO = 'MUST FAIL!';
  ok(1==0, '1==0');
  ok(eval {return 1==0}, 'eval {return 1==0}');
}
ok(eval {given(1){when(1){return 1==1} default{return 1==0}}},
  'given 1 when 1');
ok(eval {given(2){when(/2/){return 1==1} default{return 1==0}}},
  'given 2 when /2/');
ok(eval {given(undef){when(undef){return 1==1} default{return 1==0}}},
  'given undef when undef');
ok(eval {given(undef){when([1,undef]){return 1==1} default{return 1==0}}},
  'given undef when [undef,1]');
ok(eval {given(undef){when([undef,1]){return 1==1} default{return 1==0}}},
  'given undef when [undef,1]');
ok(eval {given(1){when([1,undef]){return 1==1} default{return 1==0}}},
  'given 1 when [undef,1]');
ok(eval {given(1){when([undef,1]){return 1==1} default{return 1==0}}},
  'given 1 when [undef,1]');

ok(eval {given(1){when([1,qr/2/]){return 1==1} default{return 1==0}}},
  'given 1 when [1,qr/2/]');
ok(eval {given(1){when([qr/2/,1]){return 1==1} default{return 1==0}}},
  'given 1 when [qr/2/,1]');

ok(eval {given(1){when([1,qr/2/,undef]){return 1==1} default{return 1==0}}},
  'given 1 when [1,qr/2/,undef]');
ok(eval {given(1){when([undef,1,qr/2/]){return 1==1} default{return 1==0}}},
  'given 1 when [undef,1,qr/2/]');
ok(eval {given(undef){when([1,qr/2/,undef]){return 1==1}
  default{return 1==0}}}, 'given undef when [1,qr/2/,undef]');
ok(eval {given(undef){when([undef,1,qr/2/]){return 1==1}
  default{return 1==0}}}, 'given undef when [undef,1,qr/2/]');

ok(eval {given(2){when([1,qr/2/]){return 1==1} default{return 1==0}}},
  'given 2 when [1,qr/2/]');
ok(eval {given(2){when([qr/2/,1]){return 1==1} default{return 1==0}}},
  'given 2 when [qr/2/,1]');
ok(eval {given(2){when([1,qr/2/,undef]){return 1==1} default{return 1==0}}},
  'given 2 when [1,qr/2/,undef]');
ok(eval {given(2){when([undef,1,qr/2/]){return 1==1} default{return 1==0}}},
  'given 2 when [undef,1,qr/2/]');

sub _exone($) {
  my ($given) = @_;
#  warn Dumper(\@_);
  given ($given){
    when([undef,'etc_network_interfaces','iface','mapping']) {return 'Null'}
    when('COMMENT') {return 'COMMENT'}
    when(['up','down','post-up','pre-down','auto',qr/allow-[^ ]*/]) {
      return 'repeat';
    }
    default {return 'default'}
  }
}

is(_exone(undef), 'Null', '_exone(undef)');
is(_exone("etc_network_interfaces"), 'Null', '_exone("etc_network_interfaces")');
is(_exone("mapping"), 'Null', '_exone("mapping")');
is(_exone("COMMENT"), 'COMMENT', '_exone("COMMENT")');
is(_exone("up"), 'repeat', '_exone("up")');
is(_exone("pre-down"), 'repeat', '_exone("pre-down")');
is(_exone("auto"), 'repeat', '_exone("auto")');
is(_exone("allow-auto"), 'repeat', '_exone("allow-auto")');
is(_exone("allow-pizza"), 'repeat', '_exone("allow-pizza")');
is(_exone("allow-"), 'repeat', '_exone("allow-")');
is(_exone("default"), 'default', '_exone("default")');
is(_exone("pizza"), 'default', '_exone("pizza")');
is(_exone(""), 'default', '_exone("")');

sub _extwo($) {
  my ($given) = @_;
#  warn Dumper(\@_);
  my $tmp='__NEVERMATCH';
  given ($given){
    when([undef,'etc_network_interfaces','iface','mapping']) {return 'Null'}
    when('COMMENT') {return 'COMMENT'}
    when(/allow-[^ ]*/) { $tmp=$given; continue; }
    when(['up','down','post-up','pre-down','auto',$tmp]) {return 'repeat'}
    default {return 'default'}
  }
}

is(_extwo(undef), 'Null', '_extwo(undef)');
is(_extwo("etc_network_interfaces"), 'Null', '_extwo("etc_network_interfaces")');
is(_extwo("mapping"), 'Null', '_extwo("mapping")');
is(_extwo("COMMENT"), 'COMMENT', '_extwo("COMMENT")');
is(_extwo("up"), 'repeat', '_extwo("up")');
is(_extwo("pre-down"), 'repeat', '_extwo("pre-down")');
is(_extwo("auto"), 'repeat', '_extwo("auto")');
is(_extwo("allow-auto"), 'repeat', '_extwo("allow-auto")');
is(_extwo("allow-pizza"), 'repeat', '_extwo("allow-pizza")');
is(_extwo("allow-"), 'repeat', '_extwo("allow-")');
is(_extwo("default"), 'default', '_extwo("default")');
is(_extwo("pizza"), 'default', '_extwo("pizza")');
is(_extwo(""), 'default', '_extwo("")');

sub _exthr($) {
  my ($given) = @_;
#  warn Dumper(\@_);
  given ($given){
    when(undef) {return 'Null'}
    when(['etc_network_interfaces','iface','mapping']) {return 'Null'}
    when('COMMENT') {return 'COMMENT'}
    when(['up','down','post-up','pre-down','auto',qr/allow-[^ ]*/]) {
      return 'repeat';
    }
    default {return 'default'}
  }
}

is(_exthr(undef), 'Null', '_exthr(undef)');
is(_exthr("etc_network_interfaces"), 'Null', '_exthr("etc_network_interfaces")');
is(_exthr("mapping"), 'Null', '_exthr("mapping")');
is(_exthr("COMMENT"), 'COMMENT', '_exthr("COMMENT")');
is(_exthr("up"), 'repeat', '_exthr("up")');
is(_exthr("pre-down"), 'repeat', '_exthr("pre-down")');
is(_exthr("auto"), 'repeat', '_exthr("auto")');
is(_exthr("allow-auto"), 'repeat', '_exthr("allow-auto")');
is(_exthr("allow-pizza"), 'repeat', '_exthr("allow-pizza")');
is(_exthr("allow-"), 'repeat', '_exthr("allow-")');
is(_exthr("default"), 'default', '_exthr("default")');
is(_exthr("pizza"), 'default', '_exthr("pizza")');
is(_exthr(""), 'default', '_exthr("")');

sub _exfor($) {
  my ($given) = @_;
#  warn Dumper(\@_);
  my $tmp='__NEVERMATCH';
  given ($given){
    when(undef) {return 'Null'}
    when(['etc_network_interfaces','iface','mapping']) {return 'Null'}
    when('COMMENT') {return 'COMMENT'}
    when(/allow-[^ ]*/) { $tmp=$given; continue; }
    when(['up','down','post-up','pre-down','auto',$tmp]) {return 'repeat'}
    default {return 'default'}
  }
}

is(_exfor(undef), 'Null', '_exfor(undef)');
is(_exfor("etc_network_interfaces"), 'Null', '_exfor("etc_network_interfaces")');
is(_exfor("mapping"), 'Null', '_exfor("mapping")');
is(_exfor("COMMENT"), 'COMMENT', '_exfor("COMMENT")');
is(_exfor("up"), 'repeat', '_exfor("up")');
is(_exfor("pre-down"), 'repeat', '_exfor("pre-down")');
is(_exfor("auto"), 'repeat', '_exfor("auto")');
is(_exfor("allow-auto"), 'repeat', '_exfor("allow-auto")');
is(_exfor("allow-pizza"), 'repeat', '_exfor("allow-pizza")');
is(_exfor("allow-"), 'repeat', '_exfor("allow-")');
is(_exfor("default"), 'default', '_exfor("default")');
is(_exfor("pizza"), 'default', '_exfor("pizza")');
is(_exfor(""), 'default', '_exfor("")');

