package Text::Upskirt;
BEGIN {
  $Text::Upskirt::VERSION = '0.100';
}
    # ABSTRACT: turns baubles into trinkets

use strict;
use warnings;
use 5.012003;
use Carp;

use constant {HTML_SKIP_HTML => (1 << 0),
              HTML_SKIP_STYLE => (1 << 1),
              HTML_SKIP_IMAGES => (1 << 2),
              HTML_SKIP_LINKS => (1 << 3),
              HTML_EXPAND_TABS => (1 << 5),
              HTML_SAFELINK => (1 << 7),
              HTML_TOC => (1 << 8),
              HTML_HARD_WRAP => (1 << 9),
              HTML_GITHUB_BLOCKCODE => (1 << 10),
              HTML_USE_XHTML => (1 << 11)};

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Text::Upskirt ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
        MKDEXT_AUTOLINK
        MKDEXT_FENCED_CODE
        MKDEXT_LAX_HTML_BLOCKS
        MKDEXT_NO_INTRA_EMPHASIS
        MKDEXT_SPACE_HEADERS
        MKDEXT_STRIKETHROUGH
        MKDEXT_TABLES
        HTML_SKIP_HTML
        HTML_SKIP_STYLE
        HTML_SKIP_IMAGES
        HTML_SKIP_LINKS
        HTML_EXPAND_TABS
        HTML_SAFELINK
        HTML_TOC
        HTML_HARD_WRAP
        HTML_GITHUB_BLOCKCODE
        HTML_USE_XHTML
        markdown
        smartypants
) ],
 'ext' => [ qw (
        MKDEXT_AUTOLINK
        MKDEXT_FENCED_CODE
        MKDEXT_LAX_HTML_BLOCKS
        MKDEXT_NO_INTRA_EMPHASIS
        MKDEXT_SPACE_HEADERS
        MKDEXT_STRIKETHROUGH
        MKDEXT_TABLES
)],
 'html' => [ qw (
        HTML_SKIP_HTML
        HTML_SKIP_STYLE
        HTML_SKIP_IMAGES
        HTML_SKIP_LINKS
        HTML_EXPAND_TABS
        HTML_SAFELINK
        HTML_TOC
        HTML_HARD_WRAP
        HTML_GITHUB_BLOCKCODE
        HTML_USE_XHTML
)],

 );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT;


sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Text::Upskirt::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
      no strict 'refs';
      # Fixed between 5.005_53 and 5.005_61
#XXX  if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Text::Upskirt', $Text::Upskirt::VERSION);

# Preloaded methods go here.

# Autoload methods go after __END__, and are processed by the autosplit program.

1;
__END__

=head1 SYNOPSIS

    use Text::Upskirt qw/markdown smartypants/;
    
    my $markdown = << 'EOMD';
    Installation
    ============

    The simplest way to install this is with cpanm!
    Thanks to 'Natacha Porté' for Upskirt.
    EOMD
    
    my $html = markdown($markdown);
    my $fancyhtml = smartypants($html);

At this point $html contains the basic html rendered from the markdown, which will look like

    <h1>Installation</h1>
    
    <p>The simplest way to install this is with cpanm!
    Thanks to 'Natacha Porté' and any other contributors for Upskirt</p>

and $fancyhtml has had smart quotes and things added to look like this

    <h1>Installation</h1>
    
    <p>The simplest way to install this is with cpanm!
    Thanks to &lsquo;Natacha Porté&rsquo; and any other contributors for Upskirt</p>

=head1 Functions

=head2 markdown

    $html = markdown($input, $extensions, $html_options)

C<markdown> takes it's input as a string and returns the rendered HTML output.

Both $extensions and $html_options are optional and default to nothing.

=head3 Extensions

=over 8

=item C<MKDEXT_AUTOLINK>

Automatically create links from urls and email addresses.

=item C<MKDEXT_FENCED_CODE>

Allow for fenced code blocks using B<~> and B<`>.  This lets you do code blocks without indention which can make copy-paste easier after the fact.

    SYNOPSIS
    --------
    
    ~~~~~~~
    use Text::Upskirt qw/markdown smartypants/;

    my $markdown = << 'EOMD';
    Installation
    ============

    The simplest way to install this is with cpanm!
    Thanks to 'Natacha Porté' for Upskirt.
    EOMD

    my $html = markdown($markdown);
    my $fancyhtml = smartypants($html);
    ~~~~~~~

NOTES:
    If you plan on using C<smartypants> you may encounter issues if you attempt to use the ``fancy'' quote style exhibited there.

=item C<MKDEXT_LAX_HTML_BLOCKS>

Allow HTML tags inside paragraphs without being surrounded by newlines.

=item C<MKDEXT_NO_INTRA_EMPHASIS>

Avoid turning text like C<my_awesome_function> into C<E<lt>emE<gt>awesomeE<lt>/emE<gt>function>.  You will need to escape phrases as C<I like it when you say, "_I love you_.">

=item C<MKDEXT_SPACE_HEADERS>

Force a space between header hashes and the header itself

=item C<MKDEXT_STRIKETHROUGH>

Let you make strikethroughs by surrounding text with ~~.

=item C<MKDEXT_TABLES>

Let you create tables similar to the PHP Markdown Extra

    First Header  | Second Header
    ------------- | -------------
    Content Cell  | Content Cell
    Content Cell  | Content Cell

=back

=head3 Html Options

=over 8

=item C<HTML_SKIP_HTML>

Don't output any of the boilerplate HTML tags at the start of the document

=item C<HTML_SKIP_STYLE>

Don't add any C<E<lt>styleE<gt>> tags to the output

=item C<HTML_SKIP_IMAGES>

Don't process any image markdown and remove any C<E<lt>imgE<gt>> tags from the output

=item C<HTML_SKIP_LINKS>

Don't process any link markdown and remove any C<E<lt>aE<gt>> tags from the output

=item C<HTML_EXPAND_TABS>

Does not appear to be used in the code.

=item C<HTML_SAFELINK>

Don’t make hyperlinks from links that have unknown URL types.

=item C<HTML_TOC>

Build a table of contents on the top of the output

=item C<HTML_HARD_WRAP>

Treat newlines in paragraphs as real line breaks, github style.

=item C<HTML_GITHUB_BLOCKCODE>

Don't include any extra CSS for code blocks

=item C<HTML_USE_XHTML>

Generate XHTML 1.0 compliant tags

=back

=head2 smartypants

    $html = smartpants($input)

C<smartypants> takes input as a string and returns the fancy HTML output.
You can read a bit more about smartypants at L<http://daringfireball.net/projects/smartypants/>.

=head1 UPSKIRT

Upskirt is a fast, robust Markdown parsing library that doesn't suck,  Created by Natacha Porté.  This module is a set of bindings for it.  It is bundled along with the module and is seperately licensed as specified below.

  Copyright (c) 2008, Natacha Porté
  
  Permission to use, copy, modify, and distribute this software for any
  purpose with or without fee is hereby granted, provided that the above
  copyright notice and this permission notice appear in all copies.
  
  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

And while the sources are available with the module, you're probably going to have a nicer time grabbing them from the github repository for Upskirt at L<https://github.com/tanoku/upskirt>

=head1 LICENSE

This module is available under the Artistic 2.0 license as available at L<http://www.perlfoundation.org/artistic_license_2_0>
Copyright Ryan Voots 2011.

=head1 SEE ALSO

  * L<https://github.com/tanoku/upskirt>