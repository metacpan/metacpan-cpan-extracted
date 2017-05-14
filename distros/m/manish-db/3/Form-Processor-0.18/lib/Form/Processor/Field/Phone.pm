package Form::Processor::Field::Phone;
use strict;
use warnings;
use base 'Form::Processor::Field::Text';
our $VERSION = '0.03';


=head1 NAME

Form::Processor::Field::Phone - input a telephone number

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

This is a placeholder field that does not override any methods
and is just a subclass of the Text field.

This origianlly had valiation to test the phone number length and pattern,
but it became clear that phone numbers vary too much to be validated in
this way -- and it breaks the rule that you should only validate what
needs validation.

You may wish to replace this class if you really need a specific phone number
format.


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

