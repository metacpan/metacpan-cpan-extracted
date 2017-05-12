package XML::RSS::Private::Output::V1_0;

use strict;
use warnings;

use vars (qw(@ISA));

use XML::RSS::Private::Output::Base;
use XML::RSS::Private::Output::Roles::ModulesElems;

@ISA = (qw(XML::RSS::Private::Output::Roles::ModulesElems XML::RSS::Private::Output::Base));

sub _get_top_elem_about {
    my ($self, $tag, $about_sub) = @_;
    return ' rdf:about="' . $self->_encode($about_sub->()) . '"';
}

sub _out_textinput_rss_1_0_elems {
    my $self = shift;

    $self->_out_dc_elements($self->textinput());

    # Ad-hoc modules
    # TODO : Should this follow the %rdf_resources conventions of the items'
    # and channel's modules' support ?
    while (my ($url, $prefix) = each %{$self->_modules()}) {
        next if $prefix =~ /^(dc|syn|taxo)$/;
        while (my ($el, $value) = each %{$self->textinput($prefix) || {}}) {
            $self->_out_ns_tag($prefix, $el, $value);
        }
    }
}

sub _get_rdf_decl_open_tag {
    return "<rdf:RDF\n";
}

sub _calc_prefer_dc {
    return 1;
}

sub _get_first_rdf_decl_mappings {
    return (
        ["rdf", "http://www.w3.org/1999/02/22-rdf-syntax-ns#"],
        [undef, "http://purl.org/rss/1.0/"]
    );
}

sub _out_image_dc_elements {
    my $self = shift;
    return $self->_out_dc_elements($self->image());
}

sub _out_item_1_0_tags {
    my ($self, $item) = @_;

    $self->_out_dc_elements($item);

    # Taxonomy module
    $self->_output_taxo_topics($item);
}

sub _output_rss_middle {
    my $self = shift;

    # PICS rating - Dublin Core has not decided how to incorporate PICS ratings yet
    #$$output .= '<rss091:rating>'.$self->{channel}->{rating}.'</rss091:rating>'."\n"
    #$if $self->{channel}->{rating};

    $self->_out_copyright();

    # publication date
    $self->_out_defined_tag("dc:date", $self->_calc_dc_date());

    # external CDF URL
    #$output .= '<rss091:docs>'.$self->{channel}->{docs}.'</rss091:docs>'."\n"
    #if $self->{channel}->{docs};

    $self->_out_editors;

    $self->_out_all_modules_elems;

    $self->_out_seq_items();

    if ($self->_is_image_defined()) {
        $self->_out('<image rdf:resource="' .
            $self->_encode($self->image('url')) . "\" />\n"
        );
    }

    if (defined(my $textinput_link = $self->textinput('link'))) {
        $self->_out('<textinput rdf:resource="'
          . $self->_encode($textinput_link) . "\" />\n"
        );
    }

    $self->_end_channel;

    $self->_output_main_elements;
}

sub _get_end_tag {
    return "rdf:RDF";
}

1;

