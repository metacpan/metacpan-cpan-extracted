use strict;
use warnings;
package WebService::SendGrid::Newsletter::Recipients;

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

    $self->_check_required_args([ qw( name list ) ], %args);

    $self->{sgn}->_send_request('recipients/add', %args);
}


sub get {
    my ($self, %args) = @_;

    $self->_check_required_args([ qw( name ) ], %args);
    
    $self->{sgn}->_send_request('recipients/get', %args);
}


sub delete {
    my ($self, %args) = @_;

    $self->_check_required_args([ qw( name list ) ], %args);
    
    $self->{sgn}->_send_request('recipients/delete', %args);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::SendGrid::Newsletter::Recipients

=head1 VERSION

version 0.02

=head1 METHODS

=head2 new

Creates a new instance of WebService::SendGrid::Newsletter::Recipients.

    my $recipients = WebService::SendGrid::Newsletter::Recipients->new(sgn => $sgn);

Parameters:

=over 4

=item * C<sgn>

An instance of WebService::SendGrid::Newsletter.

=back

=head2 add

Assigns a recipients list to a newsletter.

Parameters:

=over 4

=item * C<name>

B<(Required)> The name of the newsletter.

=item * C<list>

B<(Required)> The name of the recipients list.

=back

=head2 get

Retrieves all recipient lists assigned to the specified newsletter.

Parameters:

=over 4

=item * C<name>

B<(Required)> The name of the newsletter for which to retrieve lists.

=back

=head2 delete

Removes a recipient list from the specified newsletter.

Parameters:

=over 4

=item * C<name>

B<(Required)> The name of the newsletter from which to remove the list.

=item * C<list>

B<(Required)> The name of the list to be removed.

=back

=head1 AUTHOR

Michal Wojciechowski <odyniec@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Michal Wojciechowski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
