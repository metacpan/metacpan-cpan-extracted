package Form::Processor::Field::PosInteger;
use strict;
use warnings;
use base 'Form::Processor::Field::Integer';
our $VERSION = '0.03';


sub validate {
    my $self = shift;

    return unless $self->SUPER::validate;

    # remove plus sign.
    my $value = $self->input;
    if ( $value =~ s/^\+// ) {
        $self->input( $value );
    }


    return $self->add_error('Value must be a positive integer')
        unless $self->input >= 0;

    return 1;

}


=head1 NAME

Form::Processor::Field::PosInteger - Validates input is a postive integer

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

Simply tests that the input is an integer and has a postive value.

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "text".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: "Integer".

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

