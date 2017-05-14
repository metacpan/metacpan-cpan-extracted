package Form::Processor::Field::USPhone;
use strict;
use warnings;
use base 'Form::Processor::Field::Text';
our $VERSION = '0.03';

sub validate {
    my $self = shift;

    return unless $self->SUPER::validate;

    my $input = $self->input;

    $input =~ s/\D//g;

    return $self->add_error('Phone Number must be 10 digits, including area code')
        unless length $input == 10;

    return 1;
}


=head1 NAME

Form::Processor::Field::USPhone - Validate that the input looks like a US phone number

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

This removes any non-digits and then tests that there are ten digits.

This is probably not that useful as valid phone numbers may not need to contain
ten digits -- and that additional input data may be important.

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "text".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: "Text".

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

