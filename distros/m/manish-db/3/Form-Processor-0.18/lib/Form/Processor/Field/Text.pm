package Form::Processor::Field::Text;
use strict;
use warnings;
use base 'Form::Processor::Field';
our $VERSION = '0.03';


use Rose::Object::MakeMethods::Generic (
    scalar => [
        size            => { interface => 'get_set_init' },
        min_length      => { interface => 'get_set_init' },
    ],
);

sub init_size { 0 }
sub init_min_length { 0 }



sub init_widget { 'text' }

sub validate {
    my $field = shift;

    return unless $field->SUPER::validate;

    my $value = $field->input;


    # Check for max length
    if ( my $size = $field->size  ) {

        return $field->add_error( 'Please limit to [quant,_1,character]. You submitted [_2]', $size, length $value )
            if length $value > $size;

    }

    # Check for min length
    if ( my $size = $field->min_length  ) {

        return $field->add_error( 'Input must be at least [quant,_1,character]. You submitted [_2]', $size, length $value )
            if length $value < $size;

    }

    return 1;

}

=head1 NAME

Form::Processor::Field::Text - A simple text entry field

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

This is a simple text entry field.

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "text".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: "Field".

=head1 METHODS

=head2 size [integer]

This integer value, if non-zero, defines the max size in characters of the input field.
This setting may also be used in formatting the field in the user interface.

=head2 min_length [integer]

This integer value, if non-zero, defines the minimum number of characters that must 
be entered.


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

