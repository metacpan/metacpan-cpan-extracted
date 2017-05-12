use strict;
use warnings;
package Text::Trac2GFM;
# ABSTRACT: Converts TracWiki formatted text to GitLab-flavored Markdown (GFM).
$Text::Trac2GFM::VERSION = '0.001';
use String::Util ':all';

use Exporter::Easy (
    OK => [ 'trac2gfm', 'gfmtitle' ]
);

=head1 NAME

Text::Trac2GFM

=head1 SYNOPSIS

As a Perl library:

    use Text::Trac2GFM qw( trac2gfm gfmtitle );

    # GitLab Wiki compatible title: 'api-users-and-accounts'
    my $gitlab_wiki_title = gfmtitle('API/Users & Accounts');

    my $gfm_page = trac2gfm($tracwiki_markup);

Using the included C<trac2gfm> command line program:

    $ trac2gfm <path to tracwiki file>

Or piped to C<STDIN>:

    $ cat <trac wiki file> | trac2gfm

=head1 DESCRIPTION

This module provides functions which ease the migration of TracWiki formatted
wikis (or any other content, such as ticket descriptions, which use TracWiki
markup) to GitLab projects using GitLab Flavored Markdown (GFM).

For the most part, this module assumes that your input TracWiki text is fairly
well-formed and valid. Some concessions are made for whitespace in markup that
may not be optional in TracWiki, but which we can reliably treat as such.
However, blatant violations such as an opening C<{{{> for a pre-formatted code
block that is never followed by a closing C<}}}> will break your output.
Similar breakage can occur with horribly mis-nested emphasis markup, or wildly
malformed links.

If your TracWiki markup renders properly on a Trac wiki, this module I<should>
convert it correctly (barring any special exceptions noted below). If it does
not, please file a bug (or better yet, submit a patch)!

=head1 EXPORTED FUNCTIONS

This module does not export any functions by default. You must select the ones
you wish you use explicitly during module import. The following functions are
available for importing:

=head2 trac2gfm ($markup, $options)

Provided a scalar containing TracWiki markup, returns a scalar containing GFM
compliant markup. As many markup features as can be converted are, but please
note that GitLab-flavored Markdown does not support absolutely everything that
TracWiki does.

An optional (though important) hash reference of options may be provided as the
second argument.

=over

=item * commits

A hash containing the mappings for any repository changeset/commit references
in your wiki pages. This is crucial if you are migrating a project from Trac's
Subversion module to a Gitlab project (which is, obviously, in Git). All of
yuor SVN changesets will have been converted to Git commits. For this option,
the keys are your original Subversion changeset numbers and the values are the
new Git commit IDs (you may use the full hashes or the shortened ones). These
mappings should be extracted from the output of the C<git svn clone> command.

=item * image_base

A string with the base URL where any embedded or attached images are located.
For Gitlab this will generally be https://<yourgitlabdomain>/<namespace>/<project>/uploads/<hash>
where the domain, namespace, and project should hopefully be self-explanatory,
and the hash is simply a randomized string. Note that this URL should map to
the appropriate uploads directory on your Gitlab server where you have copied
the images/attachments.

=back

These options are used both for markup conversion as well as any necessary
title rewriting, so in addition to the keys just mentioned, you will likely
also need to pass in the options documented for C<gfmtitle> below.

Things that do get converted:

=over

=item * Paragraphs (should have gone without saying)

=item * Headings

=item * Emphasis (bold, italic, and underline; including nesting)

=item * Lists (numbered, bulleted, and lettered; latter being converted to bulleted)

=item * Pre-formatted text and code blocks

=item * Blockquotes

=item * Links

=item * TracLinks

=over

=item * Issues/Tickets

=item * Changesets (including mapping SVN changeset numbers to Git commit IDs)

=back

=item * Image macross (for images on the current wiki page only)

=item * Tables

=back

Things that do I<not> convert (at least not yet):

=over

=item * Definition Lists

=item * Images from anywhere other than the current wiki page

=item * Macros

=back

=cut

sub trac2gfm {
    my ($trac, $opts) = @_;

    my $end_with_nl = $trac =~ m{\n$}s;

    # To properly convert TracLinks using the same title conversions the caller
    # may be supplying when using gfmtitle directly, we need to accept the same
    # here and pass it along to any of our own invocations to that function.
    $opts = {} unless defined $opts && ref($opts) eq 'HASH';

    # Additionally, we need some conversion mappings for ourselves - where wiki
    # images will be living and any SVN changeset -> Git commit mappings.
    $opts->{'image_base'} = '/' unless exists $opts->{'image_base'};
    $opts->{'commits'} = {} unless exists $opts->{'commits'} && ref($opts->{'commits'}) eq 'HASH';

    # Enforce UNIX linebreaks and convert 0xa0 non breaking spaces to regular spaces
    $trac =~ s{\r\n}{\n}gs;
    $trac =~ s{\xa0}{ }g;

    # Headings ('=== Foo ===' -> '### Foo')
    $trac =~ s{^(=+)([^=]+)=*$}{ ('#' x length($1)) . ' ' . crunch($2) }gme;

    # Paragraph spacing
    $trac =~ s{\n{2,}}{\n\n}gs;

    # Blockquotes (opening line only - remaining multiline are handled later)
    $trac =~ s{\n\n\s{2,}(\S[^\n]*)(\n|$)}{\n\n> $1$2}gs;

    # Numbered, lettered, and bulleted lists (preserving nesting/indentation)
    $trac =~ s{^(\s*\d+)[.)\]]\s*}{$1. }gm;
    $trac =~ s{^(\s*)[a-z]+[.)\]]\s*}{$1* }gm;
    $trac =~ s{^(\s*)\*\s*([^\*]+)$}{$1* $2}gm;

    # Various forms of emphasis
    $trac =~ s{__([^\n_]+|[^\n_]+_?[^\n_]+)__}{<ul>$1</ul>}g;
    my $edge = 0;
    $trac =~ s{'''''}{ ++$edge % 2 == 1 ? '**_' : '_**' }ge;
    $trac =~ s{'''}{**}g;
    $trac =~ s{''}{_}g;

    # Preformatting blocks (including highlighter selection)
    $trac =~ s|^\}\}\}$|```|gm;
    $trac =~ s|^\{\{\{(?:#!(\w+))?| '```' . (defined $1 ? $1 : '') |gme;

    # In-line preformatting
    $trac =~ s/(\{\{\{|\}\}\})/`/g;

    # CamelCase internal wiki links
    $trac =~ s{
        (^|\s) ( !? ([A-Z][a-z0-9]+){2,} ) \b
    }{
        substr($2, 0, 1) eq '!'
            ? $1 . substr($2, 1)
            : $1 . '[' . $2 . '](' . gfmtitle($2, $opts) . ')'
    }gxe;

    # Explicit wiki links
    $trac =~ s{
        \[wiki: ([^\s]+) \s* ([^\]]+)? \]
    }{
        my $l_title = gfmtitle($1, $opts);
        defined $2 && length($2) > 0
            ? '[' . $2 . '](' . $l_title . ')'
            : '[' . $l_title . '](' . $l_title . ')'
    }gmex;

    # Named URLs
    $trac =~ s{
        \[ (\w+://[^\]\s]+) \s* ([^\]]+)? \]
    }{
        defined $2 && length($2) > 0
            ? '[' . $2 . '](' . $1 . ')'
            : $1
    }gmex;

    ## Trac project links (issues, commits, users, etc.)
    # Tickets
    $trac =~ s{(?:#|ticket:|bug:)(\d+)}{#$1}g;

    # Changesets
    $trac =~ s{
        ( (r|changeset:)(?<num>\d+) | \[(?<num>\d+)\] )
    }{
        exists $opts->{'commits'}{$+{'num'}}
            ? $opts->{'commits'}{$+{'num'}}
            : $+{'num'}
    }gxe;

    # Image macros
    $trac =~ s{
        \[\[Image\( ([^\)]+) \)\]\]
    }{
        my @path = split('/', $1);
        my $url = $opts->{'image_base'};
        $url .= (substr($url, -1, 1) eq '/' ? '' : '/') . $path[-1];
        sprintf('![%s](%s)', $path[-1], $url);
    }gxe;

    # Manual linebreaks cleanup
    $trac =~ s{\n?(\[\[BR\s*\]\])+}{  }gs;

    # Track contents of the current table for conversion as a whole
    my @table;

    my @lines = split(/\n/, $trac);

    LINE:
    for (my $i = 0; $i <= $#lines; $i++) {
        # Table conversion
        if ($lines[$i] =~ m{^\s*\|\|}s) {
            # We need the entire table before we can convert its markup, so
            # gather the lines into @table while also clearing the current $line
            push(@table, $lines[$i]);
            $lines[$i] = '';
            next LINE;
        } elsif (@table > 0) {
            # We have table content, but just hit a line that is not part of the
            # table, so we can now convert that markup and add it back in at
            # the previous line (since the current one may require its own
            # non-table-y processing).
            $lines[$i-1] = _convert_table(@table);
            @table = ();
        }

        if ($lines[$i] =~ m{^\s*$}) {
            next LINE;
        }

        # Blockquote continuations.
        if ($i > 0 && $lines[$i-1] =~ m{^>}) {
            if ($lines[$i] =~ m{^\s+(\S.*)}) {
                $lines[$i] = "> $1";
            } else {
                # Blockquote was terminated by outdenting, but without the
                # customary blank line in between. Add that, close the block,
                # and move to the next line.
                $lines[$i] = "\n$lines[$i]";
                next LINE;
            }
        }
    }

    # If we still have table content, then we hit the end of the markup right
    # on a table row. Go ahead and consume and convert the straggler.
    push(@lines, _convert_table(@table)) if @table && @table > 0;

    if (@lines == 1) {
        $trac = $lines[0];
    } else {
        $trac = join("\n", @lines);
        $trac =~ s{\n{3,}}{\n\n}gs;
    }

    $trac .= "\n" if $end_with_nl && $trac !~ m{\n$}s;

    return $trac;
}

=head2 gfmtitle ($title_string, $options)

Provided a single line string, C<$title_string>, returns a variant suitable for
use as the title of a GitLab Wiki page. Default mutations include replacement
of all whitespace and disallowed characters with dashes along with a reduction
to non-repeating kebab casing.

Some common technical terms that would otherwise render strangely within the
restrictions of GFM titles are replaced with more verbose versions (e.g. 'C++'
becomes 'c-plus-plus' instead of 'c-' as it would without special handling).

You may also pass in an optional hash reference containing the following
options to override some of the default behavior:

=over

=item * downcase

Defaults to true. Providing any false-y value will cause C<gfmtitle> to retain
the case of your input string, instead of lower-casing it.

=item * unslash

Defaults to true. Providing any false-y value will cause slashes (C</>) to be
retained in the output, instead of converting them to dashes (C<->). Note that
this can cause problems if you are committing your converted wiki pages into a
local Git repository - special care will be needed to escape the retained
slashes so that they are treated as part of the filename itself instead of as a
directory separator.

=item * terms

Allows you to supply your own special term conversions, or override any default
ones provided by this module. This is helpful in the event that your wiki uses
words or phrases which are mangled in unfortunate ways. The keys of the hashref
should be the terms (case-insensitive) as they appear in your wiki titles and
the values should be the form to which they should be converted. For example,
to keep a sane version of 'C++' in your wiki titles for GitLab (where the plus
sign is not allowed), you might do:

    gfmtitle('Languages/C++', { terms => { 'c++' => 'c-plus-plus' } });

=back

=cut

sub gfmtitle {
    my ($title, $opts) = @_;

    my $defaults = {
        downcase => 1,
        unslash  => 1,
        terms    => {},
    };

    return unless defined $title && length($title) > 0;

    # Special-case WikiStart, since TracWiki uses that as the homepage of a wiki
    # and GitLab uses 'home'.
    return 'home' if $title eq 'WikiStart';

    # Override our defaults if caller has provided anything.
    if (defined $opts && ref($opts) eq 'HASH') {
        foreach my $k (keys %{$opts}) {
            $defaults->{$k} = $opts->{$k};
        }
    }

    # Not terrifically wonderful, but some developer/tech/etc. terms that would
    # otherwise convert in very unfortunate ways. Keys are case-insensitive.
    # Values are what we'll mutate them into for GitLab wikis. These are done
    # before any other mangling, so the values don't necessarily have to be
    # perfect "GitLab" identifiers.
    my %special_terms = (
        '&'    => '-and-',
        '@'    => '-at-',
        'c++ ' => 'C-Plus-Plus',
        'a#'   => 'A-Sharp',
        'c#'   => 'C-Sharp',
        'f#'   => 'F-Sharp',
        'j#'   => 'J-Sharp',
        '.net' => '-Dot-Net',
    );

    # Add any user-supplied replacement terms.
    if (exists $defaults->{'terms'} && ref($defaults->{'terms'}) eq 'HASH') {
        $special_terms{$_} = $defaults->{'terms'}{$_} for keys %{$defaults->{'terms'}};
    }

    # GitLab wiki titles are restricted to (roughly) [a-zA-Z0-9_-/].
    # Additionally, they encourage kebab-casing in their examples.
    $title =~ s{/}{-}g  if $defaults->{'unslash'};
    $title =~ s{(^\s+|\s+$)}{}gs;
    $title =~ s{$_}{ $special_terms{$_} }ige for keys %special_terms;
    $title =~ s{[^a-zA-Z0-9/]+}{-}gs;

    if ($defaults->{'downcase'}) {
        $title =~ s{([A-Z][a-z])}{-$1}g if $title =~ m{\b([A-Z][a-z0-9]+){2,}\b}s;
        $title = lc($title);
    }

    $title =~ s{-+}{-}g;
    $title =~ s{(^-+|-+$)}{}gs;

    return $title;
}

sub _convert_table {
    my ($header, @rows) = @_;

    my @headers = _split_table_line($header);
    my @aligns = map { $_ =~ m{^\S.*\s+$}s ? 'l' : $_ =~ m{^\s+.*\S$} ? 'r' : 'c' } @headers;
    my @widths = map { length(crunch($_)) } @headers;

    my ($i, $j);

    for ($i = 0; $i <= $#rows; $i++) {
        $rows[$i] = [map { crunch($_) } _split_table_line($rows[$i])];
        for ($j = 0; $j <= $#{$rows[$i]}; $j++) {
            $widths[$j] = length($rows[$i][$j])
                unless defined $widths[$j]
                    && $widths[$j] > length($rows[$i][$j]);
        }
    }

    # GFM requires the header marker row to be at least three dashes. We add two
    # so there's room for aligning marks.
    @widths = map { $_ >= 5 ? $_ : 5 } @widths;

    # Ensure that we have an alignment for every column (in case there were
    # more columns in a row under the headers). Default is centering.
    push(@aligns, ('c') x ($#widths - $#aligns));

    my @table;

    for ($i = 0; $i <= $#aligns; $i++) {
        $headers[$i] = crunch($headers[$i]) if defined $headers[$i];
        $headers[$i] = _align_cell($headers[$i] // '', $aligns[$i], $widths[$i]);
    }
    push(@table, join(' | ', @headers));

    my @marks;
    for ($i = 0; $i <= $#aligns; $i++) {
        my $bar = '-' x $widths[$i];
        if ($aligns[$i] eq 'l') {
            $bar = ':' . substr($bar, 1);
        } elsif ($aligns[$i] eq 'r') {
            $bar = substr($bar, 0, -1) . ':';
        } else {
            $bar = ':' . substr($bar, 1, -1) . ':';
        }
        push(@marks, $bar);
    }
    push(@table, join(' | ', @marks));

    foreach my $row (@rows) {
        for ($i = 0; $i <= $#aligns; $i++) {
            $row->[$i] = _align_cell($row->[$i] // '', $aligns[$i], $widths[$i]);
        }
        push(@table, join(' | ', @{$row}));
    }

    my $gfm_table = '| ' . join(" |\n| ", @table) . " |\n";
    return $gfm_table;
}

sub _split_table_line {
    my ($line) = @_;

    chomp($line);

    $line =~ s{(^\s*\|\||\|\|\s*$)}{}gs;

    return map { $_ =~ s{(^=|=$)}{}gs; $_ } split(/\|\|/, $line);
}

sub _align_cell {
    my ($text, $align, $width) = @_;

    if ($align eq 'l') {
        $text = sprintf('%-' . $width . 's', $text);
    } elsif ($align eq 'r') {
        $text = sprintf('%' . $width . 's', $text);
    } else {
        $text = sprintf('%-' . $width . 's', (' ' x int(($width - length($text)) / 2)) . $text);
    }

    return $text;
}

=head1 LIMITATIONS

This module makes a few concessions to sloppiness (and tolerated, though not
official, markup), but for the most part it assumes your source content in the
TracWiki markup is generally well-formed and valid.

=head2 Tables

Tables, specifically, will face known limitations in their conversion. GFM
tables do not support row or column spanning, and cannot handle multi-line
contents in the markup (the newline will terminate the current cell's content).
As a result, complicated table markup from TracWiki pages will likely need to
be hand-wrangled after the conversion.

In addition to the lack of spanning in GFM, this converter will base the cell
alignment on the contents of the first row. While TracWiki markup allows each
cell to have its own independent alignment, GFM tables set the alignment on a
per-column basis using markup in the headers.

Headers are also mandatory in GFM tables, whereas they are optional in TracWiki.
The first row of every TracWiki table will be used as the header in the GFM
table, regardless of whether it included the C<||=Foo=||> markup.

=head1 BUGS

There are no known bugs at the time of this release. There may well be some
misfeatures, though.

Please report any bugs or deficiencies you may discover to the module's GitHub
Issues page:

L<https://github.com/jsime/text-trac2gfm/issues>

Pull requests are welcome.

=head1 AUTHORS

Jon Sime <jonsime@gmail.com>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2016 by Jon Sime.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

1;
