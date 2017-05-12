use strict;
use warnings;
package Tie::Scalar::Ratio;
$Tie::Scalar::Ratio::VERSION = '0.01';
use parent 'Tie::Scalar';

#ABSTRACT: a scalar which multiplies in value every time it is accessed.

sub TIESCALAR {
  my ($class, $ratio, $value) = @_;

  die 'Must provide ratio argument, a number to multiply the scalar value by'
    unless $ratio && $ratio =~ /^[\d.]+$/;

  bless {
    ratio => $ratio,
    value => $value,
  }, $class;
}

sub STORE {
  my ($self, $value) = @_;
  $self->{value} = $value;
}

sub FETCH {
  my ($self) = @_;
  my $old_value = $self->{value};
  $self->{value} *= $self->{ratio} if $self->{value};
  return $old_value;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tie::Scalar::Ratio - a scalar which multiplies in value every time it is accessed.

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use Tie::Scalar::Ratio;

  tie(my $doubler, 'Tie::Scalar::Ratio', 2, 1);

  print $doubler; # 1
  print $doubler; # 2
  print $doubler; # 4
  print $doubler; # 8

  tie(my $halver, 'Tie::Scalar::Ratio', 0.5, 80);

  print $halver; # 80
  print $halver; # 40
  print $halver; # 20
  print $halver; # 10

=head1 DESCRIPTION

C<Tie::Scalar::Ratio> is a class for creating tied scalars which multiply their
value by a ratio everytime their value is read. I found this a useful way to
make a C<retry()> function increase its sleep duration after every attempt,
without re-writing the function (I just passed a C<Tie::Scalar::Ratio> object
as the duration scalar).

Similarly by passing a ratio value less than 1, it can be used as a timeout or
countdown feature.

=head1 SEE ALSO

L<Tie::Scalar::Decay|https://metacpan.org/pod/Tie::Scalar::Decay>

=head1 AUTHOR

David Farrell <dfarrell@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by David Farrell.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
