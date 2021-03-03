package Valiant::Proxy::Object;

use Moo;
use Valiant::Util 'throw_exception';
use Scalar::Util 'blessed';

with 'Valiant::Proxy';

sub read_attribute_for_validation {
  my ($self, $attribute) = @_;
  if($self->for->can($attribute)) {
    return $self->for->$attribute;
  } else {
    throw_exception MissingMethod => (object=>$self->for, method=>$attribute);
  }
}

sub AUTOLOAD {
  my $self = shift;
  ( my $method = our $AUTOLOAD ) =~ s{.*::}{};
  if(blessed($self->for) && $self->for->can($method)) {
    return $self->for->$method(@_);
  } else {
    # warn "cannot find $method in ${\$self->data}";
  }
}

1;

=head1 NAME

Valiant::Result::Object - Wrap any object into a validatable result object.

=head1 SYNOPSIS

    TBD

=head1 DESCRIPTION

Create a validation object for a given class or role.  Useful when you need (or prefer)
to build up a validation ruleset in code rather than via the annotations-like approach
given in L<Valiant::Validations>.  Can also be useful to add validations to a class that
isn't Moo/se and can't use  L<Valiant::Validations> or is outside your control (such as
a third party library).  Lastly you may need to build validation sets based on existing
metadata, such as via database introspection or from a file containing validation
instructions.

This uses AUTOLOAD to delegate method calls to the underlying object.

Please note that the code used to create the validation object is not speed optimized so
I recommend you not use this approach in 'hot' code paths.  Its probably best if you can
create all these during your application startup once (for long lived applications).  Maybe
not ideal for 'fire and forget' scripts like cron jobs or CGI.

You probably won't use this directly (although you can) since we have L<Valiant::Class> to
encapsulate the most common patterns for this need.

=head1 SEE ALSO

This does the interface defined by L<Valiant::Result> so see the docs on that.
 
Also: L<Valiant>, L<Valiant::Validator>, L<Valiant::Validator::Each>.

=head1 AUTHOR

