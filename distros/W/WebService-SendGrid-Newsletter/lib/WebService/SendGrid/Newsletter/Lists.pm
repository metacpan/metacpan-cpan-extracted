use strict;
use warnings;
package WebService::SendGrid::Newsletter::Lists;

use WebService::SendGrid::Newsletter::Lists::Email;
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

    $self->_check_required_args([ qw( list ) ], %args);

    return $self->{sgn}->_send_request('lists/add', %args);
}


sub get {
    my ($self, %args) = @_;

    return $self->{sgn}->_send_request('lists/get', %args);
}


sub edit {
    my ($self, %args) = @_;

    $self->_check_required_args([ qw( list newlist ) ], %args);

    return $self->{sgn}->_send_request('lists/edit', %args);
}


sub delete {
    my ($self, %args) = @_;

    $self->_check_required_args([ qw( list ) ], %args);

    return $self->{sgn}->_send_request('lists/delete', %args);
}


sub email {
    my ($self) = @_;
    
    if (!defined $self->{email}) {
        $self->{email} = WebService::SendGrid::Newsletter::Lists::Email->new(
            sgn => $self->{sgn}
        );
    }
    
    return $self->{email};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::SendGrid::Newsletter::Lists

=head1 VERSION

version 0.02

=head1 METHODS

=head2 new

Creates a new instance of WebService::SendGrid::Newsletter::Lists.

    my $lists = WebService::SendGrid::Newsletter::Lists->new(sgn => $sgn);

Parameters:

=over 4

=item * C<sgn>

An instance of WebService::SendGrid::Newsletter.

=back

=head2 add

Creates a new recipient list.

Parameters:

=over 4

=item * C<list>

B<(Required)> The name of the new recipient list.

=item * C<name>

The name of the column for the name associated with email address.

=back

=head2 get

Retrieves all recipient lists or checks if a specific list exists.

Parameters:

=over 4

=item * C<list>

The name of the list to retrieve.

=back

=head2 edit

Renames a list.

Parameters:

=over 4

=item * C<list>

B<(Required)> The existing name of the list.

=item * C<newlist>

B<(Required)> The new name for the list.

=back

=head2 delete

Deletes a list.

Parameters:

=over 4

=item * C<list>

B<(Required)> The name of the list to be deleted.

=back

=head2 email

Returns an instance of WebService::SendGrid::Newsletter::Lists::Email.

=head1 AUTHOR

Michal Wojciechowski <odyniec@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Michal Wojciechowski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
