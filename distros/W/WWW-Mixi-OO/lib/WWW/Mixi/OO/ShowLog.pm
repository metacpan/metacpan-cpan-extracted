# -*- cperl -*-
# copyright (C) 2005 Topia <topia@clovery.jp>. all rights reserved.
# This is free software; you can redistribute it and/or modify it
#   under the same terms as Perl itself.
# $Id: ShowLog.pm 94 2005-02-04 12:39:28Z topia $
# $URL: file:///usr/minetools/svnroot/mixi/trunk/WWW-Mixi-OO/lib/WWW/Mixi/OO/ShowLog.pm $
package WWW::Mixi::OO::ShowLog;
use strict;
use warnings;
use base qw(WWW::Mixi::OO::TableHistoryListPage);

sub _split_tables {
    my ($this, $part) = @_;

    my $maybe_attrs_regex = $this->regex_parts->{html_maybe_attrs};
    (my $head, $part) = $part =~ m|^(<table$maybe_attrs_regex>(?>.*?</table>))\s*(.*)\Z|ois;
    my @tables = $part =~ m|<table$maybe_attrs_regex>
           (?>.*?(<table$maybe_attrs_regex>(?>.*?</table>)))
           (?>.*?</table>)\s*|oixsg;
    unshift @tables, $head;
    $part = pop @tables;
    $part =~ m|<table$maybe_attrs_regex>
	(?>.*?<table$maybe_attrs_regex>){3}
	\s*<tr>\s*<td>(?>(.*?)</td>)</tr>
	\s*<tr>\s*<td$maybe_attrs_regex>(?>(.*?)</td>)|oixs;
    push @tables, $1, $2;
    $this->cache->{tables} = \@tables;
    $this->cache->{indecies}->{title} = 0;
    $this->cache->{indecies}->{info} = 1;
    $this->cache->{indecies}->{count} = 2;
    $this->cache->{indecies}->{body} = 3;
}

sub parse_count {
    my $this = shift;
    my $part = $this->parse_table_item('count');
    return () unless defined $part;
    return () unless $part =~ m|<b>(\d+)</b>|io;
    return $1;
}

sub _parse_body {
    my $this = shift;
    my $part = $this->parse_table_item('body');
    return () unless defined $part;
    my $maybe_attrs_regex = $this->regex_parts->{html_maybe_attrs};
    my $regex = qr|^(.*)\s+<a($maybe_attrs_regex)>(.*?)</a><br>|oisx;
    my ($date, $anchor, $name);
    return [map {
	if (($date, $anchor, $name) = /$regex/) {
	    $anchor = $this->html_anchor_to_uri($anchor);
	    my $data = {
		date => $this->convert_time($date),
		time => $this->convert_time($date),
		name => $this->rewrite($name),
		link => $anchor,
		$this->analyze_uri($anchor),
	    };
	    $data;
	} else {
	    ();
	}
    } $part =~ m|\s*(.*?</a><br>)|oisg];
}

1;
