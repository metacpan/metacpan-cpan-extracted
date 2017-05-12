# -*- cperl -*-
# copyright (C) 2005 Topia <topia@clovery.jp>. all rights reserved.
# This is free software; you can redistribute it and/or modify it
#   under the same terms as Perl itself.
# $Id: Page.pm 55 2005-02-01 19:16:17Z topia $
# $URL: file:///usr/minetools/svnroot/mixi/trunk/WWW-Mixi-OO/lib/WWW/Mixi/OO/Page.pm $
package WWW::Mixi::OO::Page;
use strict;
use warnings;
use Carp;
use base qw(Class::Accessor::Fast);
use base qw(WWW::Mixi::OO::Util);

=head1 NAME

WWW::Mixi::OO::Page - WWW::Mixi::OO's Pages base class

=head1 SYNOPSIS

  package WWW::Mixi::OO::Foo;
  use base qw(WWW::Mixi::OO::Page);
  sub uri {
      shift->absolute_uri('foo.pl');
  }
  # some implementations...

=head1 DESCRIPTION

pages base class.

=head1 METHODS

=over 4

=cut

=item new

  # subclass
  sub new {
      my $this = shift->SUPER::new(@_);
      # some initializations...
  }

  # call
  my $page = $pkg->new($session);

constructor of page.
please override if you need some initializations.

=cut

sub new {
    my ($class, $session) = @_;

    croak 'session argument is not found' unless defined $session;

    my $this = {
	session => $session,
    };
    bless $this, $class;
}

=item uri

  # subclass
  sub uri {
      my ($this, %options) = @_;
      $this->SUPER::uri(_path => 'foo',
			_params => {
			    a => b,
			},
			%options);
  }

  # call
  my $uri = $page->uri([opt => val], ...);

return URI of page.

=cut

sub uri {
    my $this = shift;
    my $options = $this->_init_uri(@_);

    my $uri = $this->absolute_uri($options->{_path});
    $this->copy_hash_val($options, $options->{_params}, 'id');
    $uri->query_form($options->{_params});
    $uri;
}

sub _init_uri {
    my $this = shift;
    my $options;
    if (@_ % 2) {
	$options = shift;
	if (@_ > 0) {
	    my $key;
	    while (@_) {
		$key = shift;
		$options->{$key} = shift;
	    }
	}
    } else {
	$options = {@_};
    }

    if (!defined $options->{_path}) {
	$options->{_path} = $this->class_to_page(ref($this) || $this);
    }
    $options->{_params} ||= {};
    $options;
}

=item parse_uri

  # subclass
  sub parse_uri {
      my ($this, $data, %options) = @_;
      $this->copy_hash_val($data->{params}, \%options, 'page');
      if ($data->{path} eq "show_friend") {
	  # blah...
      }
      if ($data->{uri}->...) {
	  # maybe you won't use this
      }
      $this->SUPER::uri($data, %options);
  }

  # call
  my %options = $page->analyze_uri($uri);

return page information of URI.

=cut

sub parse_uri {
    my ($this, $data, %options) = @_;

    $this->copy_hash_val($data->{params}, \%options, 'id');
    if ($data->{path} =~ /^(?:view|show)_(\w+)/) {
	$options{type} = $1;
    }
    %options;
}

=item parse

  # subclass
  sub parse {
      my ($this, %options) = @_;
      # parse...
      my $part = $this->parse_extract_parts(qw/.../);
      return () unless defined $part;
      # return
      return ({ a => b, c => d }, { a => e, c => f }, ...);
  }

  # call
  my @datas = $page->parse;

page parser. please return hashref array.

=cut

sub parse { shift->please_override_this }

=item parse_banner

  my $data = $page->parse_banner;

parse banner.
structure:

 link:    link to ad page.
 subject: subject of ad(banner's alt text).
 image:   image of banner
 height:  height of image
 width:   width of image

=cut

sub parse_banner {
    my $this = shift;
    my ($uri, $attrs) = $this->parse_extract_parts(
	qr|<a href="?(banner.+?)"? class="?img"?><img (.+?)></a>|i);
    return () unless defined $uri and defined $attrs;
    my %data;
    $data{link} = $this->absolute_linked_uri($uri);

    my $temp = $this->generate_case_preserved_hash(
	$this->html_attrs_to_hash($attrs));
    $data{subject} = $temp->{alt};
    $data{image} = $this->absolute_linked_uri($temp->{src});
    $this->copy_hash_val($temp, \%data, qw(height width));
    return \%data;
}

=item parse_mainmenu

  my @data = $page->parse_mainmenu;

parse mainmenu.
structure:

 link:    link to page
 subject: subject of page

=cut

sub parse_mainmenu {
    my $this = shift;
    my $part = $this->parse_extract_parts(
	qr|<map name="?mainmenu"?>(.+?)</map>|is);
    return () unless defined $part;
    return map {
	my(%data,$temp);
	$temp = $this->generate_ignore_case_hash(
	    $this->html_attrs_to_hash($_));
	$data{link} = $this->absolute_linked_uri($temp->{href});
	$data{subject} = $this->rewrite($temp->{alt});
	\%data;
    } ($part =~ m|<area (.+?)>|g);
}

=item parse_tool_bar

  my @data = $page->parse_tool_bar;

parse toolbar.
structure:

 link:    link to page
 subject: subject of page
 image:   image of toolbar.
 height:  height of image
 width:   width of image

=cut

sub parse_tool_bar {
    my $this = shift;
    my $attr_regex = $this->regex_parts->{html_attr};
    my $attrval_regex = $this->regex_parts->{html_attrval};
    my $maybe_attrs_regex = $this->regex_parts->{html_maybe_attrs};
    my $part = $this->parse_extract_parts(
	qr|<table$maybe_attrs_regex>(?>.*?<tr>)
	   (?>.*?<td>)<img\s+src="?[a-z:/.]*/img/b(?:fr\|)_left\.gif"?$maybe_attrs_regex></td>
	   (.+)
	   (?>.*?<td>)<img\s+src="?[a-z:/.]*/img/b(?:fr\|)_right\.gif"?$maybe_attrs_regex></td>
	   (?>.*?</tr>)(?>.*?</table>)|isx);
    return () unless defined $part;
    return map {
	m|<a($maybe_attrs_regex)><img($maybe_attrs_regex)></a>|i;
	my $temp = $this->generate_ignore_case_hash(
	    $this->html_attrs_to_hash($2));
	my %data = (
	    link => $this->html_anchor_to_uri($1),
	    image => $this->absolute_linked_uri($temp->{src}),
	    subject => $this->rewrite($temp->{alt}),
	   );
	$this->copy_hash_val($temp, \%data, qw(height width));
	\%data;
    } ($part =~ m|<td>(?>(.+)</td>)|ig);
}

=item get

  $page->get([opt => val], ...);

handy method. call ->set_content and ->parse.

=cut

__PACKAGE__->mk_get_method('');

=item set_content

  $page->set_content($uri);

or

  $page->set_content(%options);

set content to specified by uri or options.

=cut

sub set_content {
    my $this = shift;
    my $uri;

    if (scalar(@_) % 2) {
	# odd
	$uri = shift;
    } else {
	$uri = $this->uri(@_) || return undef;
    }
    $this->session->set_content($uri);
}

=back

=head1 UTILITY METHODS

methods to useful for subclass implementations

=over 4

=cut

=item parse_extract_parts

  # array
  my @parts = $this->parse_extract_parts(qr|....|);
  return () unless @parts;
  # more parse with @parts

or

  # scalar
  my $part = $this->parse_extract_parts(qr|....|);
  return () unless defined $part;
  # more parse with $part

extract part(s) from current content.

=cut

sub parse_extract_parts {
    my ($this, $regex) = @_;

    my $content = $this->content;
    return () unless defined $content;
    my @array;
    return () unless @array = $content =~ m/$regex/;
    if (wantarray) {
	return @array;
    } else {
	return shift(@array);
    }
}

=item html_attr_to_uri

  $page->html_attr_to_uri('src', 'src="foobar" ...');

parse html attrs string(C<< ->html_attrs_to_hash >>) and
extract attr(C<< ->generate_ignore_case_hash()->{$attrname} >>) and
resolve to absolute URI(C<< ->absolute_linked_uri >>).

=cut

sub html_attr_to_uri {
    my ($this, $attrname, $attrvals) = @_;

    $this->absolute_linked_uri(
	$this->generate_ignore_case_hash(
	    $this->html_attrs_to_hash(
		    $attrvals))->{$attrname});
}

=item html_anchor_to_uri

  $page->html_anchor_to_uri("href='...'...");

handy method. call ->html_attr_to_uri with 'href'.

=cut

sub html_anchor_to_uri { shift->html_attr_to_uri('href', @_) }

=item cache

  my $cache = $pkg->cache;
  if (defined $cache->{foo}) {
      return $cache->{foo};
  }
  ...

get modules's cache storage.

=cut

sub cache {
    my $this = shift;
    $this->session->cache(ref($this));
}

=item mk_cached_parser

  # from subclass
  __PACKAGE__->mk_cached_parser(qw(foo bar));
  sub _parse_foo {
      # ...
      return $foo; # please return scalar value.
  }

generate cached parser (proxy) method.
use _parse_(name) to real parser method.

=cut

sub mk_cached_parser {
    my $this = shift;
    my $pkg = ref($this) || $this;
    foreach (@_) {
	eval <<"END";
  package $pkg;
  sub parse_$_ \{
    my \$this = shift;
    return \$this->cache->{$_} if defined \$this->cache->{$_};
    return \$this->cache->{$_} = \$this->_parse_$_;
  \}
END
    }
}

=item mk_get_method

  # from subclass
  __PACKAGE__->mk_get_method(qw(foo bar));

generate get handy method.

=cut

sub mk_get_method {
    my $this = shift;
    my $pkg = ref($this) || $this;
    foreach (@_) {
	my $method = '';
	$method .= "_$_" if length;
	eval <<"END";
  package $pkg;
  sub get$method \{
    my \$this = shift;
    my \%options;

    if (scalar(\@_) % 2) {
	# odd
	\$this->set_content(shift);
	\%options = \@_;
    } else {
	\%options = \@_;
	\$this->set_content(\%options) || return undef;
    }
    \$this->parse$method(\%options);
  \}
END
    }
}



=back

=head1 ACCESSOR

=over 4

=item session

parent L<WWW::Mixi::OO> object.

=cut

__PACKAGE__->mk_ro_accessors(qw(session));

=back

=head1 PROXY METHODS

=over 4

=item relative_uri

=item absolute_uri

=item absolute_linked_uri

=item refresh_content

=item post

=item response

=item content

=item page

=item class_to_page

=item page_to_class

=item analyze_uri

=item convert_from_http_content

=item convert_to_http_content

=item convert_login_time

=item convert_time

see L<WWW::Mixi::OO::Session>.

=cut

foreach (qw(relative_uri absolute_uri absolute_linked_uri refresh_content post
	    response content page class_to_page page_to_class analyze_uri
	    convert_from_http_content convert_to_http_content
            convert_login_time convert_time
	   )) {
    eval "sub $_ \{ shift->session->$_(\@_) }";
}

1;

__END__
=back

=head1 SEE ALSO

L<WWW::Mixi::OO>

for listed content: L<WWW::Mixi::OO::ListPage>

=head1 AUTHOR

Topia E<lt>topia@clovery.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Topia.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
