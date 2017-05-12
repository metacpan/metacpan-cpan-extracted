# -*- cperl -*-
# copyright (C) 2005 Topia <topia@clovery.jp>. all rights reserved.
# This is free software; you can redistribute it and/or modify it
#   under the same terms as Perl itself.
# $Id: TableListPage.pm 100 2005-02-04 19:19:55Z topia $
# $URL: file:///usr/minetools/svnroot/mixi/trunk/WWW-Mixi-OO/lib/WWW/Mixi/OO/TableListPage.pm $
package WWW::Mixi::OO::TableListPage;
use strict;
use warnings;
use URI;
use URI::QueryParam;
use base qw(WWW::Mixi::OO::ListPage);

=head1 NAME

WWW::Mixi::OO::TableListPage - WWW::Mixi::OO's Table style List Pages base class

=head1 SYNOPSIS

  package WWW::Mixi::OO::Foo;
  use base qw(WWW::Mixi::OO::TableListPage);
  # some implementations...

=head1 DESCRIPTION

table style list pages base class.

=head1 METHODS

=over 4

=cut

=item parse

see parent class (L<WWW::Mixi::OO::ListPage>),
and some implementation class.

=item parse_navi_prev

=item parse_navi_current

=item parse_navi_next

parse previous(or current, or next) navigation.

see some implementation class.

=back

=head1 METHODS MAYBE IMPLEMENTATION AT SUBCLASS

=over 4

=item parse_title

parse title message. return scalar or array of scalar.

=cut

sub parse {
    my $body = shift->parse_body;
    return () unless defined $body;
    return @$body;
}

foreach (qw(prev current next)) {
    eval <<"END";
  sub parse_navi_$_ \{
      my \$this = shift;
      my \$navi = \$this->parse_navi;
      return () unless defined \$navi;
      return () unless defined \$navi->{$_};
      return \$navi->{$_};
  \}
END
}

=back

=head1 INTERNAL METHODS

these methods used from internal (such as subclass).

=over 4

=item parse_table

=item parse_navi

=item parse_body

cached parser methods for _parse_table, _parse_navi, _parse_body.

=cut

__PACKAGE__->mk_cached_parser(qw(table navi body));

=item _parse_table

  # subclass
  sub _parse_table {
      my $this = shift;
      return $this->SUPER::_parse_table(@_) if @_ == 1; # overridable

      my %options = @_;
      $this->SUPER::_parse_table(qr/.../);
  }

return main table.

=cut

sub _parse_table {
    my $this = shift;

    my $part = $this->parse_extract_parts(shift);
    return () unless defined $part;

    # split to each tables
    $this->_split_tables($part);
    return $part;
}

=item _split_tables

  # subclass
  sub _split_tables {
      my ($this, $part) = @_;
      my @tables = /(...)/g;

      # set tables
      $this->cache->{tables} = \@tables;

      # set indecies to tables...
      $this->cache->{indecies}->{title} = 0;
      $this->cache->{indecies}->{navi} = 1;
      $this->cache->{indecies}->{body} = 2;
  }

split main tables to some parts.

=cut

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
	pop(@tables);
	$this->cache->{indecies}->{navi} = 1;
	$this->cache->{indecies}->{body} = 2;
    } else {
	$this->cache->{indecies}->{body} = 1;
    }
}

=item parse_table_item_with_index

  # call from subclass
  sub _parse_foo {
      my ($this, %options) = @_;
      my $part = $this->parse_table_item_with_index(0);
      return () unless defined $part;
      # ...
      return $1;
  }

return split part with index. (maybe useless)

=cut

sub parse_table_item_with_index {
    my $this = shift;
    $this->parse_table;
    return $this->cache->{tables}->[shift];
}

=item parse_table_item

  # call from subclass
  sub _parse_body {
      my ($this, %options) = @_;
      my $part = $this->parse_table_item('body');
      return () unless defined $part;
      # ...
      return $1;
  }

return split part with keyword.

=cut

sub parse_table_item {
    my $this = shift;
    $this->parse_table;
    my $index = $this->cache->{indecies}->{+shift};
    if (defined $index) {
	return $this->cache->{tables}->[$index];
    }
}

=item parse_table_items

  # call from subclass
  my $table_count = $this->parse_table_items;

return split parts count. (maybe useless)

=cut

sub parse_table_items {
    my $this = shift;
    $this->parse_table;
    return scalar @{$this->cache->{tables}};
}

sub _parse_navi {
    my $this = shift;
    my $part = $this->parse_table_item('navi');
    return () unless defined $part;
    my $maybe_attrs_regex = $this->regex_parts->{html_maybe_attrs};
    my $non_metas_regex = $this->regex_parts->{non_metas};
    my $regex = qr|
        <td$maybe_attrs_regex>
	(?:<a($maybe_attrs_regex)>($non_metas_regex)</a>&nbsp;&nbsp;)?
	($non_metas_regex)
	(?:&nbsp;&nbsp;<a($maybe_attrs_regex)>($non_metas_regex)</a>)?
	</td>
	    |iox;
    return () unless $part =~ m/$regex/;
    $this->_parse_navi_link('prev', $1, $2) if defined $1;
    $this->_parse_navi_link('next', $4, $5) if defined $4;

    my $navi_cache = $this->cache->{navi}->{current} = {};
    $navi_cache->{subject} = $3;
    if ($3 =~ /(\d+)\D+(\d+)/) {
	$navi_cache->{start} = $1;
	$navi_cache->{end} = $2;
    }
    return $this->cache->{navi};
}

=item _parse_navi_link

  # call from subclass
  my %datas = $this->_parse_navi_link('current', 'href="..."', 'next page');

standard navigation link parser.

=cut

sub _parse_navi_link {
    my ($this, $genre, $attr, $value) = @_;
    my $link = $this->html_anchor_to_uri($attr);
    my $data = $this->cache->{navi}->{$genre} = {
	link => $link,
	$this->analyze_uri($link),
    };
    $data->{subject} = $this->rewrite($value);
    if ($value =~ /(\d+)/) {
	$data->{count} = $1;
    }
}


1;

__END__
=back

=head1 SEE ALSO

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
