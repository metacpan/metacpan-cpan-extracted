package XML::Chain::Element;

use warnings;
use strict;
use utf8;
use 5.010;

our $VERSION = '0.06';

use Moose;
use MooseX::Aliases;
use Carp qw(croak);

extends qw(XML::Chain::Selector);

use overload '""' => \&XML::Chain::Selector::as_string, fallback => 1;

has '_xc_el_data' => (is => 'ro', isa => 'HashRef',    required => 1);
has '_xc'         => (is => 'rw', isa => 'XML::Chain', required => 1);

sub as_xml_libxml    {return $_[0]->{_xc_el_data}->{lxml};}
sub name             {return $_[0]->{_xc_el_data}->{lxml}->nodeName;}
sub current_elements {return [$_[0]->_xc_el_data];}

1;

__END__

=encoding utf8

=head1 NAME

XML::Chain::Element - helper class for XML::Chain representing single element

=head1 SYNOPSIS

    xc('body')->c(h1)->t('title')->root

=head1 DESCRIPTION

Returned by L<XML::Chain::Selector/single> call.

=head1 METHODS

=head2 name

return element name

=head2 as_xml_libxml

Returns L<XML::LibXML::Element> object.

=head2 XML::Chain::Selector methods

All of the L<XML::Chain::Selector> methods works too.

=head1 AUTHOR

Jozef Kutej

=head1 COPYRIGHT & LICENSE

Copyright 2017 Jozef Kutej, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
