# Copyright (C) 2004 Identity Commons.  All Rights Reserved.
# See LICENSE for licensing details

# Author: Eugene Eric Kim <eekim@blueoxen.org>

package XRI::Descriptor::LocalAccess;

our $VERSION = 0.1;

sub new {
    bless {}, shift;
}

### accessors/mutators

sub service {
    my $self = shift;
    $self->{service} = shift if (@_);
    return $self->{service};
}

sub uris {
    my $self = shift;
    $self->{uris} = shift if (@_);
    return $self->{uris};
}

sub types {
    my $self = shift;
    $self->{types} = shift if (@_);
    return $self->{types};
}

1;
__END__

=head1 NAME

XRI::Descriptor::LocalAccess - Local access objects from an XRI Descriptor

=head1 SYNOPSIS

  use XRI::Descriptor::LocalAccess;

  my $localAccess = XRI::Descriptor::LocalAccess->new;
  $localAccess->service('xri:$r.a/X2R');  # sets service

  $localAccess->addType('text/html');     # sets media types
  $localAccess->addType('image/jpeg');

  $localAccess->uris(['http://www.idcommons.net/',
                      'http://www.2idi.com/']);

=head1 DESCRIPTION

XRI::Descriptor generates XRI::Descriptor::LocalAccess objects when
parsing an XRIDescriptor XML file.  These objects, described in the
XML Schema for XRIDescriptor, have three fields:

  service -- optional.  Indicates the type of service.

  URI -- 1 or more.  Indicates URIs at which service can be requested.

  type -- 0 or more.  MIME types for media supported by service.

=head1 METHODS

=head2 new()

Constructor.  Creates an unpopulated object.

=head2 Accessors/Mutators

  service($service)
  uris(\@uris)
  types(\@types)

=head1 AUTHOR

Eugene Eric Kim, E<lt>eekim@blueoxen.orgE<gt>

=head1 SEE ALSO

L<XRI::Descriptor>

=cut
