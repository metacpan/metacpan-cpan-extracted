# -*- cperl -*-
# copyright (C) 2005 Topia <topia@clovery.jp>. all rights reserved.
# This is free software; you can redistribute it and/or modify it
#   under the same terms as Perl itself.
# $Id: TableHistoryListPage.pm 94 2005-02-04 12:39:28Z topia $
# $URL: file:///usr/minetools/svnroot/mixi/trunk/WWW-Mixi-OO/lib/WWW/Mixi/OO/TableHistoryListPage.pm $
package WWW::Mixi::OO::TableHistoryListPage;
use strict;
use warnings;
use URI;
use URI::QueryParam;
use base qw(WWW::Mixi::OO::TableListPage);

=head1 NAME

WWW::Mixi::OO::TableHistoryListPage - WWW::Mixi::OO's
Table style History List Pages base class

=head1 SYNOPSIS

  package WWW::Mixi::OO::Foo;
  use base qw(WWW::Mixi::OO::TableHistoryListPage);
  # some implementations...

=head1 DESCRIPTION

log style list pages base class.

=head1 METHODS

=over 4

=cut

=item parse_title

title parser: return scalar or array of scalar.

=cut

sub parse_title {
    my $this = shift;
    my $part = $this->parse_table_item('title');
    my $sp_or_nbsp = qr/(?:\s+|&nbsp;)/o;
    return () unless defined $part;
    my @parts;
    return () unless @parts = $part =~ m|<b>(.+)</b>
         (?>(?:$sp_or_nbsp+\*\*\*$sp_or_nbsp+(.*?))?</td>)|xio;
    @parts = map $this->rewrite($_), grep defined, @parts;
    return (wantarray) ? (@parts) : $parts[0];
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
             (?>.*?<table$maybe_attrs_regex>)\s*
             <tr><td>\s*(.+)\s*
           </td></tr>\s*</table>(?>.*?<tr>)\s*<td>
           <img\s+src="?[a-z:/.]*/img/q_brown3\.gif"?$maybe_attrs_regex>|oisx);
}

sub _parse_body {
    my $this = shift;
    my $part = $this->parse_table_item('body');
    return () unless defined $part;
    my $maybe_attrs_regex = $this->regex_parts->{html_maybe_attrs};
    my $regex = qr|<td$maybe_attrs_regex><img$maybe_attrs_regex>(.*?)</td>\s*
	<td$maybe_attrs_regex>\s*<a($maybe_attrs_regex)>(?>(.*?)</a>)\s+
	\((.*)\)\s*</td>|oisx;
    my ($date, $anchor, $title, $name);
    return [map {
	if (($date, $anchor, $title, $name) = /$regex/) {
	    $anchor = $this->html_anchor_to_uri($anchor);
	    my $data = {
		link => $anchor,
		$this->analyze_uri($anchor),
		date => $this->convert_time($date),
		time => $this->convert_time($date),
		name => $this->rewrite($name),
		$this->_parse_body_subject($title),
	    };
	    $data;
	} else {
	    ();
	}
    } $part =~ m|<tr$maybe_attrs_regex>(.*?)</tr>|oisxg];
}

=item _parse_body_subject

standard body subject parser, only rewrite.

=cut

sub _parse_body_subject {
    my ($this, $subject) = @_;
    (subject => $this->rewrite($subject));
}

=item _parse_body_subject_with_count

  # subclass
  sub _parse_body_subject {
      shift->_parse_body_subject_with_count(@_);
  }

alternate body subject parser, with count.

such as: 'foobar (10)' to C<< (subject => 'foobar', count => 10) >>.

=cut

sub _parse_body_subject_with_count {
    my ($this, $subject) = @_;

    if ($subject =~ /^(.*) \((\d+)\)\s*$/so) {
	(subject => $this->rewrite($1),
	 count => $2);
    } else {
	(subject => $this->rewrite($subject));
    }
}

1;

__END__
=back

=head1 SEE ALSO

L<WWW::Mixi::OO::TableListPage>,
L<WWW::Mixi::OO::ListPage>,
L<WWW::Mixi::OO::Page>

=head1 AUTHOR

Topia E<lt>topia@clovery.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Topia.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

