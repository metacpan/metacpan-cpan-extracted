package XML::RSS::LibXML::V0_92;
use strict;
use warnings;
use base qw(XML::RSS::LibXML::V0_91);

# Should be compatible with 0.91.
# See http://backend.userland.com/rss092

sub parse_dom
{
    my $self = shift;
    my $c    = shift;
    my $dom  = shift;

    $c->reset;
    $c->version('0.92');
    $c->encoding($dom->encoding);
    $self->parse_namespaces($c, $dom);
    $self->parse_channel($c, $dom);
    $self->parse_items($c, $dom);
}

1;
