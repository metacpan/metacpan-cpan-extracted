use v5.10;
use strict;
use warnings;
package Tie::Scalar::Callback;
$Tie::Scalar::Callback::VERSION = '0.07';
use parent 'Tie::Scalar';
use Carp qw(carp);

#ABSTRACT: a tied scalar which executes a callback everytime it is used

sub TIESCALAR {
  my ($class, $sub ) = @_;

  die 'Must provide subroutine reference argument'
    unless $sub && ref $sub eq ref sub {};

  bless $sub, $class;
}

sub STORE {
  carp "You can't assign to this tied scalar";
}

sub FETCH {
  my ($self) = @_;
  return $self->();
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tie::Scalar::Callback - a tied scalar which executes a callback everytime it is used

=head1 VERSION

version 0.07

=head1 SYNOPSIS

  use Tie::Scalar::Callback;

  # this coderef doubles the scalar's value everytime it's fetched
  my $coderef = sub {
  	state $value  = 1/2;
  	state $factor = 2;
  	$value *= $factor;
    }
  };

  tie(my $doubler, 'Tie::Scalar::Callback', $coderef);

  print $doubler; 1
  print $doubler; 2
  print $doubler; 4

=head1 DESCRIPTION

C<Tie::Scalar::Callback> is a class for creating tied scalars which execute
a callback everytime an event occurs on the scalar. The callback's return
value becomes the scalar's apparent value.

=head1 ACKNOWLEDGEMENTS

Thanks to L<brian d foy|https://metacpan.org/author/BDFOY> for coming up with the idea for this module.

=head1 SEE ALSO

=over 4

=item *

L<Tie::Simple|https://metacpan.org/pod/Tie::Simple>

=item *

L<Tie::Cycle|https://metacpan.org/pod/Tie::Cycle>

=item *

L<Tie::Scalar::Decay|https://metacpan.org/pod/Tie::Scalar::Decay>

=item *

L<Tie::Scalar::Ratio|https://metacpan.org/pod/Tie::Scalar::Ratio>

=back

=head1 AUTHOR

David Farrell <dfarrell@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by David Farrell.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
