package Form::Processor::Field::Readonly;
use strict;
use warnings;
use base 'Form::Processor::Field::Text';
our $VERSION = '0.03';

=item

This field is a display only field

=cut

sub init_readonly { 1 };  # for html rendering

sub init_noupdate { 1 }



=head1 NAME

Form::Processor::Field::Readonly - Field that can be read but not updated

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

This field is used to display but not update data from the database/model.

This readonly field has the "readonly" and "noupdate" flags set.
The "readonly" flag is a hint to render the HTML as a readonly field.
The "noupdate" flag tells L<Form::Processor> to not update the database
with this data.

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "text/readonly".

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

