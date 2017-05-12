# -*- perl -*-
#
# Text::Smart by Daniel Berrange <dan@berrange.com>
#
# Copyright (C) 2000-2004 Daniel P. Berrange <dan@berrange.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# $Id: Smart.pm,v 1.3 2004/12/31 16:00:45 dan Exp $

=pod

=head1 NAME

Text::Smart - Processor for 'smart text' markup

=head1 SYNOPSIS

  use Text::Smart;

  my $markup = Text::Smart->new(entities => \%entities);

  my $text = $markup->process($text, %opts);

  my $text = $markup->process_divider($text);
  my $text = $markup->process_itemize($text, %opts);
  my $text = $markup->process_enumeration($text, %opts);
  my $text = $markup->process_paragraph($text, %opts);
  my $text = $markup->process_smart($text, %opts);

  # Virtual methods for subclasses to implement
  my $text = $markup->generate_divider();
  my $text = $markup->generate_itemize(@items);
  my $text = $markup->generate_enumeration(@items);
  my $text = $markup->generate_paragraph($text);
  my $text = $markup->generate_bold($text);
  my $text = $markup->generate_italic($text)
  my $text = $markup->generate_monospace($text);
  my $text = $markup->generate_link($text, $url);
  my $text = $markup->escape($text);

=head1 DESCRIPTION

This module provides an interface for converting
smarttext markup into an arbitrary text based markup
language, such as HTML, Latex, or Troff.

=head2 SMARTTEXT MARKUP

Smarttext markup can be split into two categories,
block level and inline. Block level elements are
separated by one or more completely blank lines.
Inline elements encompass one or more words within
a block. Valid inline markup is:

  *foo* - Puts the word 'foo' in bold face
  /foo/ - Puts the word 'foo' in italic face
  =foo= - Puts the word 'foo' in fixed width face
  @foo(bar) - Makes the word 'foo' a link to the url 'bar'

There are six pre-defined entities

  (C) - Insert copyright symbol
  (TM) - Insert trademark symbol
  (R) - Insert registered symbol

  1/2 - insert a fraction
  1/4 - insert a fraction
  3/4 - insert a fraction

There are six levels of heading available

  &title(Main document heading)
  &subtitle(Secondary document heading)
  &section(Section heading)
  &subsection(Secondary section heading)
  &subsubsection(Tertiary section heading)
  &paragraph(Paragraph heading)

There are three special blocks. Horizontal dividing bars
can be formed using

  ---
  ___

Numbered lists using

 + item one
 + item two
 + item three

Bulleted lists using

 * item one
 * item two
 * item three

Anything not fitting these forms is treated as a
standard paragraph.

=head2 OPTIONS

All the C<process_XXX> family of methods accept a number
of options which control which pieces of markup are
permitted in the text. The following options are recognised:

  no_links
  no_symbols
  no_lists
  no_rules
  no_inline

To use this options pass them as a named parameter:

  $markup->process($text, no_links => 1, no_lists => 1);

=head2 SUBCLASSING

This module provides the basic parsing routines and
framework for outputting text, however, it must be
subclassed to generate the markup language specific
tags. The primary subclass is L<Text::Smart::HTML> which
is used to generate HTML markup.

=head1 METHODS

The 'generate_XXX' methods are virtual and need to be implemented
by subclasses.

=over 4

=cut

package Text::Smart;

use strict;
use warnings;

our $VERSION = '1.0.2';

=item my $proc = Text::Smart->new();

Create a new smart text processor. This constructor would
not normally be called by application code, since this module
must be sub-classed to be useful. The primary subclass is for
generating HTML, L<Text::Smart::HTML>.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    my %params = @_;

    bless $self, $class;

    return $self;
}

=item my $markup = $proc->process($text)

Converts a piece of smart text, passed in as the parameter into the
target markup language of this processor. The markedup text is returned

=cut

sub process {
    my $self = shift;
    my $text = shift;
    my %params = @_;

    my @blocks = split /\r?\n(\r?\n)+/, (ref($text) ? ${$text} : $text);

    foreach (@blocks) {
	if (/^\s*(___+|---+)\s*$/ && !$params{no_rules}) {
	    $_ = $self->_process_divider($_);
	} elsif (/^\*\s/ && !$params{no_lists}) {
	    $_ = $self->_process_itemize($_, @_);
	} elsif (/^\+\s/ && !$params{no_lists}) {
	    $_ = $self->_process_enumeration($_, @_);
	} elsif (/^&\w+\(.*\)/) {
	    $_ = $self->_process_heading($_, @_);
	} elsif (/\w/) {
	    $_ = $self->_process_paragraph($_, @_);
	}
    }

    return join("\n", @blocks);
}


sub _process_divider {
    my $self = shift;
    local $_ = shift;

    return $self->generate_divider();
}


sub _process_itemize {
    my $self = shift;
    local $_ = shift;

    my @items = split /^\*\s+/m;
    shift @items if $items[0] eq '';

    return $self->generate_itemize(map { $self->_process_smart($_, @_) } @items);
}


sub _process_enumeration {
    my $self = shift;
    local $_ = shift;

    my @items = split /^\+\s*/m;
    shift @items if $items[0] eq '';

    return $self->generate_enumeration(map { $self->_process_smart($_, @_) } @items);
}


sub _process_heading {
    my $self = shift;
    local $_ = shift;

    $_ =~ /^&(\w+)\((.*)\)/;

    return $self->generate_heading($self->_process_smart($2, @_), $1);
}

sub _process_paragraph {
    my $self = shift;
    local $_ = shift;

    return $self->generate_paragraph($self->_process_smart($_, @_));
}


sub _process_smart {
    my $self = shift;
    local $_ = $self->escape(shift);
    my %params = @_;

    my $links = {};

    # We're going to use the octal characters \001 and \002 for
    # escaping stuff, so we'd better make sure there aren't any
    # in the text.
    s/\001//g;
    s/\002//g;
    s/\003//g;

    unless ($params{no_links}) {
	# We've got to protect the url of links before we go further,
	# however we can't actually generate the link yet because
	# that interferes with the monospace stuff below....
	s|@@|\001|gx;
	s|@([^\(@]+)\(([^\)]+)\)|'@' . $1 . '(' . $self->_obscure($2, $links) . ')'|gex;
	s|\001|@@|gx;
    }

    unless ($params{no_symbols}) {
	# We transform a few common symbols
	# We don't substitute them straight in because the
	# substituted text might interfere with stuff that
	# follows...
	s|\b1/4\b|"\003fraction14\003"|gex;
	s|\b1/2\b|"\003fraction12\003"|gex;
	s|\b3/4\b|"\003fraction34\003"|gex;

	s|\(C\)|"\003copyright\003"|gex;
	s|\(R\)|"\003registered\003"|gex;
	s|\(TM\)|"\003trademark\003"|gex;
    }

    unless ($params{no_links}) {
	# We protect hyperlinks so that the '/' or '@' doesn't get
	# mistaken for a block of italics / link
	s|([a-z]+://[^\s,\(\)><]*)|'@' . $self->_obscure($1, $links) . '(' . $self->_obscure($1, $links) . ')'|gex;
	s|(mailto:[^\s,\(\)><]*)|'@' . $self->_obscure($1, $links) . '(' . $self->_obscure($1, $links) . ')'|gex;
    }

    unless ($params{no_inline}) {
	# Next lets process italics /italic/
	# NB. this must be first, otherwise closing tags </foo>
	# interfere with the pattern matching
	s|//|\001|gx;
	s|(?<!\w)/([^/]+)/(?!\w)|$self->generate_italic($1)|gex;
	s|\001|/|gx;

	# Lets process bold text *bold*
	s|\*\*|\001|gx;
	s|(?<!\w)\*([^\*]+)\*(?!\w)|$self->generate_bold($1)|gex;
	s|\001|\*|gx;

	# Now we're onto the monospace stuff =monospace=
	s|==|\001|gx;
	s|(?<!\w)=([^=]+)=(?!\w)|$self->generate_monospace($1)|gex;
	s|\001|=|gx;
    }

    unless ($params{no_links}) {
	# Links are next on the list @text(url)
	s|@@|\001|gx;
	s|@([^\(@]+)\(([^\)]+)\)|$self->generate_link($2, $1)|gex;
	s|\001|@|gx;

	# Finally we can unobscure the hyperlinks
	s|\002([^\002]+)\002|$links->{$1}|gex;
    }

    unless ($params{no_symbols}) {
	# And those entities
	s|\003([^\003]+)\003|$self->generate_entity($1)|gex;
    }

    return $_;
}


sub _obscure {
    my $self = shift;
    my $link = shift;
    my $map = shift;

    my @keys = keys %{$map};
    my $id = $#keys + 1;

    $map->{$id} = $link;

    return "\002$id\002";
}

=item my $markup = $proc->generate_divider()

Called to generate a horizontal section divider. The generated text must
be returned in string format. This method must be implemented by subclasses.

=cut

sub generate_divider {
    my $self = shift;

    die "class " . ref($self) . " did not implement the generate_divider method";
}

=item my $markup = $proc->generate_itemize(@items)

Called to generate an itemized list of bullet points. The (already marked up) text
for each item is passed as a list of parameters. The generated text must be returned
in string format. This method must be implemented by subclasses.

=cut

sub generate_itemize {
    my $self = shift;

    die "class " . ref($self) . " did not implement the generate_itemize method";
}

=item my $markup = $proc->generate_enumeration(@items)

Called to generate an itemized list of numbered points. The (already marked up) text
for each item is passed as a list of parameters. The generated text must be returned
in string format. This method must be implemented by subclasses.

=cut

sub generate_enumeration {
    my $self = shift;

    die "class " . ref($self) . " did not implement the generate_enumeration method";
}

=item my $markup = $proc->generate_paragraph($text)

Called to generate a paragraph of text. The (already marked up) text for the body
of the paragraph is passed in as the only parameter. The generated text must be
returned in string format. This method must be implemented by subclasses.

=cut

sub generate_paragraph {
    my $self = shift;

    die "class " . ref($self) . " did not implement the generate_paragraph method";
}

=item my $markup = $proc->generate_bold($text)

Called to generate bold text. The plain text is passed in as the parameter, and
the marked up text should be returned in string format. This method must be
implemented by subclasses.

=cut

sub generate_bold {
    my $self = shift;

    die "class " . ref($self) . " did not implement the generate_bold method";
}


=item my $markup = $proc->generate_italic($text)

Called to generate italic text. The plain text is passed in as the parameter, and
the marked up text should be returned in string format. This method must be
implemented by subclasses.

=cut

sub generate_italic {
    my $self = shift;

    die "class " . ref($self) . " did not implement the generate_italic method";
}


=item my $markup = $proc->generate_monospace($text)

Called to generate fixed-width text. The plain text is passed in as the parameter, and
the marked up text should be returned in string format. This method must be
implemented by subclasses.

=cut

sub generate_monospace {
    my $self = shift;

    die "class " . ref($self) . " did not implement the generate_monospace method";
}



=item my $markup = $proc->generate_link($url, $text)

Called to generate a hyperlink. The destination of the link is the first parameter,
and the text being linked is the second parameter. The marked up text must be returned
in string format. This method must be implemented by subclasses.

=cut


sub generate_link {
    my $self = shift;

    die "class " . ref($self) . " did not implement the generate_link method";
}

=item my $markup = $proc->generate_entity($name);

Called to generated a special named entity. There are 6 named entities which
need to be supported:

=over 4

=item fraction12

The fraction 1/2

=item fraction14

The fraction 1/4

=item fraction 34

The fraction 3/4

=item copyright

The copyright symbol

=item trademark

The trademark symbol

=item registered

The rights registered symbol

=back

The markup corresponding to the specified entity must be returned in string
format.

=cut

sub generate_entity {
    my $self = shift;

    die "class " . ref($self) . " did not implement the generate_entity method";
}

=item my $text = $proc->escape($text)

Called to escape any characters which have special meaning in the destination
markup language. For example, in HTML, this would escape angle brackets and
the ampersand symbol. The escaped text must be returned in string format.

=cut

sub escape {
    my $self = shift;

    die "class " . ref($self) . " did not implement the escape method";
}

1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange <dan@berrange.com>

=head1 COPYRIGHT

Copyright (C) 2000-2004 Daniel P. Berrange <dan@berrange.com>

=head1 SEE ALSO

L<perl(1)>

=cut
