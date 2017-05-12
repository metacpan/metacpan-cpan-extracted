package XML::RSS::Private::Output::V0_9;

use strict;
use warnings;

use vars (qw(@ISA));

use XML::RSS::Private::Output::Base;

@ISA = (qw(XML::RSS::Private::Output::Base));

sub _get_rdf_decl
{
    return
    qq{<rdf:RDF\nxmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"\n} .
    qq{xmlns="http://my.netscape.com/rdf/simple/0.9/">\n\n};
}

# 'description' for item does not exist in RSS 0.9
sub _out_item_desc {
    return;
}

# RSS 0.9 does not support the language tag so we nullify this tag.
sub _out_language {
    return;
}

sub _output_rss_middle {
    my $self = shift;

    $self->_end_channel();
    $self->_output_main_elements;
}

sub _get_end_tag {
    return "rdf:RDF";
}

1;

