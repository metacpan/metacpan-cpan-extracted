# AttrNode -- construct containing type and attribute-value pairs
#  ("abstract class")
# tag_type (scalar): type of tag
# pairs (hash): attribute-value pairs
package Text::PORE::Node::Attr;

use Text::PORE::Node;
use strict;

@Text::PORE::Node::Attr::ISA = qw(Text::PORE::Node);

sub new  {
    my $type = shift;
    my $lineno = shift;
    my $tag_type = shift;
    my $pairs = shift;

    my $self = bless {}, ref($type) || $type;

    $self = $self->SUPER::new($lineno);

    $self->{'tag_type'} = $tag_type;
    $self->{'attrs'} = $pairs;
    # TODO debugging
    #print ("$lineno ", map ("$_:$$pairs{$_}\n", keys %$pairs));

    bless $self, ref($type) || $type;
}

1;
