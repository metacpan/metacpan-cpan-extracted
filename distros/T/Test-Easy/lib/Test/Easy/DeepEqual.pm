use strict;
use warnings;
package Test::Easy::DeepEqual;
use base qw(Exporter);

use Carp ();
use Data::Denter ();
use Data::Denter ();
use Data::Difflet;
use Scalar::Util ();
use Test::Easy::equivalence;
use Test::More ();

our @EXPORT = qw(deep_ok deep_equal);

sub deep_ok ($$;$) {
  my ($got, $exp, $message) = @_;

  local $Test::Builder::Level = $Test::Builder::Level + 1;
  Test::More::ok( deep_equal($got, $exp), $message ) || do {
    my $dump_got = Data::Denter::Denter($got);
    my $dump_exp = Data::Denter::Denter($exp);

    Test::More::diag '$GOT';
    Test::More::diag $dump_got;
    Test::More::diag '$EXPECTED';
    Test::More::diag $dump_exp;
    Test::More::diag '$DIFFLET';
    Test::More::diag(Data::Difflet->new->compare($got, $exp));
  };
}

sub deep_equal {
  Carp::confess "must have only two things to deep_equal" if @_ != 2;

  return 1 if _undefs(@_);
  return 0 unless _same_type(@_);
  return 1 if _hashrefs(@_) && _same_hashrefs(@_);
  return 1 if _arrayrefs(@_) && _same_arrayrefs(@_);
  return 1 if _same_values(@_); # note, not 'if _scalars(@_) && _same_values(@_)'
  return 1 if _regex_match(@_);
  return 0;
}

sub _undefs    { return 2 == grep { ! defined } @_ }
sub _hashrefs  { return 2 == grep { ref($_) eq 'HASH' } @_ }
sub _arrayrefs { return 2 == grep { ref($_) eq 'ARRAY' } @_ }

# check the refs of $got and $exp; they must match, or $got must be a simple scalar and $exp must be a checker object.
sub _same_type {
  my ($got, $exp) = @_;

  return 1 if _undefs(@_);
  return 1 if ref($got) eq ref($exp);
  return 1 if ! ref($got) && _is_a_checker($exp);
  if (! ref($got) && ref($exp) eq 'Regexp') {
$DB::single = 1;1;
    return 1;
  }
  Carp::cluck "a ${\ref($got)} is not a ${\ref($exp)}!\n";
  return 0;
}

sub _same_hashrefs {
  my ($got, $exp) = @_;

  # if their keys aren't the same there's no point checking further
  # ...but really we should run the checker objects as mutators on $exp
  # so the real failure is apparent
  return 0 unless scalar keys %$got == scalar keys %$exp;

  # not 'each': it would reset the hash's iterator on a potentially weird caller
  foreach my $k (keys %$exp) {
    return 0 unless exists $got->{$k};
    return 0 unless deep_equal($got->{$k}, $exp->{$k});
  }

  # make sure there's nothing extra in $got that we didn't $exp'ect to see.
  return 0 == grep { ! exists $exp->{$_} } keys %$got;
}

sub _same_arrayrefs {
  my ($got, $exp) = @_;

  return 0 unless $#$got == $#$exp;

  for (my $i = 0; $i < @$exp; $i++) {
    return 0 unless deep_equal($got->[$i], $exp->[$i]);
  }

  return 1;
}

sub _is_a_checker {
  my ($exp) = @_;
  my $ref = ref($exp);
  return $ref && Scalar::Util::blessed($exp) && UNIVERSAL::can($exp, 'check_value');
}

sub _same_values {
  my ($got, $exp) = @_;
  my ($ref_got, $ref_exp) = map { ref } $got, $exp;
  my $checker = _is_a_checker($exp)
    ? $exp
    : Test::Easy::equivalence->new(
      test => sub {
        my ($got) = @_;
        return "$got" eq "$exp";
      },
    );
  return $checker->check_value($got);
}

sub _regex_match {
  my ($got, $exp) = @_;
  return 0 if ref($got) || ref($exp) ne 'Regexp';
  return $got =~ $exp;
}

1;
