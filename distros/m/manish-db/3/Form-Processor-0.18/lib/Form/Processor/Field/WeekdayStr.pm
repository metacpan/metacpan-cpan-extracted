package Form::Processor::Field::WeekdayStr;
use strict;
use warnings;
use base 'Form::Processor::Field::Weekday';
our $VERSION = '0.03';


# Join the list of values into a single string

sub input_to_value {
    my $field = shift;

    my $input = $field->input;

    return $field->value( join '', ref $input ? @{$input} : $input );
}

sub format_value {
    my $field = shift;

    return () unless defined $field->value;


    return ( $field->name, [ split //, $field->value ] );
}


=head1 NAME

Form::Processor::Field::WeekdayStr

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

This allow storage of multiple days of the week in a single string field.
as digits.


=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "select".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: "Weekday".

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





