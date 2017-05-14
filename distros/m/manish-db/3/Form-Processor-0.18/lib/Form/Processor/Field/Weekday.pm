package Form::Processor::Field::Weekday;
use strict;
use warnings;
use base 'Form::Processor::Field::Select';
our $VERSION = '0.03';


sub init_options {
    my $i = 0;
    my @days = qw/
        Sunday
        Monday
        Tuesday
        Wednesday
        Thursday
        Friday
        Saturday
    /;
    return [
        map {
            {   value => $i++, label => $_ }
        } @days
    ];
}


=head1 NAME

Form::Processor::Field::Weekday - Select valid day of the week

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

Creates an option list for the days of the week.

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "select".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: "Select".

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
