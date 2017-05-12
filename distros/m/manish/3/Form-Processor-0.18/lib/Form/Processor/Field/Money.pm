package Form::Processor::Field::Money;
use strict;
use warnings;
use base 'Form::Processor::Field::Text';
our $VERSION = '0.03';

sub init_value_format { '%.2f' }


sub validate {
    my $self = shift;

    return unless $self->SUPER::validate;

    # remove plus sign.
    my $value = $self->input;

    return unless defined $value;

    if ( $value =~ s/^\$// ) {
        $self->input( $value );
    }

    return $self->add_error('Value must be a real number')
        unless $value =~ /^-?\d+\.?\d*$/;


    return 1;


}



=head1 NAME

Form::Processor::Field::Money - Input US currenty-like values.

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

Validates that a postivie or negative real value is entered.
Formatted with two decimal places.

Uses a period for the decimal point.  Not very locale smart, if you ask me.


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

