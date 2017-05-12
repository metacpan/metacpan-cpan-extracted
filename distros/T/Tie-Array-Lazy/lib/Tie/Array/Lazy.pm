package Tie::Array::Lazy;
use warnings;
use strict;
our $VERSION = sprintf "%d.%02d", q$Revision: 0.2 $ =~ /(\d+)/g;

sub DESTROY { }

sub TIEARRAY($\@\&;@){
    my ( $pkg, $array, $maker ) = splice @_, 0, 3;
    bless { _array => $array, _maker => $maker, @_ }, $pkg;
}

sub array { $_[0]->{_array} }
sub index { scalar @{ $_[0]->array } }
sub maker { $_[0]->{_maker} }

sub EXTEND($$) {
    my ( $self, $size ) = @_;
    my $index = $self->index;
    while ($index <= $size){
        $self->array->[$index] =  $self->maker->($self, $index);
	$index++;
    }
}

sub FETCH($$) {
    my ( $self, $index ) = @_;
    $self->EXTEND($index);
    $self->array->[$index];
}

sub STORE($$$) {
    my ( $self, $index, $value ) = @_;
    $self->EXTEND($index-1);
    $self->array->[$index] = $value;
}

sub STORESIZE($) { }

sub FETCHSIZE($) { scalar @{ $_[0]->array } + 1 }

sub PUSH($@) { push @{ shift->array }, @_ }

sub UNSHIFT($@) { unshift @{ shift->array }, @_ }

sub SHIFT($) {
    $_[0]->index ? shift @{ $_[0]->array } : $_[0]->maker->( $_[0] )
}

sub POP($) {
    $_[0]->index ? pop @{ $_[0]->array } : $_[0]->maker->( $_[0] )
}

sub CLEAR($){ @{$_[0]->array} = () }

sub SPLICE($;$$@){
    my $self = shift;
    return splice @{$self->array} unless @_;
    my $off = shift;
    $self->EXTEND( $off + 1);
    return splice @{$self->array}, $off unless @_;
    my $len = shift;
    return splice @{$self->array}, $off, $len unless @_;
    splice @{$self->array}, $off, $len, @_;
}

1;
__END__

=head1 NAME

Tie::Array::Lazy - Lazy -- but mutable -- arrays.

=head1 VERSION

$Id: Lazy.pm,v 0.2 2012/08/09 19:13:00 dankogai Exp dankogai $

=cut

=head1 SYNOPSIS

  use Tie::Array::Lazy;
  # 0..Inf
  tie my @a, 'Tie::Array::Lazy', [], sub{ $_[0]->index };
  print @a[0..9];      # 0123456789
  $a[1] = 'one';
  print @a[0..9];      # 0one23456789
  print "$_\n" for @a; # prints forever

=head1 DESCRIPTION


L<Tie::Array::Lazy> implements a I<lazy array>, an array that
generates the element on demand.  It is a lot like a I<lazy list> but
unlike lazy lists seen in many functional languages like Haskell, lazy
arrays are mutable so you can assign values to their elements.

The example below explains how it works.

  tie my @a, 'Tie::Array::Lazy', [3,2,1,0], sub{ 1 };
  my @r = splice @a, 1, 2, qw/two one/
  # @r is (2,1);     tied(@a)->array is [3,'two','one',0];
  pop @a;   # 0;     tied(@a)->array is [3,'two','one'];
  shift @a; # 3;     tied(@a)->array is ['two','one'];
  shift @a; # 'two'; tied(@a)->array is ['one'];
  pop @a;   # 'one;  tied(@a)->array is [];
  pop @a;   # 1;     tied(@a)->array is [];
  @a[3] = 3 #        tied(@a)->array is [1,1,1,3];

You can think I<lazy arrays> as arrays that auto-fills.

=head1 EXPORT

None.

=head1 FUNCTIONS

=head2  tie @array, 'Tie::Array::Lazy', *arrayref*, *coderef*

makes @array a lazy array with its initial state with I<arrayref> and
element generator code with I<coderef>. Here is an exmaple;

The I<coderef> is a code reference which C<$_[0]> is the
Tie::Array::Lazy object itself (tied(@array)) and C<$_[1]> is the
index.

In addition to methods that L<Tie::Array> provides, the object has
methods below:

=over 2

=item array

The reference to the internal array which stores values either
generated or assigned.

  # Fibonacci array
  tie my @a, 'Tie::Array::Lazy', 
      [0, 1], 
      sub{ $_[0]->array->[-2] + $_[0]->array->[-1] }

=item index

Shorthand for C<< scalar @{ $self->array } >>.

  # 0..Inf
  tie my @a, 'Tie::Array::Lazy', [], sub{ $_[0]->index };

=item maker

The reference to the code reference to generate the value needed.
Whenever the value is needed, L<Tie::Array::Lazy> invokes the code
below;

  $self->maker($self, $index);

=back

=head2 Using L<Tie::Array::Lazy> as a base class

Like L<Tie::Array>, you can use this module as a base class.  See
L<Tie::Array::Lazier> for details.

=head1 AUTHOR

Dan Kogai, C<< <dankogai at dan.co.jp> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-tie-array-lazy at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tie-Array-Lazy>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tie::Array::Lazy

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tie-Array-Lazy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tie-Array-Lazy>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tie-Array-Lazy>

=item * Search CPAN

L<http://search.cpan.org/dist/Tie-Array-Lazy>

=back

=head1 ACKNOWLEDGEMENTS

Nick Ing-Simmons for L<Tie::Array>

Matsumoto Yukihiro (Matz) for teasing me into hacking this module.

=head1 COPYRIGHT & LICENSE

Copyright 2007-2012 Dan Kogai, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
