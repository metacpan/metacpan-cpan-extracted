package Form::Processor::Field::Boolean;
use strict;
use warnings;
use base 'Form::Processor::Field';
our $VERSION = '0.03';

sub init_widget { 'radio' }  # although not really used.


sub value {
    my $self = shift;

    my $v = $self->SUPER::value(@_);

    return unless defined $v;

    return $v ? 1 : 0;
}


=head1 NAME

Form::Processor::Field::Boolean - A true or false field

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

This field returnes undef if no value is defined, 0 if defined and false,
and 1 if defined and true.

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "radio".

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


