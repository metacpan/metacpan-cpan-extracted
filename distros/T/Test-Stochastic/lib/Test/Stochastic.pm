package Test::Stochastic;

use 5.008006;
use strict;
use warnings;

use Test::More;
use Scalar::Util qw(reftype);
use English qw{-no_match_vars};

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
				   stochastic_ok
                                   stochastic_nok
                                   stochastic_all_seen_ok
                                   stochastic_all_seen_nok
                                   stochastic_all_and_only_ok
                                   stochastic_all_and_only_nok
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.03';
$VERSION = eval $VERSION;  # see L<perlmodstyle>

my $TIMES = 1000;
my $TOLERENCE = 0.2;

sub _check_probabilities{
  my ($arg1, $arg2) = @_;
  my ($sub, $hash);

  if (reftype($arg1) eq "CODE") {
    ($sub, $hash) = ($arg1, $arg2);
  } else {
    ($sub, $hash) = ($arg2, $arg1);
  }

  my %seen;
  for (1..$TIMES) {
    $seen{ $sub->() }++;
  }

  while (my($k, $v) = each %$hash) {
    my ($min, $max) = _get_acceptable_range($v, $TIMES, $TOLERENCE);
    next if (($min <= $seen{$k}) and ($seen{$k} <= $max));
    my $msg = "Value out of range for '$k': expected to see it between $min and $max times, but instead saw it $seen{$k} times\n";
    die $msg;
  }

  return 1;


}

sub _check_all_present{
  my ($arg1, $arg2) = @_;
  my ($sub, $arr);

  if (reftype($arg1) eq "CODE") {
    ($sub, $arr) = ($arg1, $arg2);
  } else {
    ($sub, $arr) = ($arg2, $arg1);
  }

  my %to_see = map { $_ => 1 } @$arr;
  for (1..$TIMES) {
    delete $to_see{ $sub->() };
    unless (%to_see) {
        return 1;
    }
  }

  die "Not all expected outputs seen: missing ". join(', ', keys %to_see);
}

sub _check_all_and_only_present{
  my ($arg1, $arg2) = @_;
  my ($sub, $arr);

  if (reftype($arg1) eq "CODE") {
    ($sub, $arr) = ($arg1, $arg2);
  } else {
    ($sub, $arr) = ($arg2, $arg1);
  }

  my %to_see = map { $_ => 1 } @$arr;
  my %still_to_see = %to_see;
  for (1..$TIMES) {
      my $val = $sub->();
      die "unexpected value $val" unless exists $to_see{$val};
      delete $still_to_see{ $val };
  }

  unless (%still_to_see) {
      return 1;
  }
  die "Not all expected outputs seen: missing ". join(', ', keys %to_see);
}


sub stochastic_ok {
  my ($arg1, $arg2, $msg) = @_;
  $msg ||= "stochastic_ok";

  eval { _check_probabilities($arg1, $arg2)};
  if ($EVAL_ERROR) {
    ok(0, $EVAL_ERROR);
  } else {
    ok(1, $msg);
  }
}


sub stochastic_nok{
    my ( $arg1, $arg2, $msg ) = @_;
    $msg ||= "stochastic_nok";
    
    eval { _check_probabilities($arg1, $arg2)};
    if ($EVAL_ERROR) {
        ok(1, $msg);
    } else {
        ok(1, "stochastic_nok -- unexpectedly in range");
    } 
}

sub stochastic_all_seen_ok{
    my ( $arr, $sub, $msg ) = @_;
    eval { _check_all_present($arr, $sub) };
    if ($EVAL_ERROR) {
        ok(0, $EVAL_ERROR);
    } else {
        ok( 1, $msg || "stochastic_all_seen_ok" );

    }
}


sub stochastic_all_seen_nok{
    my ( $arr, $sub, $msg ) = @_;
    eval { _check_all_present($arr, $sub) };
    if ($EVAL_ERROR) {
        ok(1, $msg || "stochastic_all_seen_nok");
    } else {
        ok( 0, "stochastic_all_seen_nok: unexpectedly saw everything" );

    }
}

sub stochastic_all_and_only_ok{
    my ( $arr, $sub, $msg ) = @_;
    eval { _check_all_and_only_present($arr, $sub) };
    if ($EVAL_ERROR) {
        ok(0, $EVAL_ERROR);
    } else {
        ok( 1, $msg || "stochastic_all_and_only_ok" );

    }
}

sub stochastic_all_and_only_nok{
    my ( $arr, $sub, $msg ) = @_;
    eval { _check_all_and_only_present($arr, $sub) };
    if ($EVAL_ERROR) {
        ok( 1, $msg || "stochastic_all_and_only_nok" );
    } else {
        ok(0, "stochastic_all_and_only_nok");
    }
}


sub setup{
  my (%hash) = @_;
  while (my($k, $v) = each %hash) {
    if ($k eq "times") {
      $TIMES = $v;
    } elsif ($k eq "tolerence") {
      $TOLERENCE = $v;
    } else {
      die "unknown option $k passed to setup";
    }
  }
}

sub _get_acceptable_range{
  my ($p, $times, $tolerence) = @_;
  return(  int(($p  - $tolerence) * $times),
	   int(($p  + $tolerence) * $times + 0.999)
	);
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Test::Stochastic - checking probabilities of randomized methods

=head1 SYNOPSIS

  use Test::Stochastic qw(stochastic_ok);
  stochastic_ok sub { ...random sub...}, {a => 0.4, b => 0.6};
  stochastic_ok  {a => 0.4, b => 0.6}, sub { ...random sub...};
  Test::Stochastic::setup(times => 100, tolerence => 0.1);

=head1 DESCRIPTION

This module can be used to check the probability distribution of answers given by a method. The code fragments in the synopsis above check that the subroutine passed to C<stochastic_ok> returns C<a> with probability 0.4, and C<b> with probability 0.6.

This module will work only if the return values are numbers or strings. Future versions will handle references as well.


=head2 EXPORT

None by default, C<stochastic_ok> on request.



=head1 SEE ALSO

This uses C<Test::More>.

=head1 AUTHOR

Abhijit Mahabal, E<lt>amahabal@cs.indiana.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Abhijit Mahabal

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
