# -*- cperl -*-
# copyright (C) 2005 Topia <topia@clovery.jp>. all rights reserved.
# This is free software; you can redistribute it and/or modify it
#   under the same terms as Perl itself.
# $Id: Util.pm 104 2005-02-05 08:26:34Z topia $
# $URL: file:///usr/minetools/svnroot/mixi/trunk/WWW-Mixi-OO/lib/WWW/Mixi/OO/Util.pm $
package WWW::Mixi::OO::Util;
use strict;
use warnings;
use URI;
use Carp;
use HTML::Parser;
use Hash::Case::Preserve;
our $regex_parts;
__PACKAGE__->_init_regex_parts;

=head1 NAME

WWW::Mixi::OO::Util - WWW::Mixi::OO's Helper Functions

=head1 SYNOPSIS

  use base qw(WWW::Mixi::OO::Util);
  $this->absolute_uri(..., ...);

=head1 DESCRIPTION

misc helper functions.

=head1 METHODS

=over 4

=cut

=item absolute_uri

  $util->absolute_uri($uri, [$base]);

Generate absolute URI from base uri.
This is simple wrapper for URI class.

=cut

sub absolute_uri {
    my ($this, $uri, $base) = @_;
    return do {
	if (defined $base) {
	    URI->new_abs($uri, $base)
	} else {
	    URI->new($uri);
	}
    };
}

=item relative_uri

  $util->relative_uri($uri, [$base]);

Generate relative URI from base uri.
This is simple wrapper for URI class.

=cut

sub relative_uri {
    my ($this, $uri, $base) = @_;
    return  $this->absolute_uri($uri, $base)->rel($base);
}

=item remove_tag

  $util->remove_tag($str);

Remove HTML(or XML, or SGML?) tag from string.

=cut

sub remove_tag {
    my ($this, $str) = @_;
    return undef unless defined $str;
    my $non_metas = $this->regex_parts->{non_metas};
    my $re_standard_tag = qr/
      <$non_metas
      (?:"[^\"]*"$non_metas|'[^\']*'$non_metas)*
      (?:>|(?=<)|$(?!\n))
    /x;
    my $re_comment_tag  = qr/<!
      (?:
       --[^-]*-
       (?:[^-]+-)*?-
       (?:[^>-]*(?:-[^>-]+)*?)??
      )*
      (?:>|$(?!\n)|--.*$)/x;
    my $re_html_tag     = qr/$re_comment_tag|$re_standard_tag/;
    $str =~ s/$re_html_tag//g;
    return $str;
}

=item extract_balanced_html_parts

  $util->extract_balanced_html_parts(
      ignore_outside => 1,
      element => 'table',
      text => ...);

extract _balanced_ HTML parts from text.

options:

=over 4

=item element

element name for balanced check.

=item text

text to extract.

=item ignore_outside

ignore I<n>th outside element.

example:

  $util->extract_balanced_html_parts(
      ignore_outside => 1,
      element => 'table',
      text => '<table><table>abc</table><table>cde</table></table>');
  # returns:
  # ('<table>abc</table>', '<table>cde</table>')

=item exclude_border_element

exclude border element from generate part.

example:

  $util->extract_balanced_html_parts(
      ignore_outside => 1,
      exclude_border_element => 1,
      element => 'table',
      text => '<table><table>abc</table><table>cde</table></table>');
  # returns:
  # ('abc', 'cde')

=back

=cut

sub extract_balanced_html_parts {
    my ($this, %options) = @_;
    my $level = - ($options{ignore_outside} || 0);
    my $debug = $options{debug} || 0;
    my $exclude_border_element = $options{exclude_border_element} ? 1 : 0;
    my @ret;
    my $temp = '';
    my $parser = HTML::Parser->new(
	api_version => 3,
	start_h => [
	    sub {
		my ($text, $skipped_text) = @_;
		$temp .= $skipped_text if $level > 0;
		$temp .= $text if $level >= $exclude_border_element;
		printf "level/\%02d> \%s (\%s)\n\n", $level, $text,
		    substr($skipped_text,0,50) if $debug;
		++$level;
	    }, "text,skipped_text" ],
	end_h => [
	    sub {
		my ($text, $skipped_text) = @_;
		$temp .= $skipped_text;
		$temp .= $text if $level > $exclude_border_element;
		--$level;
		printf "level/\%02d< \%s (\%s)\n\n", $level, $text,
		    substr($skipped_text,0,50) if $debug;
		push @ret, $temp if $level == 0;
		$temp = '' if $level <= 0;
	    }, 'text,skipped_text' ],
       );
    $parser->report_tags($options{element});
    $parser->parse($options{text});
    return @ret;
}

=item html_attrs_to_hash

  my %hash = $util->html_attrs_to_hash('href="..."');

or more useful:

  my $case_ignore_hash = $util->generate_ignore_case_hash($util->html_attrs_to_hash('href="..."'));

parse html attributes string to hash.

=cut

sub html_attrs_to_hash {
    my ($this, $str) = @_;
    my $html_attr = $this->regex_parts->{html_attr};

    map {
	if (/\A(.+?)=(.*)\z/) {
	    ($1, $this->unquote($2))
	} else {
	    ($_, undef);
	}
    } ($str =~ /($html_attr)(?:\s+|$)/go);
}

=item generate_ignore_case_hash

  my $case_insensitive_hash = $util->generate_ignore_case_hash(%hash);

hash to ignore case hash.

=cut

sub generate_ignore_case_hash {
    my $this = shift;
    tie my(%hash), 'Hash::Case::Preserve', keep => 'FIRST';
    %hash = @_;
    \%hash;
}

=item generate_case_preserved_hash

obsolete. renamed to generate_ignore_case_hash

=cut

sub generate_case_preserved_hash {
    shift->generate_ignore_case_hash(@_);
}

=item copy_hash_val

  $util->copy_hash_val(\%src_hash, \%dest_hash, qw(foo bar baz));

or

  $util->copy_hash_val(\%src_hash, \%dest_hash, [qw(foo bar)], [qw(baz qux)]);

copy hash value on key exist

=cut

sub copy_hash_val {
    my $this = shift;
    my $src = shift;
    my $dest = shift;
    my ($attr_src, $attr_dest);

    foreach (@_) {
	if (defined ref && ref eq 'ARRAY') {
	    ($attr_src, $attr_dest) = @$_;
	} else {
	    $attr_src = $attr_dest = $_;
	}
	$dest->{$attr_dest} = $src->{$attr_src} if exists $src->{$attr_src};
    }
}

=item regex_parts

  $util->regex_parts->{$foo};

return some regex parts's hashref.

parts:

=over 4

=item non_meta

html non-meta char (not ["'<>]).

=item non_metas

html non-meta chars ($non_meta*).

=item non_meta_spc

html non-meta-and-spc char (not ["'<> ]).

=item non_meta_spcs

html non-meta-and-spc chars ($non_meta_spc*).

=item non_meta_spc_eq

html non-meta-and-spc-eq char (not ["'<> =]).

=item non_meta_spc_eqs

html non-meta-and-spc-eq chars ($non_meta_spc_eq*).

=item html_quotedstr_no_paren

html quoted string without grouping paren.

=item html_quotedstr

html quoted string with grouping.

=item html_attrval

html attribute value.

=item html_attr

html attribute

=item html_maybe_attrs

maybe html attributes found

=back

=cut

sub regex_parts {
    return $regex_parts;
}

sub _init_regex_parts {
    my $parts = $regex_parts ||= {};
    $$parts{non_meta} =
	qr/[^\"\'<>]/o;
    $$parts{non_metas} =
	qr/$$parts{non_meta}*/o;

    $$parts{non_meta_spc} =
	qr/[^\"\'<> ]/o;
    $$parts{non_meta_spcs} =
	qr/$$parts{non_meta_spc}*/o;

    $$parts{non_meta_spc_eq} =
	qr/[^\"\'<> =]/o;
    $$parts{non_meta_spc_eqs} =
	qr/$$parts{non_meta_spc_eq}*/o;

    $$parts{html_quotedstr_no_paren} =
	qr/"[^"]*"|'[^']*'/o;
    $$parts{html_quotedstr} =
	qr/(?:$$parts{html_quotedstr_no_paren})/o;
    $$parts{html_attrval} =
	qr/(?:$$parts{html_quotedstr_no_paren}|$$parts{non_meta_spcs})+/o;
    $$parts{html_attr} =
	qr/$$parts{non_meta_spc_eq}+(?:=$$parts{html_attrval})?/o;
    $$parts{html_maybe_attrs} =
	qr/(?:\s+$$parts{html_attr})*/o;

}

=item escape

  $util->escape($str);

equivalent of CGI::escapeHTML.

=cut

sub escape {
    my $this = shift;
    $_ = shift;
    return undef unless defined;
    s/\&(amp|quot|apos|gt|lt);/&amp;$1;/g;
    s/\&(?!(?:[a-zA-Z]+|#\d+|#x[a-f\d]+);)/&amp;/g;
    s/\"/&quot;/g;
    s/\'/&apos;/g;
    s/>/&gt;/g;
    s/</&lt;/g;
    return $_;
}

=item unescape

  $util->unescape($str);

HTML unescape.

=cut

sub unescape {
    my $this = shift;
    $_ = shift;
    return undef unless defined;
    s/&quot;/\"/g;
    s/&apos;/\'/g;
    s/&gt;/>/g;
    s/&lt;/</g;
    s/&amp;/&/g;
    return $_;
}

=item unquote

  $util->unquote($str);

HTML unquote.

=cut

sub unquote {
    my $this = shift;
    $_ = shift;
    if (/\A([\'\"])(.*)\1\Z/) {
	$this->unescape($2);
    } else {
	# none escaped
	$_;
    }
}

=item rewrite

  $util->rewrite($str);

standard rewrite method.
do remove_tag and unescape.

=cut

sub rewrite {
    my $this = shift;
    $this->unescape($this->remove_tag(shift));
}

=item please_override_this

  sub foo { shift->please_override_this }

universal 'please override this' error method.

=cut

sub please_override_this {
    my $this = shift;
    (my $funcname = (caller(1))[3]) =~ s/^.*::(.+?)$/$1/;

    die sprintf 'please override %s->%s!', (ref $this || $this), $funcname;
}

1;

__END__
=back

=head1 SEE ALSO

L<WWW::Mixi::OO>

=head1 AUTHOR

Topia E<lt>topia@clovery.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Topia.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
