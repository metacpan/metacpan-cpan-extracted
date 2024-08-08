package WebGPU::Direct::MappedBuffer
{
  use v5.30;
  use warnings;
  no warnings qw(experimental::signatures);
  use feature 'signatures';

  sub buffer_i32 (
    $self,
    @values,
      )
  {
    my $buffer = CORE::pack( 'l*', @values );
    $self->buffer($buffer);
    return length $buffer;
  }

  sub buffer_u32 (
    $self,
    @values,
      )
  {
    $self->buffer( CORE::pack( 'L*', @values ) );
  }

  sub buffer_f32 (
    $self,
    @values,
      )
  {
    $self->buffer( CORE::pack( 'f*', @values ) );
  }

  sub buffer_f16 (
    $self,
    @values,
      )
  {
    Carp::croak "f16 is not yet supported";
    $self->buffer( CORE::pack( 'L*', @values ) );
  }
};

1;
__END__
=pod

=encoding UTF-8

=head1 NAME

WebGPU::Direct::MappedBuffer

=head2 Methods

=head3 buffer

=over

=item * Return Type

=over

=item * String (void *)

=back

=item * Arguments

=over

=item * value (String (void *))

=back

=back

=head3 buffer_i32

=over

=item * Return Type

=over

=item * Number of bytes saved to the buffer

=back

=item * Arguments

=over

=item * Array of C<i32> values

=back

=back

=head3 buffer_u32

=over

=item * Return Type

=over

=item * Number of bytes saved to the buffer

=back

=item * Arguments

=over

=item * Array of C<u32> values

=back

=back

=head3 buffer_f32

=over

=item * Return Type

=over

=item * Number of bytes saved to the buffer

=back

=item * Arguments

=over

=item * Array of C<f32> values

=back

=back

=head3 buffer_f16 (Currently does supported)

=over

=item * Return Type

=over

=item * Number of bytes saved to the buffer

=back

=item * Arguments

=over

=item * Array of C<f16> values

=back

=back

