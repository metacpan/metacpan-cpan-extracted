package XML::RSS::Private::Output::V2_0;

use strict;
use warnings;

use vars (qw(@ISA));

use XML::RSS::Private::Output::Base;
use XML::RSS::Private::Output::Roles::ModulesElems;
use XML::RSS::Private::Output::Roles::ImageDims;

@ISA = (qw(
    XML::RSS::Private::Output::Roles::ImageDims
    XML::RSS::Private::Output::Roles::ModulesElems
    XML::RSS::Private::Output::Base
    )
);

sub _get_filtered_items {
    my $self = shift;

    return [
        grep {exists($_->{title}) || exists($_->{description})}
        @{$self->_get_items()},
    ];
}

sub _out_item_2_0_tags {
    my ($self, $item) = @_;

    $self->_output_def_item_tag($item, "author");
    $self->_output_array_item_tag($item, "category");
    $self->_output_def_item_tag($item, "comments");

    $self->_out_guid($item);

    $self->_output_def_item_tag($item, "pubDate");

    $self->_out_item_source($item);

    $self->_out_item_enclosure($item);
}

sub _get_textinput_tag {
    return "textInput";
}

sub _get_item_defined {
    return 1;
}

sub _output_rss_middle {
    my $self = shift;

    # PICS rating
    # Not supported by RSS 2.0
    # $output .= '<rating>'.$self->{channel}->{rating}.'</rating>'."\n"
    #    if $self->{channel}->{rating};

    # copyright
    $self->_out_copyright();

    $self->_out_dates();

    # external CDF URL
    $self->_out_def_chan_tag("docs");

    $self->_out_editors;

    $self->_out_channel_array_self_dc_field("category");
    $self->_out_channel_self_dc_field("generator");

    # Insert cloud support here

    # ttl
    $self->_out_channel_self_dc_field("ttl");

    $self->_out_modules_elements($self->channel());

    $self->_out_last_elements;
}

1;

