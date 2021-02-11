package XML::Loy::HostMeta;
use strict;
use warnings;

use XML::Loy with => (
  prefix => 'hm',
  namespace => 'http://host-meta.net/xrd/1.0'
);

use Carp qw/carp/;

# No constructor
sub new {
  carp 'Only use ' . __PACKAGE__ . ' as an extension to XRD';
  return;
};

# host information
sub host {
  my $self = shift->root->at('*');

  unless ($_[0]) {
    my $h = $self->at('Host') or return;
    return $h->all_text;
  };

  # Set hist information
  return $self->set(Host => shift);
};


1;


__END__

=pod

=head1 NAME

XML::Loy::HostMeta - HostMeta Extension for XRD


=head1 SYNOPSIS

  use XML::Loy::XRD;

  my $xrd = XML::Loy::XRD->new;
  $xrd->extension(-HostMeta);

  $xrd->subject('http://sojolicious.example/');
  $xrd->host('sojolicious.example');

  print $xrd->to_pretty_xml;

  # <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  # <XRD xmlns="http://docs.oasis-open.org/ns/xri/xrd-1.0"
  #      xmlns:hm="http://host-meta.net/xrd/1.0"
  #      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  #   <Subject>http://sojolicious.example/</Subject>
  #   <hm:Host>sojolicious.example</hm:Host>
  # </XRD>


=head1 DESCRIPTION

L<XML::Loy::HostMeta> is an extension
to L<XML::Loy::XRD> and provides addititional
functionality for the work with
L<HostMeta|https://tools.ietf.org/html/rfc6415>
documents.


=head1 METHODS

L<XML::Loy::HostMeta> inherits all methods
from L<XML::Loy> and implements the following new ones.


=head2 host

  $xrd->host('sojolicious.example');
  print $xrd->host;

Sets or returns host information of the xrd.
The support of this element was removed from
the specification in draft C<09>.


=head1 DEPENDENCIES

L<Mojolicious>.


=head1 AVAILABILITY

  https://github.com/Akron/XML-Loy


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2021, L<Nils Diewald|https://www.nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the same terms as Perl.

=cut
