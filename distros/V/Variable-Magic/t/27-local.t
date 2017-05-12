#!perl -T

use strict;
use warnings;

use Test::More;

use Variable::Magic qw<wizard cast getdata MGf_LOCAL>;

if (MGf_LOCAL) {
 plan tests => 2 * 3 + 1 + (2 + 2 * 7) + 1;
} else {
 plan skip_all => 'No local magic for this perl';
}

use lib 't/lib';
use Variable::Magic::TestWatcher;

my $wiz = init_watcher 'local', 'local';

our $a = int rand 1000;

my $res = watch { cast $a, $wiz } { }, 'cast';
ok $res, 'local: cast succeeded';

watch { local $a } { local => 1 }, 'localized';

{
 local $@;

 my $w1 = eval { wizard local => \undef, data => sub { 'w1' } };
 is $@, '', 'local: noop wizard creation does not croak';
 my $w2 = eval { wizard data => sub { 'w2' } };
 is $@, '', 'local: dummy wizard creation does not croak';

 {
  our $u;
  eval { cast $u, $w1 };
  is $@,               '',   'local: noop magic (first) cast does not croak';
  is getdata($u, $w1), 'w1', 'local: noop magic (first) cast succeeded';
  eval { cast $u, $w2 };
  is $@,               '',   'local: dummy magic (second) cast does not croak';
  is getdata($u, $w2), 'w2', 'local: dummy magic (second) cast succeeded';
  my ($z1, $z2);
  eval {
   local $u = '';
   $z1 = getdata $u, $w1;
   $z2 = getdata $u, $w2;
  };
  is $@, '',     'local: noop/dummy magic invocation does not croak';
  is $z1, undef, 'local: noop magic (first) prevented magic copy';
  is $z2, 'w2',  'local: dummy magic (second) was copied';
 }

 {
  our $v;
  eval { cast $v, $w2 };
  is $@,               '',   'local: dummy magic (first) cast does not croak';
  is getdata($v, $w2), 'w2', 'local: dummy magic (first) cast succeeded';
  eval { cast $v, $w1 };
  is $@,               '',   'local: noop magic (second) cast does not croak';
  is getdata($v, $w1), 'w1', 'local: noop magic (second) cast succeeded';
  my ($z1, $z2);
  eval {
   local $v = '';
   $z1 = getdata $v, $w1;
   $z2 = getdata $v, $w2;
  };
  is $@, '',     'local: dummy/noop magic invocation does not croak';
  is $z2, 'w2',  'local: dummy magic (first) was copied';
  is $z1, undef, 'local: noop magic (second) prevented magic copy';
 }
}
