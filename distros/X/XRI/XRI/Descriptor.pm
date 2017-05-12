# Copyright (C) 2004 Identity Commons.  All Rights Reserved.
# See LICENSE for licensing details

# Authors:
#       Fen Labalme <fen@idcommons.net>
#       Eugene Eric Kim <eekim@blueoxen.org>

package XRI::Descriptor;

our $VERSION = 0.1;

use XRI::Descriptor::LocalAccess;
use XML::Smart;

sub new {
    my $self = shift;
    my $xml = shift;
    my $doc = XML::Smart->new( $xml );
    $doc = $doc->{XRIDescriptor};

    bless { doc=>$doc }, $self;
}

sub getResolved {
    my $self = shift;

    return $self->{doc}{Resolved};
}

# returns a reference to a list of URIs
#
sub getXRIAuthorityURIs {
    my $self = shift;

    return \@{$self->{doc}{XRIAuthority}{URI}};
}

sub getLocalAccess {
    my $self = shift;
    my ($service, $type) = @_;

    my @localAccessObjects;
    my @localAccessElements = @{$self->{doc}->{LocalAccess}};

    foreach my $element (@localAccessElements) {
        my $object = XRI::Descriptor::LocalAccess->new;
        $object->service($element->{Service}) if ($element->{Service});
        if (!$service || $object->service eq $service) {
            if ($element->{URI}) {
                # this conditional should be unnecessary if XML is valid.
                # according to the schema, there should always be at least
                # one URI per LocalAccess object.
                $object->uris($element->{URI});
            }
            $object->types($element->{Type}) if $element->{Type};
            if (!$type || grep(/^$type$/, $object->types)) {
                push @localAccessObjects, $object;
            }
        }
    }
    return @localAccessObjects;
}

sub getMappings {
    my $self = shift;

    return \@{$self->{doc}{Mapping}};
}

1;
__END__
=head1 NAME

XRI::Descriptor - Utilities for XRI Descriptor XML doc management

=head1 SYNOPSIS

    use XRI:Descriptor;
    my $XRID = XRI->new($xml_descriptor);

    $resolved = $XRID->getResolved;
    $AuthRef  = $XRID->getXRIAuthorityURIs;
    @uris     = $XRID->getLocalAccess($service, $type);
    $mapRef   = $XRID->getMappings;

=head1 ABSTRACT

Utilities for XRI Descriptor XML doc management

=head1 DESCRIPTION

This module provides utilities to pull element values from an XRI
Descriptor XML file.  Example XRI Descriptor XML file:

    <?xml version="1.0" encoding="iso-8859-1"?>
    <XRIDescriptor xmlns="xri:$r*s/XRIDescriptor">
      <Resolved>*user</Resolved>
      <XRIAuthority>
        <URI>http://community.broker.com/</URI>
      </XRIAuthority>
      <LocalAccess>
        <Service>xri:$r*a/XRIDB</Service>
        <URI>http://broker.com/xridb</URI>
      </LocalAccess>
      <Mapping>xri:@*:1002*(:1000:1000)</Mapping>
    </XRIDescriptor>

=head1 TODO

=over 4

=item *

Change getLocalAccess to return an array reference

=back

=head1 SEE ALSO

xri(3)

=head1 AUTHOR

Fen Labalme, E<lt>fen@idcommons.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 Identity Commons

See LICENSE.

=cut
