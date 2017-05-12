#!/usr/bin/perl

use warnings;
use strict;

use Test::More;

my %spec;
plan tests => scalar(keys(%spec)) * 2;
BEGIN {
%spec = (
  check_use => <<'    CODE',
    use lambda;
    my $c = λ{'foo'};
    return $c->();
    CODE
  check_use2 => <<'    CODE',
    use lambda;
    my $c = λ{'foo'};
    no lambda;
    return $c->();
    CODE
  check_no => <<'    CODE',
    use lambda;
    my $c = λ{'foo'};
    no lambda;
    my $d = λ{'bar'};
    return $c->();
    CODE
);
} # end BEGIN

sub run {
  my ($thing) = @_;
  my $spec = $spec{$thing} or die "nothing for $thing";
  my $ans = eval($spec);
  my $err = $@;
  return({ans => $ans, err => $err});
}

{ # everything is normal
  my $res = run('check_use');
  is($res->{ans}, 'foo', 'got foo');
  is($res->{err}, '', 'no error');
}
{ # everything is normal
  my $res = run('check_use2');
  is($res->{ans}, "foo", 'got foo');
  is($res->{err}, '', 'no error');
}
{ # nope
  my $res = run('check_no');
  is($res->{ans}, undef, 'dies ok');
  like($res->{err}, qr/Unrecognized/, 'got error');
}

# vim:ts=2:sw=2:et:sta:encoding=utf8
