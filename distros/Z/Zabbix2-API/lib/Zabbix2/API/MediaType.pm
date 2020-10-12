package Zabbix2::API::MediaType;

use strict;
use warnings;
use 5.010;
use Carp;

use Moo;
extends qw/Exporter Zabbix2::API::CRUDE/;

use constant {
    MEDIA_TYPE_EMAIL => 0,
    MEDIA_TYPE_EXEC => 1,
    MEDIA_TYPE_SMS => 2,
    MEDIA_TYPE_JABBER => 3,
    MEDIA_TYPE_EZ_TEXTING => 100,
};

our @EXPORT_OK = qw/
MEDIA_TYPE_EMAIL
MEDIA_TYPE_EXEC
MEDIA_TYPE_SMS
MEDIA_TYPE_JABBER
MEDIA_TYPE_EZ_TEXTING/;

our %EXPORT_TAGS = (
    media_types => [
        qw/MEDIA_TYPE_EMAIL
        MEDIA_TYPE_EXEC
        MEDIA_TYPE_SMS
        MEDIA_TYPE_JABBER
        MEDIA_TYPE_EZ_TEXTING/
    ],
);

sub id {
    ## mutator for id
    my ($self, $value) = @_;
    if (defined $value) {
        $self->data->{mediatypeid} = $value;
        return $self->data->{mediatypeid};
    } else {
        return $self->data->{mediatypeid};
    }
}

sub _prefix {
    my (undef, $suffix) = @_;
    if ($suffix) {
        return 'mediatype'.$suffix;
    } else {
        return 'mediatype';
    }
}

sub _extension {
    return (output => 'extend');
}

sub name {
    my $self = shift;
    return $self->data->{description} || '???';
}

sub type {
    my $self = shift;
    return $self->data->{type};
}

1;
__END__
=pod

=head1 NAME

Zabbix2::API::MediaType -- Zabbix media type objects

=head1 SYNOPSIS

  use Zabbix2::API::MediaType;
  # fetch a meda type by name
  my $mediatype = $zabbix->fetch('MediaType', params => { filter => { description => "My Media Type" } })->[0];
  
  # and update it
  
  $mediatype->data->{exec_path} = 'my_notifier.pl';
  $mediatype->push;

=head1 DESCRIPTION

Handles CRUD for Zabbix media_type objects.

This is a subclass of C<Zabbix2::API::CRUDE>; see there for inherited methods.

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

L<Zabbix2::API::CRUDE>.

=head1 AUTHOR

Ray Link; maintained by Fabrice Gabolde <fga@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 SFR

This library is free software; you can redistribute it and/or modify it under
the terms of the GPLv3.

=cut
