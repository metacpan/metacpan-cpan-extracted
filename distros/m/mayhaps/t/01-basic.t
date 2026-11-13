package obstwe;

use v5.10;

sub new {
  my ($class, $init) = @_;
  bless { c => $init // 0 },
}

sub bump {
  my ($self, $amount) = @_;
  $amount //= 1;
  $self->{c} += $amount;
}

sub bop {
  my ($self, $amount) = @_;
  $amount //= 1;
  $self->{c} -= $amount;
}

sub beep {
  my ($self) = @_;
  return $self->bump(0);
}

package main;

use Test2::V0 -no_srand => 1;

use mayhaps;

my $o = obstwe->new;

subtest scaffolding => sub {
    is $o->beep, 0;
    $o->bump;
    is $o->beep, 1;
    $o->bump;
    is $o->beep, 2;
    $o->bop;
    is $o->beep, 1;
};

is $o->beep, 1;
isa_ok $o->mayhaps::bump(0, 10), ref($o);
is $o->beep, 1, 'false: did not run';
isa_ok $o->mayhaps::bump('', 10), ref($o);
is $o->beep, 1, 'false: did not run';
isa_ok $o->mayhaps::bump(undef, 10), ref($o);
is $o->beep, 1, 'false: did not run';

$o->mayhaps::bump(1, 10);
is $o->beep, 11, 'true: ran';

$o->mayhaps::bop(1);
is $o->beep, 10, 'true: ran';

done_testing;
