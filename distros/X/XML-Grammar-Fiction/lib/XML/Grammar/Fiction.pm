package XML::Grammar::Fiction;

use warnings;
use strict;


our $VERSION = '0.14.11';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::Grammar::Fiction - CPAN distribution implementing an XML grammar
and a lightweight markup language for stories, novels and other fiction.

=head1 VERSION

version 0.14.11

=head1 SYNOPSIS

See L<XML::Grammar::Fiction::FromProto>,
L<XML::Grammar::Fiction::ToDocBook> and
L<XML::Grammar::Fiction::ToHTML>.

=head1 DESCRIPTION

XML::Grammar::Fiction is a CPAN distribution that facilitates writing prose
fiction (= stories, novels, novellas, etc.). What it does is:

=over 4

=item 1. Convert a well-formed plain text format to a specialized XML format.

=item 2. Convert the XML to DocBook/XML or directly to HTML for rendering.

=back

The best way to use it non-programatically is using
L<XML::Grammar::Fiction::App::FromProto>,
L<XML::Grammar::Fiction::App::ToDocBook> and
L<XML::Grammar::Fiction::App::ToHTML>, which are modules implementing
command line applications for their processing.

In order to be able to share the common code and functionality more easily,
then L<XML::Grammar::Screenplay>, which provides similar XML grammar and
text-based markup language for writing screenplays, is now included in this
CPAN distribution, and you can refer to its documentation as well:
L<XML::Grammar::Screenplay> .

The rest of this page will document the syntax of the custom textual format.

=head1 VERSION

Version 0.14.11

=head1 FORMAT

=head2 Sections

Sections are placed in XML-like tags of C<< <section> ... </section> >> or
abbreviated as C<< <s> ... </s> >>. Opening tags in the format may have
attributes whose keys are plaintext and whose values are surrounded by
double quotes. (Single-quotes are not supported).

The section tag must have an C<id> attribute (for anchors, etc.) and could
contain an optional (but highly recommended) C<< <title> >> sub-tag. If the
title is not specified, it will default to the ID.

Sections may be B<nested>.

=head2 Text

Text is any of:

=over 4

=item 1. Plaintext

Regular text

=item 2. XML-like tags.

Supported tags are C<< <b> >> for bold text, and C<< <i> >> for italic
text.

=item 3. Entities

The text format supports SGML-like entities such as C<< &amp; >>,
C<< &lt; >>, C<< &quot; >> and all other entities that are supported by
L<HTML::Entities>.

=item 4. Supported initial characters

The following characters can start a regular paragraph:

=over 4

=item * Any alphanumeric character.

=item * Some special characters:

The characters C<"> (double quotes), C<'> (single quotes), etc. are supported.

=item * XML/SGML entities.

XML/SGML entities are also supported at the start.

=back

All other characters are reserved for special markup in the future. If you
need to use them at the beginning of the paragraph you can escape them with
a backslash (C<\>) or their SGML/XML entity (e.g: C<&qout;>).

=back

=head2 Types of top-level items.

=head3 Paragraphs

These are not delimited by anything - just a paragraph of text not containing
an empty line. If a paragraph starts with a Plus sign ( C<+> ) then it is
immediately expected to be followed by a styling tag (as opposed to a

=head3 <ol>

This is an ordered list with <li>s, similar to its purpose in XHTML.

=head3 <ul>

An unordered list.

=head2 EXAMPLES

=head3 Examples Document.

    <body id="index" lang="en-UK">

    <title>David vs. Goliath - Part I</title>

    <s id="top">

    <title>The Top Section</title>

    <!-- David has Green hair here -->

    King <a href="http://en.wikipedia.org/wiki/David">David</a> and Goliath
    were standing by each other.

    David said unto Goliath: “I will shoot you. I <b>swear</b> I will”

    <s id="goliath">

    <title>Goliath's Response</title>

    <!-- Goliath has to reply to that. -->

    Goliath was not amused.

    He said to David: “Oh, really. <i>David</i>, the red-headed!”.

    </s>

    </s>

    </body>

=head3 Other Examples

Examples can be found in the C<t/data> directory, and here:

=over 4

=item * The Pope Died on Sunday (Hebrew version)

L<http://www.shlomifish.org/humour/Pope/>

=item * The Enemy and How I Helped to Fight it (Hebrew version)

L<http://www.shlomifish.org/humour/TheEnemy/>

=item * The Human Hacking Field Guide (Hebrew version)

L<http://www.shlomifish.org/humour/human-hacking/>

=back

=head1 MOTIVATION

I (= Shlomi Fish) originated this CPAN distribution (after forking
L<XML:Grammar::Screenplay> which was similar enough) so I'll have a convenient
way to edit a story I'm writing in Hebrew and similar fiction, as
OpenOffice.org caused me many problems, and I found editing bi-directional
DocBook/XML to be painful with either gvim or KDE 4's kate, so I opted for a
more plain-texty format.

I hope a lightweight markup language like that for fiction (and possibly
other types of manuscripts) will prove useful for other writers. At the
moment, a lot of stuff in the proto-text format is subject to change,
so you'll need to accept that some modifications to your sources will be
required in the future. I hope you still find it useful and let me know
if you need any feature or bug-fix.

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2007 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-Grammar-Fiction or by email to
bug-xml-grammar-fiction@rt.cpan.org.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc XML::Grammar::Fiction

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/XML-Grammar-Fiction>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/XML-Grammar-Fiction>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-Grammar-Fiction>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/XML-Grammar-Fiction>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/XML-Grammar-Fiction>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/XML-Grammar-Fiction>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/XML-Grammar-Fiction>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/X/XML-Grammar-Fiction>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=XML-Grammar-Fiction>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=XML::Grammar::Fiction>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-xml-grammar-fiction at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Grammar-Fiction>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://bitbucket.org/shlomif/perl-XML-Grammar-Fiction>

  hg clone ssh://hg@bitbucket.org/shlomif/perl-XML-Grammar-Fiction

=cut
