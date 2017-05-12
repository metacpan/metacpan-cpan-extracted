use strict;
use warnings;
package WebService::SendGrid::Newsletter::Schedule;

use parent 'WebService::SendGrid::Newsletter::Base';


sub new {
    my ($class, %args) = @_;

    my $self = {};
    bless($self, $class);
    
    $self->{sgn} = $args{sgn};
    
    return $self;
}


sub add {
    my ($self, %args) = @_;

    $self->_check_required_args([ qw( name ) ], %args);

    $self->{sgn}->_send_request('schedule/add', %args);
}


sub get {
    my ($self, %args) = @_;

    $self->_check_required_args([ qw( name ) ], %args);

    $self->{sgn}->_send_request('schedule/get', %args);
}


sub delete {
    my ($self, %args) = @_;
    
    $self->_check_required_args([ qw( name ) ], %args);

    $self->{sgn}->_send_request('schedule/delete', %args);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::SendGrid::Newsletter::Schedule

=head1 VERSION

version 0.02

=head1 METHODS

=head2 new

Creates a new instance of WebService::SendGrid::Newsletter::Schedule.

    my $schedule = WebService::SendGrid::Newsletter::Schedule->new(sgn => $sgn);

Parameters:

=over 4

=item * C<sgn>

An instance of WebService::SendGrid::Newsletter.

=back

=head2 add

Schedules a delivery time for an existing newsletter.

Parameters:

=over 4

=item * C<name>

B<(Required)> The name of the newsletter to schedule delivery for.

=item * C<at>

Date/time of the scheduled delivery (must be provided in the
C<YYYY-MM-DDTHH:MM:SS+-HH:MM> format).

=item * C<after>

The number of minutes until delivery time (must be positive).

=back

=head2 get

Retrieves the scheduled delivery time for an existing newsletter.

Parameters:

=over 4

=item * C<name>

B<(Required)> The name of the newsletter for which to retrieve the scheduled
delivery time.

=back

=head2 delete

Removes a scheduled send for a newsletter.

Parameters:

=over 4

=item * C<name>

B<(Required)> The name of the newsletter for which to remove the scheduled
delivery time.

=back

=head1 AUTHOR

Michal Wojciechowski <odyniec@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Michal Wojciechowski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
