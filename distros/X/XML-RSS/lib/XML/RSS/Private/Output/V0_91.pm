package XML::RSS::Private::Output::V0_91;

use strict;
use warnings;

use vars (qw(@ISA));

use XML::RSS::Private::Output::Base;
use XML::RSS::Private::Output::Roles::ImageDims;

@ISA = (qw(
    XML::RSS::Private::Output::Roles::ImageDims
    XML::RSS::Private::Output::Base
    )
);

sub _get_rdf_decl
{
    return
    qq{<!DOCTYPE rss PUBLIC "-//Netscape Communications//DTD RSS 0.91//EN"\n} .
    qq{            "http://www.rssboard.org/rss-0.91.dtd">\n\n} .
    qq{<rss version="0.91">\n\n};
}

sub _calc_lastBuildDate {
    my $self = shift;
    if (defined(my $d = $self->channel('lastBuildDate'))) {
        return $d;
    }
    elsif (defined(my $d2 = $self->_channel_dc('date'))) {
        return $self->_date_to_rss2($self->_date_from_dc_date($d2));
    }
    else {
        return undef;
    }
}

sub _output_rss_middle {
    my $self = shift;

    # PICS rating
    $self->_out_def_chan_tag("rating");

    $self->_out_copyright();

    $self->_out_dates();

    # external CDF URL
    $self->_out_def_chan_tag("docs");

    $self->_out_editors;

    $self->_out_last_elements;
}

1;

