package Form::Processor::Field::MD5_Password;
use strict;
use warnings;
use base 'Form::Processor::Field::Password';
use Digest::MD5 'md5_hex';
our $VERSION = '0.03';



sub validate {
    my $self = shift;

    return unless $self->SUPER::validate;

    my $input = $self->input;


    return $self->add_error( 'Passwords must include one or more digits' )
        unless $input =~ /\d/;

    return 1;
}

sub input_to_value {
    my $field = shift;

    $field->value( md5_hex( $field->input ) );

    return;
}


=head1 NAME

Form::Processor::Field::MD5_Password - convert passwords to MD5 hashes

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

Validation requires one or more digits.  Value returned is the MD5 hash
of the input value.

Useful for storing hashed passwords.

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "password".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: "Password".

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

