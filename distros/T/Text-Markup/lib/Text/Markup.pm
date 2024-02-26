package Text::Markup;

use 5.8.1;
use strict;
use warnings;
use Text::Markup;
use Text::Markup::None;
use Carp;

our $VERSION = '0.33';

my %_PARSER_FOR;
my %REGEX_FOR = (
    html          => qr{x?html?},
    markdown      => qr{m(?:d(?:own)?|kdn?|arkdown)},
    multimarkdown => qr{mm(?:d(?:own)?|kdn?|arkdown)},
    pod           => qr{p(?:od|m|l)},
    textile       => qr{textile},
    trac          => qr{tra?c},
    mediawiki     => qr{(?:m(?:edia)?)?wiki},
    rest          => qr{re?st},
    asciidoc      => qr{a(?:sc(?:iidoc)?|doc)?},
    bbcode        => qr{bb(?:code)?},
    creole        => qr{creole},
);

sub register {
    my ($class, $name, $regex) = @_;
    my $pkg = caller;
    $REGEX_FOR{$name}   = $regex;
    $_PARSER_FOR{$name} = $pkg->can('parser')
        or croak "No parser() function defind in $pkg";
}

sub _parser_for {
    my ($self, $format) = @_;
    return Text::Markup::None->can('parser') unless $format;
    return $_PARSER_FOR{$format} if $_PARSER_FOR{$format};
    my $pkg = __PACKAGE__ . '::' . ($format eq 'html' ? 'HTML' : ucfirst $format);
    eval "require $pkg; 1" or die $@;
    return $_PARSER_FOR{$format} = $pkg->can('parser')
        || croak "No parser() function defind in $pkg";
}

sub formats {
    sort keys %REGEX_FOR;
}

sub format_matchers { %REGEX_FOR }

sub new {
    my $class = shift;
    bless { default_encoding => 'UTF-8', @_ } => $class;
}

sub parse {
    my $self = shift;
    my %p = @_;
    my $file = $p{file} or croak "No file parameter passed to parse()";
    croak "$file does not exist" unless -e $file && !-d _;

    my $parser = $self->_get_parser(\%p);
    return $parser->(
        $file,
        $p{encoding} || $self->default_encoding,
        $p{options} || [],
    );
}

sub default_format {
    my $self = shift;
    return $self->{default_format} unless @_;
    $self->{default_format} = shift;
}

sub default_encoding {
    my $self = shift;
    return $self->{default_encoding} unless @_;
    $self->{default_encoding} = shift;
}

sub _get_parser {
    my ($self, $p) = @_;
    my $format = $p->{format}
        || $self->guess_format($p->{file})
        || $self->default_format;

    return $self->_parser_for($format);
}

sub guess_format {
    my ($self, $file) = @_;
    for my $format (keys %REGEX_FOR) {
        return $format if $file =~ qr{[.]$REGEX_FOR{$format}$};
    }
    return;
}

1;
__END__

=head1 Name

Text::Markup - Parse text markup into HTML

=head1 Synopsis

  my $parser = Text::Markup->new(
      default_format   => 'markdown',
      default_encoding => 'UTF-8',
  );

  my $html = $parser->parse(file => $markup_file);

=head1 Description

This class is really simple. All it does is take the name of a file and return
an HTML-formatted version of that file. The idea is that one might have files
in lots of different markups, and not know or care what markups each uses.
It's the job of this module to figure that out, parse it, and give you the
resulting HTML.

This distribution includes support for a number of markup formats:

=over

=item * L<Asciidoc|https://asciidoc.org>

=item * L<BBcode|https://www.bbcode.org/>

=item * L<Creole|https://www.wikicreole.org/>

=item * L<HTML|https://whatwg.org/html>

=item * L<Markdown|https://daringfireball.net/projects/markdown/>

=item * L<MediaWiki|https://en.wikipedia.org/wiki/Help:Contents/Editing_Wikipedia>

=item * L<MultiMarkdown|https://fletcherpenney.net/multimarkdown/>

=item * L<Pod|perlpod>

=item * L<reStructuredText|https://docutils.sourceforge.io/rst.html>

=item * L<Textile|https://textile-lang.com/>

=item * L<Trac|https://trac.edgewall.org/wiki/WikiFormatting>

=back

Modules under the Text::Markup namespace provide these parsers, and Text::Markup
automatically loads them on recognizing file name suffixes documented for each
module. To change the file extensions recognized for a particular parser (except
for L<Text::Markup::None>), load it directly and pass a regular expression. For
example, to have the Mediawiki parser recognized files with the suffixes
C<truck>, C<truc>, C<track>, or C<trac>, load it like so:

  use Text::Markup::Mediawiki qr{tr[au]ck?};

Adding support for more markup languages is straight-forward, and patches
adding them to this distribution are also welcome. See L</Add a Parser> for
step-by-step instructions.

Or if you just want to use this module, then read on!

=head1 Interface

=head2 Constructor

=head3 C<new>

  my $parser = Text::Markup->new(default_format => 'markdown');

Supported parameters:

=over

=item C<default_format>

The default format to use if one isn't passed to C<parse()> and one can't be
guessed.

=item C<default_encoding>

The character encoding in which to assume a file is encoded if it's not
otherwise explicitly determined by examination of the source file. Defaults to
"UTF-8".

=back

=head2 Class Methods

=head3 C<register>

  Text::Markup->register(foobar => qr{fb|foob(?:ar)?});

Registers a markup parser. You likely won't need to use this method unless
you're creating a new markup parser and not contributing it back to the
Text::Markup project. See L</Add a Parser> for details.

=head3 C<formats>

  my @formats = Text::Markup->formats;

Returns a list of all of the formats currently recognized by Text::Markup.
This will include all core parsers (except for "None") and any that have been
loaded elsewhere and that call C<register> to register themselves.

=head3 C<format_matchers>

  my %matchers = Text::Markup->format_matchers;

Returns a list of key/value pairs mapping all the formats returned by
C<formats> to the regular expressions used to match them.

=head2 Instance Methods

=head3 C<parse>

  my $html = $parser->parse(file => $file_to_parse);

Parses a file and return the generated HTML, or C<undef> if no markup was
found in the file. Supported parameters:

=over

=item C<file>

The file from which to read the markup to be parsed. Required.

=item C<format>

The markup format in the file, which determines the parser used to parse it.
If not specified, Text::Markup will try to guess the format from the file's
suffix. If it can't guess, it falls back on C<default_format>. And if that
attribute is not set, it uses the C<none> parser, which simply encodes the
entire file and wraps it in a C<< <pre> >> element.

=item C<encoding>

The character encoding to assume the source file is encoded in (if such cannot
be determined by other means, such as a
L<BOM|https://en.wikipedia.org/wiki/Byte_order_mark>). If not specified, the
value of the C<default_encoding> attribute will be used, and if that attribute
is not set, UTF-8 will be assumed.

=item C<options>

An array reference of options for the parser. See the documentation of the
various parser modules for details.

=back

=head3 C<default_format>

  my $format = $parser->default_format;
  $parser->default_format('markdown');

An accessor for the default format attribute.

=head3 C<default_encoding>

  my $encoding = $parser->default_encoding;
  $parser->default_encoding('Big5');

An accessor for the default encoding attribute.

=head3 C<guess_format>

  my $format = $parser->guess_format($filename);

Compares the passed file name's suffix to the regular expressions of all
registered formatting parser and returns the first one that matches. Returns
C<undef> if none matches.

=head1 Add a Parser

Adding support for markup formats not supported by the core Text::Markup
distribution is a straight-forward exercise. Say you wanted to add a "FooBar"
markup parser. Here are the steps to take:

=over

=item 1

Fork L<this project on GitHub|https://github.com/theory/text-markup/>

=item 2

Clone your fork and create a new branch in which to work:

  git clone git@github.com:$USER/text-markup.git
  cd text-markup
  git checkout -b foobar

=item 3

Create a new module named C<Text::Markup::FooBar>. The simplest thing to do is
copy an existing module and modify it. The HTML parser is probably the simplest:

  cp lib/Text/Markup/HTML.pm lib/Text/Markup/FooBar.pm
  perl -i -pe 's{HTML}{FooBar}g' lib/Text/Markup/FooBar.pm
  perl -i -pe 's{html}{foobar}g' lib/Text/Markup/FooBar.pm

=item 4

Implement the C<parser> function in your new module. If you were to use a
C<Text::FooBar> module, it might look something like this:

  package Text::Markup::FooBar;

  use 5.8.1;
  use strict;
  use Text::FooBar ();
  use File::BOM qw(open_bom)

  sub import {
      # Replace the regex if passed one.
      Text::Markup->register( foobar => $_[1] ) if $_[1];
  }

  sub parser {
      my ($file, $encoding, $opts) = @_;
      my $md = Text::FooBar->new(@{ $opts || [] });
      open_bom my $fh, $file, ":encoding($encoding)";
      local $/;
      my $html = $md->parse(<$fh>);
      return unless $html =~ /\S/;
      utf8::encode($html);
      return join( "\n",
          '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />',
          '</head>',
          '<body>',
          $html,
          '</body>',
          '</html>',
      );
  }

Use the C<$encoding> argument as appropriate to read in the source file. If
your parser requires that text be decoded to Perl's internal form, use of
L<File::BOM> is recommended, so that an explicit BOM will determine the
encoding. Otherwise, fall back on the specified encoding. Note that some
parsers, such as an HTML parser, would want text encoded before it parsed it.
In such a case, read in the file as raw bytes:

      open my $fh, '<:raw', $file or die "Cannot open $file: $!\n";

The returned HTML, however, B<must be encoded in UTF-8>. Please include an
L<encoding declaration|https://en.wikipedia.org/wiki/Character_encodings_in_HTML>,
such as a content-type C<< <meta> >> element:

  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />

This will allow any consumers of the returned HTML to parse it correctly.
If the parser parsed no content, C<parser()> should return C<undef>.

=item 5

Edit F<lib/Text/Markup.pm> and add an entry to its C<%REGEX_FOR> hash for your
new format. The key should be the name of the format (lowercase, the same as
the last part of your module's name). The value should be a regular expression
that matches the file extensions that suggest that a file is formatted in your
parser's markup language. For our FooBar parser, the line might look like
this:

    foobar => qr{fb|foob(?:ar)?},

=item 6

Add a file in your parser's markup language to F<t/markups>. It should be
named for your parser and end in F<.txt>, that is, F<t/markups/foobar.txt>.

=item 7

Add an HTML file, F<t/html/foobar.html>, which should be the expected output
once F<t/markups/foobar.txt> is parsed into HTML. This will be used to test
that your parser works correctly.

=item 8

Edit F<t/formats.t> by adding a line to its C<__DATA__> section. The line
should be a comma-separated list describing your parser. The columns are:

=over

=item * Format

The lowercased name of the format.

=item * Format Module

The name of the parser module.

=item * Required Module

The name of a module that's required to be installed in order for your parser
to load.

=item * Extensions

Additional comma-separated values should be a list of file extensions that
your parser should recognize.

=back

So for our FooBar parser, it might look like this:

  markdown,Text::Markup::FooBar,Text::FooBar 0.22,fb,foob,foobar

=item 9

Test your new parser by running

  prove -lv t/formats.t

This will test I<all> included parsers, but of course you should only pay
attention to how your parser works. Tweak until your tests pass. Note that one
test has the parser parse a file with just a couple of empty lines, to ensure
that the parser finds no content and returns C<undef>.

=item 10

Don't forget to write the documentation in your new parser module! If you
copied F<Text::Markup::HTML>, you can just modify as appropriate.

=item 11

Add any new module requirements to the C<requires> section of F<Build.PL>.

=item 12

Commit and push the branch to your fork on GitHub:

  git add .
  git commit -am 'Add great new FooBar parser!'
  git push origin -u foobar

=item 13

And finally, submit a pull request to the upstream repository via the GitHub
UI.

=back

If you don't want to submit your parser, you can still create and use one
independently. Just omit editing the C<%REGEX_FOR> hash in this module and make
sure you C<register> the parser manually with a default regular expression
in the C<import> method, like so:

  package My::Markup::FooBar;
  use Text::Markup;
  sub import {
      Text::Markup->register( foobar => $_[1] || qr{fb|foob(?:ar)?} );
  }

This will be useful for creating private parsers you might not want to
contribute, or that you'd want to distribute independently.

=head1 See Also

=over

=item *

The L<markup|https://github.com/github/markup> Ruby library -- the inspiration
for this module -- provides similar functionality, and is used to parse
F<README.your_favorite_markup> on GitHub.

=item *

L<Markup::Unified> offers similar functionality.

=back

=head1 Support

This module is stored in an open
L<GitHub repository|https://github.com/theory/text-markup/>. Feel free to
fork and contribute!

Please file bug reports via
L<GitHub Issues|https://github.com/theory/text-markup/issues/>.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

Copyright (c) 2011-2024 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
