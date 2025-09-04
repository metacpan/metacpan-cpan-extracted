package Zabbix7::API::MediaType;

use strict;
use warnings;
use 5.010;
use Carp;

use Moo;
extends qw/Exporter Zabbix7::API::CRUDE/;

use constant {
    MEDIA_TYPE_EMAIL => 0,
    MEDIA_TYPE_EXEC => 1,
    MEDIA_TYPE_SMS => 2,
    MEDIA_TYPE_JABBER => 3, # Deprecated in Zabbix 7.0
    MEDIA_TYPE_EZ_TEXTING => 100,
    MEDIA_TYPE_WEBHOOK => 4, # Added for Zabbix 7.0
    MEDIA_TYPE_SLACK => 10,  # Added for Zabbix 7.0
    MEDIA_TYPE_TELEGRAM => 11, # Added for Zabbix 7.0
    MEDIA_TYPE_MS_TEAMS => 12, # Added for Zabbix 7.0
};

our @EXPORT_OK = qw/
    MEDIA_TYPE_EMAIL
    MEDIA_TYPE_EXEC
    MEDIA_TYPE_SMS
    MEDIA_TYPE_JABBER
    MEDIA_TYPE_EZ_TEXTING
    MEDIA_TYPE_WEBHOOK
    MEDIA_TYPE_SLACK
    MEDIA_TYPE_TELEGRAM
    MEDIA_TYPE_MS_TEAMS
/;

our %EXPORT_TAGS = (
    media_types => [
        qw/MEDIA_TYPE_EMAIL
           MEDIA_TYPE_EXEC
           MEDIA_TYPE_SMS
           MEDIA_TYPE_JABBER
           MEDIA_TYPE_EZ_TEXTING
           MEDIA_TYPE_WEBHOOK
           MEDIA_TYPE_SLACK
           MEDIA_TYPE_TELEGRAM
           MEDIA_TYPE_MS_TEAMS/
    ],
);

sub id {
    my ($self, $value) = @_;
    if (defined $value) {
        $self->data->{mediatypeid} = $value;
        Log::Any->get_logger->debug("Set mediatypeid: $value for media type");
        return $self->data->{mediatypeid};
    }
    my $id = $self->data->{mediatypeid};
    Log::Any->get_logger->debug("Retrieved mediatypeid for media type: " . ($id // 'none'));
    return $id;
}

sub _readonly_properties {
    return {
        mediatypeid => 1,
        status => 1, # Added for Zabbix 7.0 (read-only)
    };
}

sub _prefix {
    my (undef, $suffix) = @_;
    return 'mediatype' . ($suffix // '');
}

sub _extension {
    return (
        output => 'extend',
        selectMessageTemplates => 'extend', # Added for Zabbix 7.0
    );
}

sub name {
    my $self = shift;
    my $name = $self->data->{description} || '???';
    Log::Any->get_logger->debug("Retrieved name for media type ID: " . ($self->id // 'new') . ": $name");
    return $name;
}

sub type {
    my $self = shift;
    my $type = $self->data->{type};
    Log::Any->get_logger->debug("Retrieved type for media type ID: " . ($self->id // 'new') . ": " . ($type // 'none'));
    return $type;
}

before 'create' => sub {
    my ($self) = @_;
    delete $self->data->{mediatypeid}; # Ensure mediatypeid is not sent
    delete $self->data->{status};     # status is read-only
    Log::Any->get_logger->debug("Preparing to create media type: " . ($self->data->{description} // 'unknown'));
};

before 'update' => sub {
    my ($self) = @_;
    delete $self->data->{status}; # status is read-only
    Log::Any->get_logger->debug("Preparing to update media type ID: " . ($self->id // 'new'));
};

1;
__END__
=pod

=head1 NAME

Zabbix7::API::MediaType -- Zabbix media type objects

=head1 SYNOPSIS

  use Zabbix7::API::MediaType;
  # fetch a meda type by name
  my $mediatype = $zabbix->fetch('MediaType', params => { filter => { description => "My Media Type" } })->[0];
  
  # and update it
  
  $mediatype->data->{exec_path} = 'my_notifier.pl';
  $mediatype->push;

=head1 DESCRIPTION

Handles CRUD for Zabbix media_type objects.

This is a subclass of C<Zabbix7::API::CRUDE>; see there for inherited methods.

=head1 METHODS

=over 4

=item name()

Accessor for the media type's name (the "description" attribute); returns the
empty string if no description is set, for instance if the media type
has not been created on the server yet.

=item type()

Accessor for the media type's type.

=back

=head1 EXPORTS

Some constants:

  MEDIA_TYPE_EMAIL
  MEDIA_TYPE_EXEC
  MEDIA_TYPE_SMS
  MEDIA_TYPE_JABBER
  MEDIA_TYPE_EZ_TEXTING

These are used to specify the media type's type.  They are not exported by
default, only on request; or you could import the C<:media_types> tag.

=head1 SEE ALSO

L<Zabbix7::API::CRUDE>.

=head1 AUTHOR

SCOTTH

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, 2012, 2013, 2014 SFR
Copyright (C) 2020 Fabrice Gabolde
Copyright (C) 2025 ScottH

This library is free software; you can redistribute it and/or modify it under
the terms of the GPLv3.

=cut
