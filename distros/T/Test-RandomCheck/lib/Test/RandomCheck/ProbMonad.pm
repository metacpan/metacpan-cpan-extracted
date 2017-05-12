package Test::RandomCheck::ProbMonad;
use strict;
use warnings;
use Exporter qw(import);
our @EXPORT = qw(
    gen const range elements variant
);

sub gen (&) {
    my $code = shift;
    bless $code => __PACKAGE__;
}

sub const (@) { my @args = @_; gen { @args } }

sub range ($$) {
    my ($min, $max) = @_;
    gen { $_[0]->next_int($min, $max) };
}

sub elements (@) {
    my $ref_elems = \@_;
    (range 0, $#$ref_elems)->map(sub { $ref_elems->[shift] });
}

sub pick {
    my ($self, $rand, $size) = @_;
    $self->($rand, $size);
}

sub map {
    my ($self, $f) = @_;
    gen { $f->($self->pick(@_)) };
}

sub flat_map {
    my ($self, $f) = @_;
    gen {
        my ($rand, $size) = @_;
        $f->($self->pick($rand, $size))->pick($rand, $size);
    };
}

1;
__END__

=encoding utf-8

=head1 NAME

Test::RandomCheck::ProbMonad - The probability monad

=head1 SYNOPSIS

  use Test::RandomCheck::ProbMonad;
  use Test::RandomCheck::PRNG;

  # A basic generator which returns random integers
  my $gen1 = gen {
      my ($r, $size) = @_;
      $r->next_int($size);
  };

  # It returns "******" strings randomly
  my $gen2 = $gen1->map(sub { '*' x $_[0] });

  # Build the new generator with the value from the original generator
  my $gen3 = $gen2->flat_map(sub{
      my $str = shift;
      gen {
          my ($r, $size) = @_;
          $str . $r->next_int($size);
      };
  });

  # Run generators
  my $r = Test::RandomCheck::PRNG->new;
  print $gen1->pick($r, 100), "\n"; # ex). 26
  print $gen2->pick($r, 100), "\n"; # ex). *****************
  print $gen3->pick($r, 100), "\n"; # ex). *********34

=head1 DESCRIPTION

Test::RandomCheck::Generator is a combinator to build random value generators
used by L<Test::RandomCheck>.

=head1 CONSTRUCTORS

=over 4

=item C<<gen { ... };>>

The most primitive constructor of this class. The block should return
any values randomly. The block will be called on list context.

The block recieved C<$r> and C<$size> as its arguments. C<$r> is an instance of
L<Test::RandomCheck::RPNG>.

=back

=head1 METHODS

=over 4

=item C<<my @random_values = $gen->pick($rand, $size);>>

Pick a set of values from this generator. You must pass an instance of
L<Test::RandomCheck::RPNG>.

=item C<<$gen->map(sub { ...; return @values });>>

A functor to apply normal functions to a Generator instance.

=item C<<$gen->flat_map(sub { ...; return $new_gen });>>

A kleisli composition to apply kleisli allows to a Generator instance.

=back

=head1 SEE ALSO

L<Test::RandomCheck::Types>

=head1 AUTHOR

Masahiro Honma E<lt>hiratara@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2013- Masahiro Honma

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
