package Form::Processor::Field::Username;
use strict;
use warnings;
use base 'Form::Processor::Field::Text';
our $VERSION = '0.03';


sub validate {
    my $self = shift;

    return unless $self->SUPER::validate;

    my $input = $self->input || '';

    return $self->add_error('Usernames must not contain spaces')
        if $input =~ /\s/;

    return $self->add_error('Usernames must be at least 4 characters long')
        if length $input < 4;

    return 1;
}


=head1 NAME

Form::Processor::Field::Username

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

Validate that the input does not contain any spaces and is at least
four characters long.

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

