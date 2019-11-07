package XML::NewsML_G2::Role::Writer_2_28;

use Moose::Role;
use namespace::autoclean;

has 'schema_location',
    isa     => 'Str',
    is      => 'ro',
    default => 'http://iptc.org/std/nar/2006-10-01/';
has 'g2_catalog_url',
    isa => 'Str',
    is  => 'ro',
    default =>
    'http://www.iptc.org/std/catalog/catalog.IPTC-G2-Standards_34.xml';

1;
__END__

=head1 NAME

XML::NewsML_G2::Role::Writer_2_18 - create XML DOM tree conforming to version 2.18 of the NewsML-G2 specification

Check the documentation of L<XML::NewsML_G2::Writer> for details.

=head1 AUTHOR

Philipp Gortan  C<< <philipp.gortan@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013-2014, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
