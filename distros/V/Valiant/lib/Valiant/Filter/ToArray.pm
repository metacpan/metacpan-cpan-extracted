package Valiant::Filter::ToArray;

use Moo;
use Valiant::Util 'throw_exception';

with 'Valiant::Filter::Each';

has split_on => (is=>'ro', predicate=>'has_split_on');

sub normalize_shortcut {
  my ($class, $arg) = @_;
  return +{ };
}

sub filter_each {
  my ($self, $class, $attrs, $attribute_name) = @_;  
  my $value = $attrs->{$attribute_name};
  return unless defined $value;

  if($self->has_split_on) {
    return [split($self->split_on, $value) ];
  }
  return (ref($value)||'') eq 'ARRAY' ? $value : [$value];
}

1;

=head1 NAME

Valiant::Filter::ToArray - Force the value into an arrayref if its not one already

=head1 SYNOPSIS

    package Local::Test;

    use Moo;
    use Valiant::Filters;

    has 'string' => (is=>'ro', required=>1);
    has 'array' => (is=>'ro', required=>1);
    has 'split' => (is=>'ro', required=>1);

    filters ['string', 'array'] => (to_array => 1);
    filters split => (to_array => +{ split_on => ',' } );

    my $object = Local::Test->new(
      string => 'foo',
      array => ['bar', 'baz'],
      split = '123',
    );

    $object->string;  # ['foo']
    $object->array;   # ['bar', 'baz']
    $object->split:   # [1, 2, 3]
  
=head1 DESCRIPTION

Force any scalar values to arrayref.  Basically normalize on an arrayref.  Allows you
to specific a split pattern or just make the string into an arrayref

=head1 ATTRIBUTES

This filter defines the following attributes

=head2 split_on

Optional.   A pattern used via C<split> to split a string into an arrayref.  If not
present just use the string as is to make an arrayref.

=head1 SEE ALSO
 
L<Valiant>, L<Valiant::Filter>, L<Valiant::Validator::Filter>.

=head1 AUTHOR
 
See L<Valiant>  
    
=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
