# -*- cperl -*-
# copyright (C) 2005 Topia <topia@clovery.jp>. all rights reserved.
# This is free software; you can redistribute it and/or modify it
#   under the same terms as Perl itself.
# $Id: ListMessage.pm 100 2005-02-04 19:19:55Z topia $
# $URL: file:///usr/minetools/svnroot/mixi/trunk/WWW-Mixi-OO/lib/WWW/Mixi/OO/ListMessage.pm $
package WWW::Mixi::OO::ListMessage;
use strict;
use warnings;
use File::Basename;
use base qw(WWW::Mixi::OO::TableHistoryListPage);

our %envelopes = (
    'img/mail1.gif' => 'new',
    'img/mail2.gif' => 'opened',
    'img/mail5.gif' => 'replied',
   );

sub uri {
    my $this = shift;
    my $options = $this->_init_uri(@_);

    $this->copy_hash_val($options, $options->{_params}, 'box');
    $this->SUPER::uri($options);
}

sub parse_uri {
    my ($this, $data, %options) = @_;

    $this->copy_hash_val($data->{params}, \%options, 'box');
    $this->SUPER::parse_uri($data, %options);
}

sub _parse_table {
    my $this = shift;
    return $this->SUPER::_parse_table(@_) if @_ == 1; # overridable

    my $attr_regex = $this->regex_parts->{html_attr};
    my $attrval_regex = $this->regex_parts->{html_attrval};
    my $maybe_attrs_regex = $this->regex_parts->{html_maybe_attrs};
    $this->SUPER::_parse_table(
	qr|<table$maybe_attrs_regex>\s*<tr>\s*<td>
             <img\s+src="?[a-z:/.]*/img/q_brown1\.gif"?$maybe_attrs_regex>
             ((?>.*?<table$maybe_attrs_regex>)\s*
             <tr><td>\s*.+)\s*
           </td></tr>\s*</table>(?>.*?<tr>)\s*<td>
           <img\s+src="?[a-z:/.]*/img/q_brown3\.gif"?$maybe_attrs_regex>|oisx);
}

sub _parse_body {
    my $this = shift;
    my $part = $this->parse_table_item('body');
    return () unless defined $part;
    my $maybe_attrs_regex = $this->regex_parts->{html_maybe_attrs};
    my $attrval_regex = $this->regex_parts->{html_attrval};
    my $regex = qr|
        <td$maybe_attrs_regex><img($maybe_attrs_regex)></td>\s*
	<td><input$maybe_attrs_regex></td>\s*
        <td>(?>(.*?)</td>)\s*
        <td><a($maybe_attrs_regex)>(?>(.*?)</a>)</td>\s*
        <td>(?>(.*?)</td>)|oisx;
    my ($img, $name, $anchor, $subject, $date);
    return [map {
	if (m|<td$maybe_attrs_regex\s+\w+="?[a-z:/.]*/img/bg_m\.gif"?|) {
	    # header
	    ();
	} elsif (($img, $name, $anchor, $subject, $date) = /$regex/) {
	    $anchor = $this->html_anchor_to_uri($anchor);
	    $img = $this->html_attr_to_uri('src', $img);
	    my $data = {
		date => $this->convert_time($date),
		time => $this->convert_time($date),
		name => $this->rewrite($name),
		subject => $this->rewrite($subject),
		link => $anchor,
		image => $img,
		status => $envelopes{$this->relative_uri($img)},
		$this->analyze_uri($anchor),
	    };
	    $data;
	} else {
	    ();
	}
    } $part =~ m|<tr$maybe_attrs_regex>(?>(.*?)</tr>)\s*
		 <tr$maybe_attrs_regex>\s*<td$maybe_attrs_regex>\s*
                   <img$maybe_attrs_regex>\s*</td></tr>|oisxg];
}

1;
