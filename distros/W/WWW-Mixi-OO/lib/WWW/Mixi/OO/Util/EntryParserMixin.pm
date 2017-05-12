# -*- cperl -*-
# copyright (C) 2005 Topia <topia@clovery.jp>. all rights reserved.
# This is free software; you can redistribute it and/or modify it
#   under the same terms as Perl itself.
# $Id: EntryParserMixin.pm 108 2005-02-05 10:36:41Z topia $
# $URL: file:///usr/minetools/svnroot/mixi/trunk/WWW-Mixi-OO/lib/WWW/Mixi/OO/Util/EntryParserMixin.pm $
package WWW::Mixi::OO::Util::EntryParserMixin;
use strict;
use warnings;
use URI;
use URI::QueryParam;

=head1 NAME

WWW::Mixi::OO::Util::EntryParserMixin - WWW::Mixi::OO's Entry Parser Mixin

=head1 SYNOPSIS

  package WWW::Mixi:OO::FooPage;
  # use base's order is important!
  use base qw(WWW::Mixi::OO::Page); # or your super class
  use base qw(WWW::Mixi::OO::Util::EntryParserMixin);
  # and use...
  my $this->parse_entry($entry_text);

=head1 DESCRIPTION

entry parser mixin.

=head1 METHODS

=over 4

=cut

=item parse_image_thumbnail

  my @items = $util->parse_image_thumbnail('<table>...</table>');

parse image thumbnail html parts, and return array of
image's information hashrefs.

image's information items:

=over 4

=item link

URI of image.

=item subject

subject of image(img/alt).

=item thumbnail_link

URI of image thumbnail.

=back

=cut

sub parse_image_thumbnail {
    my ($this, $text) = @_;

    my $maybe_attrs_regex = $this->regex_parts->{html_maybe_attrs};
    return () unless $text =~ m|<table$maybe_attrs_regex><tr$maybe_attrs_regex>
	(?>(.*?)</tr>)</table>|iosx;
    return map {
	if (m|<a($maybe_attrs_regex)><img($maybe_attrs_regex)></a>|sio) {
	    my $anchor = $this->generate_ignore_case_hash(
		$this->html_attrs_to_hash($1));
	    my $img = $this->generate_ignore_case_hash(
		$this->html_attrs_to_hash($2));
	    my $data = {
		link => $this->absolute_linked_uri($anchor->{href}),
	    };
	    if (URI->new($data->{link})->scheme eq 'javascript' &&
		    exists $anchor->{onclick}) {
		if ($anchor->{onclick} =~ /MM_open\w*Window\('([^\']+)',/) {
		    $this->copy_hash_val(
			{$this->analyze_uri($this->absolute_linked_uri($1))},
			$data,
			[qw(image link)]);
		}
	    }
	    $this->copy_hash_val($img, $data, [qw(alt subject)]);
	    $data->{thumbnail_link} = $this->absolute_linked_uri($img->{src})
		if exists $img->{src};
	    $data;
	} else {
	    ()
	}
    } $this->extract_balanced_html_parts(
	exclude_border_element => 1,
	element => 'td',
	text => $1);
}

=item parse_entry

  my $data = $util->parse_entry('....');

parse entry text, and return hashref. items:

=over 4

=item body

body text.

=item images

arrayref of images (see parse_image_thumbnail).

=back

=cut

sub parse_entry {
    my ($this, $text) = @_;

    my $data = {};
    if ($text =~ /<table>/) {
	$data->{images} = [map {
	    # remove this
	    $text =~ s/\Q$_\E\s*//s;

	    $this->parse_image_thumbnail($_);
	} $this->extract_balanced_html_parts(
	    element => 'table',
	    text => "$text ")];
	# XXX: this stringify is avoid unknown warning
	# Malformed UTF-8 character (unexpected end of string) in subroutine entry
	# at extract_balanced_html_parts/HTML::Parser->parse.
    }
    $data->{body} = $text;
    $data;
}

1;

__END__
=back

=head1 SEE ALSO

L<WWW::Mixi::OO>,
L<WWW::Mixi::OO::Util>

=head1 AUTHOR

Topia E<lt>topia@clovery.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Topia.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
