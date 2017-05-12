package XML::Grammar::Screenplay;

use warnings;
use strict;


our $VERSION = '0.14.11';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::Grammar::Screenplay - CPAN distribution implementing an XML grammar for
screenplays.

=head1 VERSION

version 0.14.11

=head1 SYNOPSIS

See L<XML::Grammar::Screenplay::FromProto>,
L<XML::Grammar::Screenplay::ToDocBook> and
L<XML::Grammar::Screenplay::ToHTML>.

=head1 DESCRIPTION

XML::Grammar::Screenplay is a Perl module for:

=over 4

=item 1. Converting a well-formed plain text format to a specialized XML format.

=item 2. Converting the XML to DocBook/XML or directly to HTML for rendering.

=back

The best way to use it non-programatically is using
L<XML::Grammar::Screenplay::App::FromProto>,
L<XML::Grammar::Screenplay::App::ToDocBook> and
L<XML::Grammar::Screenplay::App::ToHTML>, which are modules implementing
command line applications for their processing.

The rest of this page will document the syntax of the custom textual format.

=head1 VERSION

Version 0.14.11

=head1 FORMAT

=head2 Scenes

Scenes are placed in XML-like tags of C<< <section> ... </section> >> or
abbreviated as C<< <s> ... </s> >>. Opening tags in the format may have
attributes whose keys are plaintext and whose values are surrounded by
double quotes. (Single-quotes are not supported).

The scene tag must have an C<id> attribute (for anchors, etc.) and could
have an optional C<title> attribute. If the title is not specified, it will
default to the ID.

Scenes may be B<nested>. There cannot be any sayings or descriptions (see below)
except inside scenes.

=head2 Text

Text is any of:

=over 4

=item 1. Plaintext

Regular text

=item 2. XML-like tags.

Supported tags are C<< <b> >> for bold text, C<< <i> >> for italics,
C<< <a href="..."> >> for hyperlinks, and an empty C<< <br /> >> tag for line-breaks.

=item 3. Entities

The text format supports SGML-like entities such as C<< &amp; >>,
C<< &lt; >>, C<< &quot; >> and all other entities that are supported by
L<HTML::Entities>.

=item 4. Text between [ ... ]

Text between square brackets (C<[ ... ]>) is reserved for descriptions
or inline descriptions (see below).

=back

=head2 Sayings

The first paragraph when a character talks starts with the name of the
character followed by a colon (C<:>) and the rest of the text. Like this:

    David: Goliath, I'm going to kill you! You'll see -
    I will.

If a character says more than one paragraph, the next paragraph should start
with any number of "+"-signs followed by a colon:

    David: Goliath, I'm going to kill you! You'll see -
    I will.

    ++++: I will sling you and bing you till infinity!

=head2 Descriptions.

Descriptions that are not part of saying start with a C<[> at the first
character of a line and extend till the next C<]>. They can span several
paragraphs.

There are also internal descriptions to the saying which are placed
inside the paragraph of the saying and describe what happens while the
character talks.

=head2 EXAMPLES

=head3 Comprehensive Example

    <s id="top">

    <s id="david_and_goliath">

    [David and <a href="http://en.wikipedia.org/wiki/Goliath">Goliath</a> are
    standing by each other.]

    David: I will kill you.

    Goliath: no way, you little idiot!

    David: yes way!

    ++++: In the name of <a href="http://real-allah.tld/">Allah, the
    <b>merciful</b>, real merciful</a>, I will show you
    the [sarcastically] power of my sling.

    ++: I shall sling you and bing you till infinity.

    [David takes his sling.]

    Goliath: I'm still <a href="http://wait.tld/">waiting</a>.

    David: so you are.

    [David puts a stone in his sling and shoots Goliath. He hits.]

    David: as is written in the wikipedia [See <a href="http://wiki.tld/">the
    Wiki site</a> for more information], you are now dead, having been shot with
    my sling.

    </s>

    </s>

=head3 More Examples

Other examples can be found in the C<t/data> directory, and here:

=over 4

=item * The One with the Fountainhead

L<http://www.shlomifish.org/humour/TOWTF/>

=item * Humanity - The Movie

L<http://www.shlomifish.org/humour/humanity/>

=item * Star Trek - “We The Living Dead”

L<http://www.shlomifish.org/humour/Star-Trek/We-the-Living-Dead/>

=item * Selina Mandrake - The Slayer

L<http://www.shlomifish.org/humour/Selina-Mandrake/>

=item * Summerschool at the NSA

L<http://www.shlomifish.org/humour/Summerschool-at-the-NSA/>

=back

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
