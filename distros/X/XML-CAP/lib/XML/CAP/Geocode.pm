# XML::CAP::Geocode - class for XML::CAP <geocode> element classes
# Copyright 2009 by Ian Kluft
# This is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.
#
# parts derived from XML::Atom::Feed

package XML::CAP::Geocode;
use strict;
use warnings;
use base qw( XML::CAP::Base );
use XML::CAP;

# inherits initialize() from XML::CAP::Base

sub element_name { 'geocode' }

# make accessors
__PACKAGE__->mk_elem_accessors(qw( valueName value ));

1;
