package Form::Processor::Field::Checkbox;
use strict;
use warnings;
use base 'Form::Processor::Field::Boolean';
our $VERSION = '0.03';

sub init_widget { 'checkbox' }

sub input_to_value {
    my $field = shift;

    $field->value( $field->input ? 1 : 0 );
}

sub value {
    my $field = shift;
    return $field->SUPER::value( @_ ) if @_;
    my $v = $field->SUPER::value;
    return defined $v ? $v : 0;
}


=head1 NAME

Form::Processor::Field::Checkbox - A boolean checkbox field type

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

This field is very similar to the Boolean field with the exception
that only true or false can be returned.

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "checkbox".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: "Field".

=head1 AUTHORS

Bill Moseley

=head1 COPYRIGHT

See L<Form::Processor> for copyright.

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SUPPORT / WARRANTY

L<Form::Processor> is free software and is provided WITHOUT WARRANTY OF ANY KIND.
Users are expected to review software for fitness and usability.

=cut

1;


