package Valiant::Proxy::Array;

use Moo;
with 'Valiant::Proxy';
sub read_attribute_for_validation {
  my ($self, $attribute) = @_;
  #my $index = $attribute->[-1];
  my (@index) = $attribute=~m/\[(\d+)\]/g;
  if( @index && $index[-1] =~m/^\d+$/ && defined $self->for->[$index[-1]]) {
    return  $self->for->[$index[-1]];
  } else {
    return undef; # TODO Might need a flag to allow die here?
  }
}

1;

=head1 NAME

Valiant::Proxy::Array - Wrap an arrayref in a result object for validation.

=head1 SYNOPSIS

    my $proxy = Valiant::Proxy::Array->new(
      validations => [
        # array elements are addressed by index, e.g. '[0]'
        [ '[0]' => presence => 1 ],
      ],
    );

    my $result = $proxy->validate([ 'first', 'second' ]);

=head1 DESCRIPTION

Allows you to run validations against an ArrayRef.

You probably won't use this directly, although you can.

=head1 SEE ALSO

This does the interface defined by L<Valiant::Proxy> so see the docs on that.
 
Also: L<Valiant>, L<Valiant::Validator>, L<Valiant::Validator::Each>.

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
