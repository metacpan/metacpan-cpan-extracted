package Form::Processor::Field::DateTimeDMYHM2;
use strict;
use warnings;
use base 'Form::Processor::Field';
use Form::Processor;
use DateTime;
our $VERSION = '0.03';

# This implements a field made up of sub fields.

sub init_widget { 'Compound' }


# This is to keep from reporting missing field
# for required fields.  Any missing data errors will propogate up.
sub any_input { 1 }


# Create a sub-form that contains the fields that make up this compound field.
sub init {
    my $self = shift;

    $self->SUPER::init(@_);

    my $name = $self->name;

    my $required = $self->required ? 'required' : 'optional';

    $self->sub_form(
        Form::Processor->new(
            parent_field => $self,  # send all errors to parent field.
            profile => {
                optional=> {
                    day     => 'MonthDay',
                    month   => 'MonthName',
                    year    => 'Year',
                    hour    => 'Hour',
                    minute  => 'Minute',
                },
            },
        )
    );

    return;
}



sub validate {
    my $self = shift;

    return unless $self->SUPER::validate;

    my $form = $self->sub_form;

    # First validate the sub fields, passing in the original parameters
    return unless $form->validate( scalar $self->form->params );


    # This probably should be done in input_to_value()
    my %date = map { $_ => $form->field($_)->value } qw/ day month year hour minute /;

    my $dt;
    eval {  $dt = DateTime->new( %date, time_zone => 'floating' ) };

    if ( $@ ) {
        my $error = $@;
        $error =~ s! at /.+$!!; # ! vim
        $self->add_error( "Invalid date [_1]", "$error" );
        return;
    }

    $self->temp( $dt );

    return 1;
}

sub input_to_value {
    my $field = shift;
    $field->value( $field->temp );
}

sub format_value {
    my $self = shift;


    my $name = $self->name;

    my %hash;

    my $dt = $self->value || return ();


    for my $sub ( qw/ month day year hour minute / ) {

        $hash{ $name . '.' . $sub } = $dt->$sub;
    }

    return %hash;
}


=head1 NAME

Form::Processor::Field::DateTimeDMYHM2 - DEPRECATED example of a sub-form

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

This is a compound field tht is created as a form with multiple fields.
This is not well tested and should only be used after extensive testing.
It's more of an example than a real field.

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "compound".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: "Field".

=head1 DEPENDENCIES

L<DateTime>

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



