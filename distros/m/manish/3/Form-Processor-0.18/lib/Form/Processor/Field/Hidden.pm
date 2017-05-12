package Form::Processor::Field::Hidden;
use strict;
use warnings;
use base 'Form::Processor::Field::Text';
our $VERSION = '0.03';


sub init_widget { 'hidden' }


=head1 NAME

Form::Processor::Field::Hidden - a text field as a hidden widget

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

This simply inherits from the Text field and sets the widget type as
"hidden".

This should probably be deprecated because it's probalby better to simply
use a text field and set its widget type to "hidden".

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "hidden".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: Text

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

