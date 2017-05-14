package Form::Processor::Field::Email;
use strict;
use warnings;
use base 'Form::Processor::Field';
use Email::Valid;
our $VERSION = '0.03';

sub validate {
    my $self = shift;

    return unless $self->SUPER::validate;

    $self->input( lc $self->{input} );


    return $self->add_error('Email should be of the format [_1]', 'someuser@example.com')
        unless Email::Valid->address( $self->input );


    return 1;
}


=head1 NAME

Form::Processor::Field::Email - Validates email uisng Email::Valid

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

Validates that the input looks like an email address uisng L<Email::Valid>.

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "text".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: "Field".

=head1 DEPENDENCIES

L<Email::Valid>

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

