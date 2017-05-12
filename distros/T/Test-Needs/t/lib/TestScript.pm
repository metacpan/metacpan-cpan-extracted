package TestScript;
use strict;
use warnings;
use Test::Needs;

sub plan;
sub subtest;
sub done_testing;
sub ok;

for my $sub (qw(plan ok subtest done_testing)) {
  no strict 'refs';
  no warnings 'redefine';
  *$sub = sub {
    if (!$INC{'Test2/API.pm'}) {
      require Test::Builder;
      my $tb = Test::Builder->new;
      for my $install (qw(plan ok subtest done_testing)) {
        *{$install} = sub {
          $tb->$install(@_);
        };
      }
    }
    else {
      *plan = sub {
        my $ctx = Test2::API::context();
        $ctx->plan(
          $_[0] eq 'no_plan' ? (0, 'NO PLAN')
          : $_[0] eq 'tests' ? ($_[1])
          : @_
        );
        $ctx->release;
      };
      *subtest = \&Test2::API::run_subtest;
      *ok = sub {
        my $ctx = Test2::API::context();
        $ctx->ok(@_);
        $ctx->release;
      };
      *done_testing = sub {
        my $ctx = Test2::API::context();
        $ctx->done_testing;
        $ctx->release;
      };
    }
    goto &$sub;
  };
}

sub import {
  my $class = shift;
  my $opts = { map { /^--([^=]*)(?:=(.*))?/ ? ($1 => $2||1) : () } @_ };
  my @args = grep !/^--/, @_;
  @args = @args == 1 ? @args : { @args };
  if ($opts->{load}) {
    eval qq{ package main; use $opts->{load}; 1; } or die $@;
  }

  if ($opts->{subtest}) {
    plan tests => 1;
    subtest subtest => sub { do_test($opts, @args) };
  }
  else {
    do_test($opts, @args);
  }
  exit 0;
}


sub do_test {
  my ($opts, @args) = @_;
  if ($opts->{plan}) {
    plan tests => 2;
  }
  elsif ($opts->{no_plan}) {
    plan 'no_plan';
  }
  if ($opts->{tests}) {
    ok 1;
  }
  test_needs @args;
  plan tests => 2
    unless $opts->{tests} || $opts->{plan} || $opts->{no_plan};
  ok 1;
  ok 1
    unless $opts->{tests};
  done_testing
    if $opts->{tests} && !($opts->{plan} || $opts->{no_plan});
}

1;
