package WWW::VirtualPBX;

use strict;
use warnings;

use Carp;
use WWW::Mechanize;

our $VERSION = '0.01';

=head1 NAME

WWW::VirtualPBX - Scraping-based interface to VirtualPBX.com

=head1 SYNOPSIS

  use WWW::VirtualPBX;

  my $vpbx = WWW::VirtualPBX->new(
      phone     => '(888) 555-1212',
      extension => '123',
      password  => 'opensesame',
  );

  if ($vpbx->queue_status(2))
  {
      # I'm logged into queue ID #2
      $vpbx->queue_logout(2);
  }
  else
  {
      $vpbx->queue_login(2);
  }

=head1 DESCRIPTION

This module provides an object-oriented Perl interface (via screen-scraping) to VirtualPBX.com ACD queues.

=head1 METHODS

=head2 new

Returns a new WWW::VirtualPBX object.

Takes the following required parameters:

=over 4

=item * B<phone>

The telephone number for the VirtualPBX you wish to connect to.

=item * B<extension>

The extension number you wish to connect to.

=item * B<password>

The password for the extension number you wish to connect to.

=back

=cut

sub new
{
    my ($class, %args) = @_;

    croak "Phone number must be specified" unless $args{phone};
    croak "Extension must be specified"    unless $args{extension};
    croak "Password must be specified"     unless $args{password};

    my $self = {
        phone     => $args{phone},
        extension => $args{extension},
        password  => $args{password},
    };

    bless $self, $class;
    return $self;
};

=head2 queue_status

Given a queue ID number, returns 1 or 0 depending on whether you're logged into that queue.

=cut

sub queue_status
{
    my ($self, $queue_number) = @_;

    croak "No queue number provided" unless $queue_number;

    $self->_login unless $self->{mech};

    my $mech = $self->_get_queue_page;
    return $mech->value("queue_${queue_number}_login");
}

=head2 queue_login

Given a queue ID number, logs you into that queue.

=cut

sub queue_login
{
    my ($self, $queue_number) = @_;

    croak "No queue number provided" unless $queue_number;

    $self->_login unless $self->{mech};

    my $mech = $self->_get_queue_page;
    $mech->submit_form(
        with_fields => {
            "queue_${queue_number}_login" => 1,
            FormAction                  => 'Submit',
        }
    );
}

=head2 queue_logout

Given a queue ID number, logs you out of that queue.

=cut

sub queue_logout
{
    my ($self, $queue_number) = @_;

    croak "No queue number provided" unless $queue_number;

    $self->_login unless $self->{mech};

    my $mech = $self->_get_queue_page;
    $mech->submit_form(
        with_fields => {
            "queue_${queue_number}_login" => 0,
            FormAction                  => 'Submit',
        },
    );
}

sub _get_queue_page
{
    my ($self) = @_;

    $self->_login unless $self->{mech};

    my $mech = $self->{mech};
    $mech->uri =~ /BasicCallRouting/ ||
        $mech->follow_link(url_regex => qr/BasicCallRouting/i);
    return $mech;
}

sub _login
{
    my ($self, %args) = @_;

    my $mech = WWW::Mechanize->new;
    $mech->get("https://vconsole.virtualpbx.com/");
    $mech->form_name('frmLogin');
    $mech->submit_form(
        fields => {
           LoginPhone    => $self->{phone},
           LoginExt      => $self->{extension},
           LoginPassword => $self->{password},
        }
    );
    $self->{mech} = $mech;
    return $self->{mech} ? 1 : 0;
}

=head1 DEPENDENCIES

WWW::Mechanize

=head1 DISCLAIMER

The author of this module is not affiliated in any way with VirtualPBX.com. Users must follow the VirtualPBX.com terms of service when using this module.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 Michael Aquilina. All rights reserved.

This code is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Michael Aquilina, aquilina@cpan.org

Ohio-Pennsylvania Software, LLC

=cut

1;

