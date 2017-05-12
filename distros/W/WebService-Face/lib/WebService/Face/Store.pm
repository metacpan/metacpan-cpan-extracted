package WebService::Face::Store;

use 5.006;
use strict;
use warnings;

use Storable;

=head1 NAME

WebService::Face::Store

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

WebService::Face::Store wraps the data returned by the server for account data
(limits, users, namespacs)

It provides a simple OO interface to access the data

For a better understanding of the data structure you can read :

=over 4

=item * L<http://developers.face.com/docs/api/account-limits/>

=item * L<http://developers.face.com/docs/api/account-users/>

=item * L<http://developers.face.com/docs/api/account-namespaces/>

=back

=head1 SUBROUTINES/METHODS

=head2 new ( \%params )

The constructor for the WebService::Face::Store class

=cut

sub new {
    my $class = shift;
    my $params = shift || {};

    my $self = bless {}, $class;

    for my $key ( keys %$params ) {
        $self->{$key} = $params->{$key};
    }

    return $self;
}

=head2 create_user ()

Getter for the 'create_user' attribute

=cut

sub create_user {
    my $self = shift;
    my $user = shift;

    my $exist = exists $self->{_data}{USER}{$user};

    $self->{_data}{USER}{$user} = 1;

    return !$exist;
}

=head2 delete_user ()

Getter for the 'delete_user' attribute

=cut

sub delete_user {
    my $self = shift;
    my $user = shift;

    my $exist = $self->{_data}{USER}{$user};

    delete $self->{_data}{USER}{$user};

    return $exist;
}

=head2 list_users ()

Getter for the 'list_users' attribute

=cut

sub list_users {
    my $self = shift;
    my $user = shift;

    return keys %{ $self->{_data}{USER} };
}

=head2 train_user ()

Getter for the 'train_user' attribute

=cut

sub train_user {
    my $self  = shift;
    my $user  = shift;
    my $photo = shift;

    push @{$self->{_data}{PHOTO}{$user}}, $photo;
    
    return scalar  @{$self->{_data}{PHOTO}{$user}};
}

=head2 get_user ()

Getter for the 'get_user' attribute

=cut

sub get_user {
    my $self = shift;

    return $self->{'get_user'};
}

=head2 set_user ()

Getter for the 'set_user' attribute

=cut

sub set_user {
    my $self = shift;

    return $self->{'set_user'};
}

=head2 recognize_user ()

Getter for the 'recognize_user' attribute

=cut

sub recognize_user {
    my $self = shift;

    return $self->{'recognize_user'};
}

=head2 save ()

Getter for the 'save' attribute

=cut

sub save {
    my $self     = shift;
    my $filename = shift;

    $filename =~ s/[^a-zA-Z\d_]//g;

    store $self, "$filename" or die "Can't save Store ($!)";
}

=head2 restore ()

Getter for the 'restore' attribute

=cut

sub restore {
    my $self     = shift;
    my $filename = shift;

    $self = retrieve($filename) or die "Can't restore store ($!)";
}

=head1 AUTHOR

Arnaud (Arhuman) ASSAD, C<< <arhuman at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C< arhuman at gmail.com>, or through
the web interface at L<https://github.com/arhuman/WebService-Face/issues>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Face::Client

You can also look for information at:

=over 4

=item * Github repository

L<https://github.com/arhuman/WebService-Face>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Face>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-Face>

=back

More information about Face.com service :

L<http://developers.face.com/docs/api>

=head1 ACKNOWLEDGEMENTS

Thanks to Face.com for the service they provide.
Thanks to Jaguar Network for allowing me to publish my work.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Arnaud (Arhuman) ASSAD.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
