package Form::Processor::Field::Integer;
use strict;
use warnings;
use base 'Form::Processor::Field::Text';
our $VERSION = '0.03';


sub init_size { 8 }

sub validate {
    my $self = shift;

    return unless $self->SUPER::validate;

    # remove plus sign.
    my $value = $self->input;
    if ( $value =~ s/^\+// ) {
        $self->input( $value );
    }

    return $self->add_error('Value must be an integer')
        unless $self->input =~ /^-?\d+$/;

    return 1;

}



=head1 NAME

Form::Processor::Field::Integer - validate an integer value
=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

This accpets a positive or negative integer.  Negative integers may
be prefixed with a dash.

By default a max of eight digets are accepted.


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

