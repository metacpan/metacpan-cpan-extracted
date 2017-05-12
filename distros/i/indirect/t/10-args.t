#!perl -T

use strict;
use warnings;

use Test::More tests => 4 + 3 + 1 + 2;

BEGIN { delete $ENV{PERL_INDIRECT_PM_DISABLE} }

sub expect {
 my ($pkg) = @_;
 qr/^Indirect call of method "new" on object "$pkg" at \(eval \d+\) line \d+/;
}

{
 my @warns;
 {
  local $SIG{__WARN__} = sub { push @warns, "@_" };
  eval <<'  HERE';
   return;
   no indirect;
   my $x = new Warn1;
   $x = new Warn2;
  HERE
 }
 my $w1 = shift @warns;
 my $w2 = shift @warns;
 is             $@, '',              'didn\'t croak without arguments';
 like          $w1, expect('Warn1'), 'first warning caught without arguments';
 like          $w2, expect('Warn2'), 'second warning caught without arguments';
 is_deeply \@warns, [ ],             'no more warnings without arguments';
}

for my $fatal (':fatal', 'FATAL', ':Fatal') {
 {
  local $SIG{__WARN__} = sub { die "warn:@_" };
  eval <<"  HERE";
   die qq{shouldn't even compile\n};
   no indirect '$fatal';
   my \$x = new Croaked;
   \$x = new NotReached;
  HERE
 }
 like $@, expect('Croaked'), "croaks when $fatal is specified";
}

{
 {
  local $SIG{__WARN__} = sub { "warn:@_" };
  eval <<'  HERE';
   die qq{shouldn't even compile\n};
   no indirect 'whatever', hook => sub { die 'hook:' . join(':', @_) . "\n" };
   my $x = new Hooked;
   $x = new AlsoNotReached;
  HERE
 }
 like $@, qr/^hook:Hooked:new:\(eval\s+\d+\):\d+$/, 'calls the specified hook';
}

{
 my $no_hook_and_fatal = qr/^The 'fatal' and 'hook' options are mutually exclusive at \(eval \d+\) line \d+/;

 {
  local $SIG{__WARN__} = sub { die "warn:@_" };
  eval <<'  HERE';
   die qq{shouldn't even compile\n};
   no indirect 'fatal', hook => sub { };
   new NotReached;
  HERE
 }
 like $@, $no_hook_and_fatal, '"no indirect qw<fatal hook>" croaks';

 {
  local $SIG{__WARN__} = sub { die "warn:@_" };
  eval <<'  HERE';
   die qq{shouldn't even compile\n};
   no indirect hook => sub { }, 'fatal';
   new NotReached;
  HERE
 }
 like $@, $no_hook_and_fatal, '"no indirect qw<hook fatal>" croaks';
}
