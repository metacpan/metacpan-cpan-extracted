# -*- cperl -*-
# copyright (C) 2005 Topia <topia@clovery.jp>. all rights reserved.
# This is free software; you can redistribute it and/or modify it
#   under the same terms as Perl itself.
# $Id: ListDiary.pm 109 2005-02-05 10:40:18Z topia $
# $URL: file:///usr/minetools/svnroot/mixi/trunk/WWW-Mixi-OO/lib/WWW/Mixi/OO/ListDiary.pm $
package WWW::Mixi::OO::ListDiary;
use strict;
use warnings;
use File::Basename;
use base qw(WWW::Mixi::OO::TableHistoryListPage);
use base qw(WWW::Mixi::OO::Util::EntryParserMixin);

sub uri {
    my $this = shift;
    my $options = $this->_init_uri(@_);

    $this->copy_hash_val($options, $options->{_params}, qw(year month));
    $this->SUPER::uri($options);
}

sub parse_uri {
    my ($this, $data, %options) = @_;

    $this->copy_hash_val($data->{params}, \%options, qw(year month));
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
             <img\s+src="?[a-z:/.]*/img/q_or1\.gif"?$maybe_attrs_regex>
             ((?>.*?<table$maybe_attrs_regex>)\s*
             <tr><td>\s*.+)\s*
           </td></tr>\s*</table>(?>.*?<tr>)\s*<td>
           <img\s+src="?[a-z:/.]*/img/q_or3\.gif"?$maybe_attrs_regex>|oisx);
}

sub _split_tables {
    my ($this, $part) = @_;

    my $maybe_attrs_regex = $this->regex_parts->{html_maybe_attrs};
    my @tables = $this->extract_balanced_html_parts(
	element => 'table',
	text => $part);
    $this->cache->{tables} = \@tables;
    $this->cache->{indecies}->{title} = 0;
    if (@tables > 2) {
	# remove no-need footer
	$this->cache->{indecies}->{navi} = 1;
	$this->cache->{indecies}->{body} = 2;
    } else {
	$this->cache->{indecies}->{body} = 1;
    }
}

sub _parse_body {
    my $this = shift;
    my $part = $this->parse_table_item('body');
    return () unless defined $part;
    my $maybe_attrs_regex = $this->regex_parts->{html_maybe_attrs};
    my $attrval_regex = $this->regex_parts->{html_attrval};
    my @parts = $this->extract_balanced_html_parts(
	element => 'tr',
	text => $part);
    my $sep = qr,<font$maybe_attrs_regex>\|</font>,io;
    my ($title, $body, $control, $temp, $data);
    my @ret;
    while (@parts >= 3) {
	($title, $body, $control) = splice(@parts, 0, 3);

	next unless
	    $control =~ m|<tr$maybe_attrs_regex>\s*
		<td$maybe_attrs_regex><a($maybe_attrs_regex)>(.*?)</a>\s*
		$sep\s*<a$maybe_attrs_regex>(.*?)</a>
		(?>.*?</td>)</tr>|siox;
	$temp = $this->html_anchor_to_uri($1);
	$data = {
	    link => $temp,
	    $this->analyze_uri($temp),
	};
	if ($2 =~ /^.*\((\d+)\)\s*$/so) {
	    $data->{count} = $1;
	}

	next unless
	    $title =~ m|<tr$maybe_attrs_regex>\s*
		<td$maybe_attrs_regex><font$maybe_attrs_regex>(.*?)</font>(?>.*?</td>)\s*
		<td$maybe_attrs_regex>&nbsp;(?>(.*?)</td>)\s*
		</tr>|siox;
	$data->{subject} = $this->rewrite($2);
	$temp = $1;
	$temp =~ s|<br(?:\s*/)?>| |g;
	$data->{time} = $data->{date} =
	    $this->convert_time($this->rewrite($temp));

	next unless
	    $body =~ m|<tr$maybe_attrs_regex>\s*<td$maybe_attrs_regex>\s*
		<table$maybe_attrs_regex>\s*<tr$maybe_attrs_regex>\s*
		<td$maybe_attrs_regex>\s*(?>(.*?)\s*<br>\s*</td>)\s*
		</tr>\s*</table>\s*</td>\s*</tr>|siox;
	$temp = $this->parse_entry($1);
	$this->copy_hash_val($temp, $data,[qw(body summary)], 'images');
	#$data->{summary} = $1;

	push @ret, $data;
    }
    return \@ret;
}

1;
