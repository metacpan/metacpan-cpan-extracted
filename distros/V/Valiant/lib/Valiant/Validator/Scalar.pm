package Valiant::Validator::Scalar;

use Moo;
use Valiant::I18N;

with 'Valiant::Validator::Each';

has is_not_scalar => (is=>'ro', required=>1, default=>sub {_t 'is_not_a_scalar'});

sub normalize_shortcut {
  my ($class, $arg) = @_;
  return +{} if $arg eq '1' ;
}

sub validate_each {
  my ($self, $record, $attribute, $value, $opts) = @_;
  return if ref( \$value ) eq 'SCALAR' or ref( \( my $val = $value ) ) eq 'SCALAR';

  $record->errors->add($attribute, $self->is_not_scalar, $opts)
}

1;

=head1 NAME

Valiant::Validator::Scalar - Validate that a value is a scalar (like a string or number)

=head1 SYNOPSIS

    package Local::Test::Scalar;

    use Moo;
    use Valiant::Validations;

    has name => (is=>'ro');

    validates name => ( scalar => 1 );

    ok my $object = Local::Test::Scalar->new(name=>[111,'John']);
    ok $object->validate->invalid;

    is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      'name' => [
        'Name must be a string or number',
      ]
    };

=head1 DESCRIPTION

Validates that the value in question is a scalar.

=head1 SHORTCUT FORM

This validator supports the follow shortcut forms:

    validates attribute => ( scalar => 1, ... );

Which is the same as:

    validates attribute => (
      scalar => { },
    );
 
=head1 GLOBAL PARAMETERS

This validator supports all the standard shared parameters: C<if>, C<unless>,
C<message>, C<strict>, C<allow_undef>, C<allow_blank>.

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Valiant>, L<Valiant::Validator>, L<Valiant::Validator::Each>.
    
=head1 COPYRIGHT & LICENSE
 
Copyright 2020, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
