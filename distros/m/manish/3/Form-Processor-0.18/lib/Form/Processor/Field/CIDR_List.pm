package Form::Processor::Field::CIDR_List;
use strict;
use warnings;
use base 'Form::Processor::Field::Text';
our $VERSION = '0.03';

use Net::CIDR;


sub validate {
    my $self = shift;

    return unless $self->SUPER::validate;

    my $input = $self->input || return 1;

    for my $addr ( split /[^\d\.\/]+/, $input ) {
        eval { Net::CIDR::cidr2range( $addr ) };

        next unless $@;

        return $self->add_error( "Failed to parse address '$addr'" );
    }

    return 1;
}


=head1 NAME

Form::Processor::Field::CIDR_List - Muliplt CIDR addresses

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

Allow entry of multiple CIDR formatted IP addresses and masks.
This field simply splits and validates the addresses using L<Net::CIDR>.

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "text".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: "Text";

=head1 DEPENDENCIES

L<Net::CIDR>

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

