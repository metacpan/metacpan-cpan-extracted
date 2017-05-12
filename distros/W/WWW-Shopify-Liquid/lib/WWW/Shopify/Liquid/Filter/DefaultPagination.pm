#!/usr/bin/perl
use strict;
use warnings;

package WWW::Shopify::Liquid::Filter::DefaultPagination; use base 'WWW::Shopify::Liquid::Filter';
sub operate { return join(" ", map { '<span class="page"><a href="' . $_->{url} . '" title="">' . $_->{title} . '</a></span>' } @{$_[2]->{paginate}->{parts}}); }

1;