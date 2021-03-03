package Valiant::Filter::Each;

use Moo::Role;
use Valiant::Util 'throw_exception', 'debug';
use Scalar::Util 'blessed';

with 'Valiant::Filter';
requires 'filter_each';

has attributes => (is=>'ro', predicate=>'has_attributes');
has model => (is=>'ro', required=>1);


sub generate_attributes {
  my ($self, $class, $attrs) = @_;
  return keys %$attrs unless $self->has_attributes; # Just filter everything when this is used with 'filters_with'
  if(ref($self->attributes) eq 'ARRAY') {
    return @{ $self->attributes };
  } elsif(ref($self->attributes) eq 'CODE') {
    return $self->attributes->($class, $attrs);
  }
}

sub filter {
  my ($self, $class, $attrs) = @_;
  foreach my $attribute ($self->generate_attributes($class, $attrs)) {
    $attrs->{$attribute} = $self->filter_each($class, $attrs, $attribute);
  }
  return $attrs;
}

1;

=head1 NAME

Valiant::Filter::Each - A Role to create custom validators

=head1 SYNOPSIS

    package Valiant::Filter::With;

    use Moo;

    with 'Valiant::Filter::Each';

    has cb => (is=>'ro', required=>1);

    sub normalize_shortcut {
      my ($class, $arg) = @_;
      if((ref($arg)||'') eq 'CODE') {
        return +{
          cb => $arg,
        };
      }
    }

    sub filter_each {
      my ($self, $class, $attrs, $attribute_name) = @_;  
      return $self->cb->($class, $attrs, $attribute_name);
    }

    1;

=head1 DESCRIPTION

Use this role when you with to create a custom filter that will be run 
on your class attributes.  Please note
that you can also use the 'with' validator (L<Valiant::Filter::With>)
for simple custom filter needs.  Its best to use this role when you
want custom filters that is going to be shared across several classes
so the effort pays off in reuse.

Your class must provide the method C<filter_each>, which will be called
once for each attribute in the validation.

=head1 SEE ALSO
 
L<Valiant>, L<Valiant::Filter>.

=head1 AUTHOR
 
See L<Valiant>  
    
=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
