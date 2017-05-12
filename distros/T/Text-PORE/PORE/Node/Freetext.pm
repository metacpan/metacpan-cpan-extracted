# Freetextnode -- unparsed HTML node
# text (scalar): unparsed HTML text
package Text::PORE::Node::Freetext;

use Text::PORE::Node;
use strict;

@Text::PORE::Node::Freetext::ISA = qw(Text::PORE::Node);

sub new {
    my $type = shift;
    my $lineno = shift;
    my $text = shift;

    my $self = bless {}, ref($type) || $type;

    $self = $self->SUPER::new($lineno);
    $self->setText($text);

    bless $self, ref($type) || $type;
}

sub setText {
    my $self = shift;
    my $text = shift;

    $self->{'text'} = $text;
}

sub appendText {
    my $self = shift;
    my $text = shift;

    $self->{'text'} .= $text;
}
	
    
sub traverse {
    my $self = shift;
    my $globals = shift;

    my $return = '';

    $return .= "[Freetext:$self->{'lineno'}]" if $self->getDebug();
    $return .= $self->{'text'} if (defined $self->{'text'});

    $self->output($return);

    # note - currently this will never have any errors in it, but if we
    #  generate errors in the future, we would want to have this
    $self->errorDump();
}

1;
