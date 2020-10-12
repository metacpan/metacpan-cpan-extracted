package Zabbix2::API::Application;

use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;

use Moo;
extends qw/Zabbix2::API::CRUDE/;

has 'items' => (is => 'ro',
                lazy => 1,
                builder => '_fetch_items');
has 'host' => (is => 'ro',
               lazy => 1,
               builder => '_fetch_host');

sub id {
    ## mutator for id
    my ($self, $value) = @_;
    if (defined $value) {
        $self->data->{applicationid} = $value;
        return $self->data->{applicationid};
    } else {
        return $self->data->{applicationid};
    }
}

sub _readonly_properties {
    return {
        applicationid => 1,
        # 2.2 uses templateids, 2.0 uses templateid, neither are updatable
        templateids => 1,
        templateid => 1,
    };
}

sub _prefix {
    my (undef, $suffix) = @_;
    if ($suffix) {
        return 'application'.$suffix;
    } else {
        return 'application';
    }
}

sub _extension {
    return (output => 'extend');
}

sub name {
    my $self = shift;
    return $self->data->{name} || '???';
}

sub _fetch_items {
    my $self = shift;
    my $items = $self->{root}->fetch('Item', params => { applicationids => [ $self->id ] });
    return $items;
}

sub _fetch_host {
    my $self = shift;
    my $host = $self->{root}->fetch_single('Host', params => { hostids => [ $self->data->{hostid} ] });
    return $host;
}

before 'update' => sub {
    # you can create an Application with a hostid, but you can never
    # update it
    my ($self) = @_;
    delete $self->data->{hostid};
};

1;
__END__
=pod

=head1 NAME

Zabbix2::API::Application -- Zabbix application objects

=head1 SYNOPSIS

  # fetch a single app
  my $app = $zabber->fetch_single('Application',
                                  params => { filter => { name => 'CPU' },
                                              hostids => [ 12345 ] });
  # get its parent host (costs one API call)
  my $host = $app->host;
  # get its child items
  my $items = $app->items;

=head1 DESCRIPTION

Handles CRUD for Zabbix application objects.

This is a subclass of C<Zabbix2::API::CRUDE>; see there for inherited
methods.

=head1 ATTRIBUTES

=head2 host

(read-only L<Zabbix2::API::Host> object)

This attribute is lazily populated from the application's host from
the server.

=head2 items

(read-only arrayref of L<Zabbix2::API::Item> objects)

This attribute is lazily populated from the application's items from
the server.

=head1 SEE ALSO

L<Zabbix2::API::CRUDE>

=head1 AUTHOR

Fabrice Gabolde <fga@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Fabrice Gabolde

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
