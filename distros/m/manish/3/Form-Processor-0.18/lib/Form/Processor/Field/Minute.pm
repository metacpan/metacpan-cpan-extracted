package Form::Processor::Field::Minute;
use strict;
use warnings;
use base 'Form::Processor::Field::IntRange';
our $VERSION = '0.03';

sub init_range_start { 0 }
sub init_range_end { 59 }
sub init_label_format { '%02d' }  # How the base class will format the options

=head1 NAME

Form::Processor::Field::Minute - input range from 0 to 60

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

Generate a select list for entering a minute value.

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "select".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: "IntRange"

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
