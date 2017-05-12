package XML::DOM::Lite::Serializer;

use XML::DOM::Lite::Constants qw(:all);

sub new {
    my $class = shift;
    return bless { }, $class;
}

sub serializeToString {
    my ($self, $node) = @_;
    unless (ref $self) {
        $self = __PACKAGE__->new;
    }
    if ($node->nodeType == DOCUMENT_NODE) {
        $node = $node->firstChild;
    }

    $self->{_indent_level} = 0 unless defined $self->{_indent_level};

    my $out = "";
    if ($node->nodeType == ELEMENT_NODE) {
        $out .= "\n".$self->_mkIndent()."<".$node->tagName;
        foreach my $att (@{$node->attributes}) {
            $out .= " $att->{nodeName}=\"".$att->{nodeValue}."\"";
        }
        if ($node->childNodes->length) {
            $out .= ">";
            $self->{_indent_level}++;
            foreach my $n (@{$node->childNodes}) {      
                $out .= $self->serializeToString($n);
            }
            $self->{_indent_level}--;
            $out .= "\n".$self->_mkIndent()."</".$node->tagName.">";
        } else {
            $out .= " />";
        }
    }
    elsif ($node->nodeType == TEXT_NODE) {
        $out .= "\n".$self->_mkIndent().$node->nodeValue;
    }

    return $out;
}

sub _mkIndent {
    my ($self) = @_;
    return (" " x (2 * $self->{_indent_level}));
}
1;
