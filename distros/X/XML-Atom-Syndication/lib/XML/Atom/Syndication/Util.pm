package XML::Atom::Syndication::Util;
use strict;

use vars qw( @EXPORT_OK );
@EXPORT_OK = qw( utf8_off nodelist );

use base qw( Exporter );

sub utf8_off {
    if ($] > 5.008 && defined $_[0]) {
        require Encode;
        Encode::_utf8_off($_[0]);
    }
    $_[0];
}

sub nodelist {
    my ($node, $ns, $name) = @_;
    my @nodes =
      grep { ref($_) eq 'XML::Elemental::Element' && $_->name eq "{$ns}$name" }
      @{$node->elem->contents};
    @nodes;
}

1;
