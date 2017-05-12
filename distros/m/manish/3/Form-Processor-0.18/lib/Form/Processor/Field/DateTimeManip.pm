package Form::Processor::Field::DateTimeManip;
use strict;
use warnings;
use base 'Form::Processor::Field';
use DateTime::Format::DateManip;
our $VERSION = '0.03';

my %date;


sub validate {
    my ( $self ) = @_;

    return unless $self->SUPER::validate;


    my $dt = DateTime::Format::DateManip->parse_datetime( $self->input );

    unless ( $dt ) {
        $self->add_error( "Sorry, don't understand date" );
        return;
    }

    # Manip sets the time zone to the local timezone (or what's globally set)
    # which means if the zone is later changed then the time will change.
    # So change it to a floating so if validation sets the timezone the
    # time won't change.
    # ** But fails if a timezone is specified on input **
    # so really need to parse at a later time.

    # $dt->set_time_zone( 'floating' );

    $self->temp( $dt );

    return 1;
}

sub input_to_value {
    my $field = shift;
    $field->value( $field->temp );
}

sub format_value {
    my $self = shift;

    return unless my $value = $self->value;
    die "Value is not a DateTime" unless $value->isa('DateTime');

    my $d = $value->strftime( '%a, %b %e %Y %l:%M %p %Z' );

    # The calendar javascript popup can't parse the day & hour with a leading space,
    # so remove.
    $d =~ s/\s(\s\d:)/$1/;
    $d =~ s/\s(\s\d\s\d{4})/$1/;


    return ($self->name => $d );

}


=head1 NAME

Form::Processor::Field::DateTimeManip - Free-form date/time input

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

This field uses the scary and bloated L<Date::Manip> module to allow
free-form date input (e.g. "Last Tuesday in December").

IIRC, timezone handling in Date::Manip is broken.

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "text".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: "Field".

=head1 DEPENDENCIES

L<DateTime>, L<DateTime::Format::DateManip>

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

