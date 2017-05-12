use strict;
use warnings;
package WebService::SendGrid::Newsletter::Categories;

use parent 'WebService::SendGrid::Newsletter::Base';


sub new {
    my ($class, %args) = @_;

    my $self = {};
    bless($self, $class);

    $self->{sgn} = $args{sgn};

    return $self;
}


sub create {
    my ($self, %args) = @_;

    $self->_check_required_args([ qw( category ) ], %args);

    return $self->{sgn}->_send_request('category/create', %args);
}


sub add {
    my ($self, %args) = @_;

    $self->_check_required_args([ qw( category name ) ], %args);

    return $self->{sgn}->_send_request('category/add', %args);
}


sub list {
    my ($self, %args) = @_;

    return $self->{sgn}->_send_request('category/list', %args);
}


sub remove {
    my ($self, %args) = @_;

    $self->_check_required_args([ qw( name ) ], %args);

    return $self->{sgn}->_send_request('category/remove', %args);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::SendGrid::Newsletter::Categories

=head1 VERSION

version 0.02

=head1 METHODS

=head2 new

Creates a new instance of WebService::SendGrid::Newsletter::Categories.

    my $lists = WebService::SendGrid::Newsletter::Categories->new(sgn => $sgn);

Parameters:

=over 4

=item * C<sgn>

An instance of WebService::SendGrid::Newsletter.

=back

=head2 create

Creates a new category.

Parameters:

=over 4

=item * C<category>

B<(Required)> The name of the new category.

=back

=head2 add

Assigns a category to an existing newsletter.

Parameters:

=over 4

=item * C<category>

B<(Required)> The name of the category to be added to the newsletter.

=item * C<name>

B<(Required)> The name of the newsletter to add the category to.

=back

=head2 list

Lists all categories or check if a specific category exists.

Parameters:

=over 4

=item * C<category>

The name of the category to check.

=back

=head2 remove

Removes a specific category, or all categories from a newsletter.

Parameters:

=over 4

=item * C<name>

B<(Required)> The name of the newsletter to remove categories from.

=item * C<category>

The name of the category to be removed. If not specified, all categories will be
removed.

=back

=head1 AUTHOR

Michal Wojciechowski <odyniec@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Michal Wojciechowski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
