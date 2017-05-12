# -*- cperl -*-
# copyright (C) 2005 Topia <topia@clovery.jp>. all rights reserved.
# This is free software; you can redistribute it and/or modify it
#   under the same terms as Perl itself.
# $Id: ListPage.pm 106 2005-02-05 10:35:38Z topia $
# $URL: file:///usr/minetools/svnroot/mixi/trunk/WWW-Mixi-OO/lib/WWW/Mixi/OO/ListPage.pm $
package WWW::Mixi::OO::ListPage;
use strict;
use warnings;
use Carp;
use base qw(WWW::Mixi::OO::Page);

=head1 NAME

WWW::Mixi::OO::ListPage - WWW::Mixi::OO's List Pages base class

=head1 SYNOPSIS

  package WWW::Mixi::OO::Foo;
  use base qw(WWW::Mixi::OO::ListPage);
  # some implementations...

=head1 DESCRIPTION

list pages base class.

=head1 METHODS

=over 4

=cut

=item uri

see super class (L<WWW::Mixi::OO::Page>).

this module handle following params:

=over 4

=item page

page number, maybe 1 origin.

=back

=cut

sub uri {
    my $this = shift;
    my $options = $this->_init_uri(@_);

    $this->copy_hash_val($options, $options->{_params}, 'page');
    $this->SUPER::uri($options);
}

=item parse_uri

see super class (L<WWW::Mixi::OO::Page>).

this module handle following params:

=over 4

=item page

page number, maybe 1 origin.

=back

=cut

sub parse_uri {
    my ($this, $data, %options) = @_;

    $this->copy_hash_val($data->{params}, \%options, 'page');
    $this->SUPER::parse_uri($data, %options);
}

=item parse_navi_next

  # subclass
  sub parse_navi_next {
      my ($this, %options) = @_;
      # parse...
      $this->content =~ /.../;
      # return
      return { a => b, c => d };
  }

  # call
  my $next = $pkg->parse_navi_next;

page "next" navi parser. please return hashref.
page didn't have next page navigation, no need to implement this.

=cut

sub parse_navi_next { shift->please_override_this }

=item parse_navi_prev

  # subclass
  sub parse_navi_prev {
      my ($this, %options) = @_;
      # parse...
      $this->content =~ /.../;
      # return
      return { a => b, c => d };
  }

  # call
  my $prev = $pkg->parse_navi_prev;

page "prev" navi parser. please return hashref.
page didn't have previous page navigation, no need to implement this.

=cut

sub parse_navi_prev { shift->please_override_this }

=item fetch

  # call
  $pkg->fetch(
      limit => $limit,
      other_options...
  );

fetch all items from some pages.
need ->get and ->parse_navi_next()->{link}.

=cut

sub fetch {
    my ($this, %options) = @_;

    my $limit = delete $options{limit};

    my (@items, $next);
    push @items, $this->get(%options);
    while (defined ($next = $this->parse_navi_next)) {
	last if defined $limit && @items > $limit;
	push @items, $this->get($next->{link}, %options);
    }
    if (defined $limit && @items > $limit) {
	splice @items, $limit;
    }
    return @items;
}

=item gen_sort_proc

  # call
  $pkg->gen_sort_proc($spec, [$pkg]);

generate sort closure(anonsub).

spec is "$field" or "!$field"(reverse order).

=cut

sub gen_sort_proc {
    my ($this, $spec, $pkg) = @_;
    $pkg = caller unless defined $pkg;

    my @order = qw($a $b);
    @order = reverse @order if $spec =~ s/^\!//;

    my $op;
    my $type = $this->sort_type($spec);
    if ($type eq 'num') {
	$op = '<=>';
    } elsif ($type eq 'str') {
	$op = 'cmp';
    } else {
	croak "unknown sort_type: $type";
    }

    no warnings;
    no strict 'refs';
    return eval "package $pkg;(sub {" .
	join(" $op ",
	     map { "\$$_\{$spec\}" } @order) . "})";
}

=item sort

  # call
  $pkg->sort($spec, @items...);

handy sort function.
(but maybe need unnecessarily array copy...)

=cut

sub sort {
    my ($this, $spec, @items) = @_;
    my $sort_proc = $this->gen_sort_proc($spec);
    sort $sort_proc @items;
}

=item sort_type

  # subclass
  sub sort_type {
      my ($this, $field) = @_;

      if (grep { $_ eq $field } qw(more nums...)) {
	  return 'num';
      } else {
	  return $this->SUPER::sort_type($field);
      }
  }

sort type probe function.

=cut

sub sort_type {
    my ($this, $field) = @_;

    if (grep { $_ eq $field } qw(id count)) {
	return 'num';
    } else {
	return 'str';
    }
}

=item get_navi_next

  # call
  $pkg->get_navi_next([opt => val], ...);

handy method. call ->set_content and ->parse_navi_next.

=item get_navi_prev

  # call
  $pkg->get_navi_prev([opt => val], ...);

handy method. call ->set_content and ->parse_navi_prev.

=cut

__PACKAGE__->mk_get_method(qw(navi_next navi_prev));

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
