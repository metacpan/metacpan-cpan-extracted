# -*- cperl -*-
# copyright (C) 2005 Topia <topia@clovery.jp>. all rights reserved.
# This is free software; you can redistribute it and/or modify it
#   under the same terms as Perl itself.
# $Id: TablePreviewListPage.pm 100 2005-02-04 19:19:55Z topia $
# $URL: file:///usr/minetools/svnroot/mixi/trunk/WWW-Mixi-OO/lib/WWW/Mixi/OO/TablePreviewListPage.pm $
package WWW::Mixi::OO::TablePreviewListPage;
use strict;
use warnings;
use URI;
use URI::QueryParam;
use base qw(WWW::Mixi::OO::TableListPage);

=head1 NAME

WWW::Mixi::OO::TablePreviewListPage - WWW::Mixi::OO's Table style List Pages base class

=head1 SYNOPSIS

  package WWW::Mixi::OO::Foo;
  use base qw(WWW::Mixi::OO::TableListPage);
  # some implementations...

=head1 DESCRIPTION

table style list pages base class.

=head1 METHODS

=over 4

=cut

=item parse_title

title parser: return scalar.

=cut

sub parse_title {
    my $this = shift;
    my $part = $this->parse_table_item('title');
    return () unless defined $part;
    return () unless $part =~ m|<b>(.+)</b></td>|io;
    return $1;
}

sub _parse_table {
    my $this = shift;
    return $this->SUPER::_parse_table(@_) if @_ == 1; # overridable

    my $attr_regex = $this->regex_parts->{html_attr};
    my $attrval_regex = $this->regex_parts->{html_attrval};
    my $maybe_attrs_regex = $this->regex_parts->{html_maybe_attrs};
    $this->SUPER::_parse_table(
	qr|<table$maybe_attrs_regex><tr><td>
             <img\s+src="?[a-z:/.]*/img/q_or1\.gif"?$maybe_attrs_regex>
             ((?>.*?<table$maybe_attrs_regex>)
             <tr><td>.+)
           </td></tr><tr><td>
           <img\s+src="?[a-z:/.]*/img/q_or3\.gif"?$maybe_attrs_regex>|oisx);
}

sub _parse_body {
    my $this = shift;
    my $part = $this->parse_table_item('body');
    return () unless defined $part;
    my $maybe_attrs_regex = $this->regex_parts->{html_maybe_attrs};
    my $regex = qr|\A(.*?)</tr>\s*
	<tr$maybe_attrs_regex>(.*?)\Z|oisx;
    my $link;
    return [map {
	my ($photo, $text) = /$regex/;
	# parse top-half
	my @top_half = map {
	    if (m|<a($maybe_attrs_regex)><img($maybe_attrs_regex)></a>|oi) {
		$link = $this->html_anchor_to_uri($1);
		my %data = (
		    link => $link,
		    $this->analyze_uri($link),
		   );
		$data{image} = $this->absolute_linked_uri(
		    $this->generate_case_preserved_hash(
			$this->html_attrs_to_hash($2))->{src});
		\%data;
	    } else {
		();
	    }
	} $photo =~ m|<td$maybe_attrs_regex>(.*?)</td>|oig;
	# parse bottom-half
	my @data = map {
	    if (m|\A(.*)\((\d+)\)|oi) {
		my $data = shift(@top_half);
		$data->{count} = $2;
		$data->{subject} = $this->rewrite($1);
		$data;
	    } else {
		();
	    }
	} $text =~ m|<td>(.*?)</td>|oig;
	@data;
    } $part =~ m|<tr$maybe_attrs_regex>(.*?</tr>\s*
		 <tr$maybe_attrs_regex>.*?)</tr>|oisxg];
}

1;

__END__
=back

=head1 SEE ALSO

L<WWW::Mixi::OO::Page>

=head1 AUTHOR

Topia E<lt>topia@clovery.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Topia.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
