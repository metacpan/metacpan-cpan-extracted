# -*- perl -*-
#
# Text::Smart::HTML by Daniel Berrange <dan@berrange.com>
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
# $Id: HTML.pm,v 1.2 2004/12/31 16:00:45 dan Exp $

=pod

=head1 NAME

Text::Smart::HTML - Smart text outputter for HTML

=head1 SYNOPSIS

  use Text::Smart::HTML;

  my $markup = Text::Smart::HTML->new(%params);

=head1 DESCRIPTION

=head1 METHODS

=over 4

=cut

package Text::Smart::HTML;

use strict;
use warnings;

use Text::Smart;

use vars qw(@ISA);

@ISA = qw(Text::Smart);

=item my $proc = Text::Smart::HTML->new(target => $target);

Creates a new smart text processor which outputs HTML markup.
The only C<target> parameter is used to specify the hyperlink
window target (via the 'target' attribute on the <a> tag)

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new();
    my %params = @_;

    $self->{target} = exists $params{target} ? $params{target} : undef;

    bless $self, $class;

    return $self;
}

=item my $markup = $proc->generate_divider

Generates a horizontal divider using the <hr> tag.

=cut

sub generate_divider {
    my $self = shift;

    return "<hr>\n";
}

=item my $markup = $proc->generate_itemize(@items)

Generates an itemized list of bullet points using the <ul> tag.

=cut

sub generate_itemize {
    my $self = shift;
    my @items = @_;

    return "<ul>\n" . (join("\n", map { "<li>$_</li>\n" } @items)) . "</ul>\n";
}

=item my $markup = $proc->generate_enumeration(@items)

Generates an itemized list of numbered points using the <ol> tag

=cut

sub generate_enumeration {
    my $self = shift;
    my @items = @_;

    return "<ol>\n" . (join("\n", map { "<li>$_</li>\n" } @items)) . "</ol>\n";
}

=item my $markup = $proc->generate_heading($text, $level)

Generates a heading using one of the tags <h1> through <h6>

=cut

sub generate_heading {
    my $self = shift;
    local $_ = $_[0];
    my $level = $_[1];

    my %levels = (
		  "title" => "h1",
		  "subtitle" => "h2",
		  "section" => "h3",
		  "subsection" => "h4",
		  "subsubsection" => "h5",
		  "paragraph" => "h6",
		  );

    return "<" . $levels{$level} . ">$_</" . $levels{$level} . ">\n";
}

=item my $markup = $proc->generate_paragraph($text)

Gnerates a paragraph using the <P> tag.

=cut

sub generate_paragraph {
    my $self = shift;
    local $_ = $_[0];

    return "<p>$_</p>\n";
}

=item my $markup = $proc->generate_bold($text)

Generates bold text using the <strong> tag

=cut

sub generate_bold {
    my $self = shift;
    local $_ = $_[0];

    return "<strong>$_</strong>";
}

=item my $markup = $proc->generate_italic($text)

Generates italic text using the <em> tag.

=cut

sub generate_italic {
    my $self = shift;
    local $_ = $_[0];

    return "<em>$_</em>";
}

=item my $markup = $proc->generate_monospace($text)

Generates monospaced text using the <code> tag.

=cut

sub generate_monospace {
    my $self = shift;
    local $_ = $_[0];

    return "<code>$_</code>";
}


=item my $markup = $proc->generate_link($url, $text)

Generates a hyperlink using the <a> tag.

=cut

sub generate_link {
    my $self = shift;
    my $url = shift;
    local $_ = $_[0];

    if ($self->{target}) {
	return "<a target=\"$self->{target}\" href=\"$url\">$_</a>";
    } else {
	return "<a href=\"$url\">$_</a>";
    }
}


=item my $markup = $proc->generate_entity($text)

Generates entities using the &frac12;, &frac14;, &frac34;,
&copy;, &reg; and <sup> TM </sup> entities / markup.

=cut

sub generate_entity {
    my $self = shift;
    my $entity = shift;

    my %entities = (
		    fraction12 => "&frac12;",
		    fraction14 => "&frac14;",
		    fraction34 => "&frac34;",
		    copyright => "&copy;",
		    registered => "&reg;",
		    trademark => "<sup>TM</sup>",
		    );

    return exists $entities{$entity} ? $entities{$entity} : $entity;
}

=item my $text = $proc->escape($text)

Escapes the ampersand, and angle bracket characters

=cut

sub escape {
    my $self = shift;
    local $_ = $_[0];

    s/&/&amp;/g;
    s/</&lt;/g;
    s/>/&gt;/g;

    return $_;
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
