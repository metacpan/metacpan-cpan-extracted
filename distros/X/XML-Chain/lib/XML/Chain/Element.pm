package XML::Chain::Element;

use warnings;
use strict;
use utf8;
use 5.010;

our $VERSION = '0.07';

use parent qw(XML::Chain::Selector);
use Class::XSAccessor accessors => [qw(_xc_el_data)];
use Carp qw(croak);

use overload '""' => \&XML::Chain::Selector::as_string, fallback => 1;

sub new {
    my ( $class, @args ) = @_;
    my %args =
        ( ( @args == 1 ) && ( ref( $args[0] ) eq 'HASH' ) )
        ? %{ $args[0] }
        : @args;

    return bless {
        _xc_el_data => $args{_xc_el_data},
        _xc         => $args{_xc},
    }, $class;
}

sub as_xml_libxml    { return $_[0]->{_xc_el_data}->{lxml}; }
sub name             { return $_[0]->{_xc_el_data}->{lxml}->nodeName; }
sub current_elements { return [ $_[0]->_xc_el_data ]; }

1;

__END__

=encoding utf8

=head1 NAME

XML::Chain::Element - helper class for XML::Chain representing a single element

=head1 SYNOPSIS

    xc('body')->c('h1')->t('title')->root

=head1 DESCRIPTION

Returned by L<XML::Chain::Selector/single>.

=head1 METHODS

=head2 new

Creates a new element wrapper.

=head2 name

Returns the element name.

=head2 as_xml_libxml

Returns an L<XML::LibXML::Element> object.

=head2 current_elements

Returns the element wrapped in an array reference for internal consistency
with L<XML::Chain::Selector>. Selectors always work with arrays of elements,
and Element overrides this to return its single element as a 1-element array.

=head2 XML::Chain::Selector methods

All L<XML::Chain::Selector> methods work here as well.

=head1 AUTHOR

Jozef Kutej

=head1 COPYRIGHT & LICENSE

Copyright 2017 Jozef Kutej, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
