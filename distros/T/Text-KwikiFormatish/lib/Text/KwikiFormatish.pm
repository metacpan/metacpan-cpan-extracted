package Text::KwikiFormatish;
use strict;
use warnings;

our $VERSION = '1.11';

use CGI::Util qw(escape unescape);

=head1 NAME

Text::KwikiFormatish - convert Kwikitext into XML-compliant HTML

=head1 SYNOPSIS

  use Text::KwikiFormatish;
  my $xhtml = Text::KwikiFormatish::format($text);

=head1 DESCRIPTION

B<NOTE:> I<This> module is based off of the old L<CGI::Kwiki> formatter. Ideally, L<Text::KwikiFormat> would be written to use the new the new L<Kwiki> formatter.

L<CGI::Kwiki> includes a formatter (L<CGI::Kwiki::Formatter>) for converting
Kwikitext (a nice form of wikitext) to HTML. Unfortunately, it isn't easy to
use the formatter outside the L<CGI::Kwiki> environment. Additionally, the HTML
produced by the formatter isn't XHTML-1 compliant. This module aims to fix both
of these issues and provide an interface similar to L<Text::WikiFormat>.

Essentially, this module is the code from Brian Ingerson's
L<CGI::Kwiki::Formatter> with a C<format> subroutine, code relating to slides
removed, tweaked subroutinesa, and more. 

Since the wikitext spec for input wikitext for this module differs a little
from the default Kwiki formatter, I thought it best to call it "Formatish"
instead of *the* Kwiki Format.

=cut

use vars qw($UPPER $LOWER $ALPHANUM $WORD $WIKIWORD @DEFAULTPROCESSORDER);

$UPPER    = '\p{UppercaseLetter}';
$LOWER    = '\p{LowercaseLetter}';
$ALPHANUM = '\p{Letter}\p{Number}';
$WORD     = '\p{Letter}\p{Number}\p{ConnectorPunctuation}';
$WIKIWORD = "$UPPER$LOWER\\p{Number}\\p{ConnectorPunctuation}";

@DEFAULTPROCESSORDER = qw(
    function
    header_1 header_2 header_3 header_4 header_5 header_6
    escape_html
    horizontal_line comment lists
    code paragraph
    named_http_link no_http_link http_link
    no_mailto_link mailto_link
    no_wiki_link force_wiki_link wiki_link
    inline negation
    bold italic underscore
    mdash
    table
);

=head2 format()

C<format()> takes one or two arguments, with the first always being the
wikitext to translate. The second is a hash of options, but currently the only
option supported is C<prefix> in case you want to prefix wiki links with
sommething. For example,

  my $xml = Text::KwikiFormatish::format(
    $text,
    prefix => '/wiki/',
  );

=cut

sub format {
    my ( $raw, %args ) = @_;

    # create instance of formatter
    my $f = __PACKAGE__->new();

    # translate Text::Wikiformat args to Kwiki formatter args
    $f->{_node_prefix} = $args{prefix} if exists $args{prefix};

    # do the deed
    return $f->process($raw);
}

=head1 EXTENDING

L<CGI::Kwiki::Formatter> was designed to be subclassable so that the formatting
engine could be easily customized. Information on how the Kwiki formatter works
can be found at
L<HowKwikiFormatterWorks|http://www.kwiki.org/index.cgi?HowKwikiFormatterWorks>.

For example, say you wanted to override the markup for strong (bold) text. You
decide that it would make much more sense to write strong text as C<HEYthis is
bold textHEY>. You would subclass Text::KwikiFormatish and use it like so:

    package My::Formatter;
    use base 'Text::KwikiFormatish';
    
    # I simply copied this from Text/KwikiFormatish.pm and tweaked it
    sub bold {
        my ($self, $text) = @_;
        $text =~ s#(?<![$WORD])HEY(\S.*?\S|\S)HEY(?![$WORD])#<strong>$1</strong>#g;
        return $text;
    }
    
    package main;
    my $data = join '', <>;
    print My::Formatter->new->process( $data );

=cut

=head2 Administrative Methods

=over 4

=cut

=item process( TEXT )

Process the given TEXT as KwikiText and return XHTML.

=cut

sub process {
    my ( $self, $wiki_text ) = @_;
    my $array = [];
    push @$array, $wiki_text . "\n";
    for my $method ( $self->process_order ) {
        $array = $self->_dispatch( $array, $method );
    }
    return $self->_combine_chunks($array);
}

=item process_order()

C<process_order()> returns a list of the formatting rules that will be applied
when C<format> is called for this object. If called with a set of formatting
rules (names of class methods), that set of formatting rules will supercede the
default set.

=cut

sub process_order {
    my $self = shift;
    @{ $self->{'process_order'} } = @_ if (@_);
    return ( @{ $self->{'process_order'} } );
}

sub _dispatch {
    my ( $self, $old_array, $method ) = @_;
    return $old_array unless $self->can($method);
    my $new_array;
    for my $chunk (@$old_array) {
        if ( ref $chunk eq 'ARRAY' ) {
            push @$new_array, $self->_dispatch( $chunk, $method );
        }
        else {
            if ( ref $chunk ) {
                push @$new_array, $chunk;
            }
            else {
                push @$new_array, $self->$method($chunk);
            }
        }
    }
    return $new_array;
}

sub _combine_chunks {
    my ( $self, $chunk_array ) = @_;
    my $formatted_text = '';
    for my $chunk (@$chunk_array) {
        $formatted_text .=
              ( ref $chunk eq 'ARRAY' ) ? $self->_combine_chunks($chunk)
            : ( ref $chunk ) ? $$chunk
            : $chunk;
    }
    return $formatted_text;
}

=item * new() - the constructor

=cut

sub new {
    my ( $class, %args ) = @_;
    my $self = {};
    bless $self, $class;
    my %defs = ( node_prefix => './', );
    my %collated = ( %defs, %args );
    foreach my $k ( keys %defs ) {
        $self->{ "_" . $k } = $collated{$k};
    }
    $self->process_order(@DEFAULTPROCESSORDER);
    $self->init(%args);
    return $self;
}

=item * init() - called by the constructor immediately after the objects creation

=cut

sub init { }

=back 

=cut

=head2 Helper Methods

=over 4

=item * split_method( TEXT, REGEXP, METHOD ) - calls METHOD on any matches in TEXT for groups in REGEXP

=cut

sub split_method {
    my ( $self, $text, $regexp, $method ) = @_;
    my $i = 0;
    map { $i++ % 2 ? \$self->$method($_) : $_ } split $regexp, $text;
}

=item * escape_html( TEXT ) - returns TEXT with HTML entities escaped

=cut

sub escape_html {
    my ( $self, $text ) = @_;
    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    $text;
}

=back 

=cut

=head2 Formatter Methods

These are the methods you'll probably override most often. They define the
regular expressions that the formatter uses to split text as well as what to do
with each chunk.

Many of these methods have corrosponding C<format_xxx> methods, which take the
chunk and format it as XHTML.

=over 4

=item * function - user-definable functions

=cut

sub function {
    my ( $self, $text ) = @_;
    $self->split_method( $text, qr{\[\&(\w+\b.*?)\]}, '_function_format', );
}

sub _function_format {
    my ( $self,   $text ) = @_;
    my ( $method, @args ) = split;
    $self->_isa_function($method)
        ? $self->$method(@args)
        : "<!-- Function not supported here: $text -->\n";
}

sub _isa_function {
    my ( $self, $function ) = @_;
    defined { map { ( $_, 1 ) } $self->user_functions }->{$function}
        and $self->can($function);
}

=item * table - tabular data

=cut

sub table {
    my ( $self, $text ) = @_;
    my @array;
    while ( $text =~ /(.*?)(^\|[^\n]*\|\n.*)/ms ) {
        push @array, $1;
        my $table;
        ( $table, $text ) = $self->_parse_table($2);
        push @array, $table;
    }
    push @array, $text if length $text;
    return @array;
}

sub _parse_table {
    my ( $self, $text ) = @_;
    my $error = '';
    my $rows;
    while ( $text =~ s/^(\|(.*)\|\n)// ) {
        $error .= $1;
        my $data = $2;
        my $row  = [];
        for my $datum ( split /\|/, $data ) {
            $datum =~ s/^\s*(.*?)\s*$/$1/;
            if ( $datum =~ s/^<<(\S+)$// ) {
                my $marker = $1;
                while ( $text =~ s/^(.*\n)// ) {
                    my $line = $1;
                    $error .= $line;
                    if ( $line eq "$marker\n" ) {
                        $marker = '';
                        last;
                    }
                    $datum .= $line;
                }
                if ( length $marker ) {
                    return ( $error, $text );
                }
            }
            push @$row, $datum;
        }
        push @$rows, $row;
    }
    return ( $self->format_table($rows), $text );
}

=item * format_table - format the table data as XHTML

=cut

sub format_table {
    my ( $self, $rows ) = @_;
    my $cols = 0;
    for (@$rows) {
        $cols = @$_ if @$_ > $cols;
    }
    my $table = qq{<table border="1">\n};
    for my $row (@$rows) {
        $table .= qq{<tr valign="top">\n};
        for ( my $i = 0; $i < @$row; $i++ ) {
            my $colspan = '';
            if ( $i == $#{$row} and $cols - $i > 1 ) {
                $colspan = ' colspan="' . ( $cols - $i ) . '"';
            }
            my $cell = $self->escape_html( $row->[$i] );
            $cell = qq{<pre>$cell</pre>\n}
                if $cell =~ /\n/;
            $cell = '&nbsp;' unless length $cell;
            $table .= qq{<td$colspan>$cell</td>\n};
        }
        $table .= qq{</tr>\n};
    }
    $table .= qq{</table>\n};
    return \$table;
}

=item * no_wiki_link - things that look like wikilinks but are forced not to be

=cut

sub no_wiki_link {
    my ( $self, $text ) = @_;
    $self->split_method( $text,
        qr{!([$UPPER](?=[$WORD]*[$UPPER])(?=[$WORD]*[$LOWER])[$WORD]+)},
        'no_wiki_link_format', );
}

=item * no_wiki_link_format - typically just the text that could have been a link

=cut

sub no_wiki_link_format {
    my ( $self, $text ) = @_;
    return $text;
}

=item * wiki_link - a WikiLink

=cut

sub wiki_link {
    my ( $self, $text ) = @_;
    $self->split_method( $text,
        qr{([$UPPER](?=[$WORD]*[$UPPER])(?=[$WORD]*[$LOWER])[$WORD]+)},
        'wiki_link_format', );
}

=item * force_wiki_link - a link that normally wouldn't have been one but is forced to be

=cut

sub force_wiki_link {
    my ( $self, $text ) = @_;
    $self->split_method( $text, qr{(?<!\!)\[([$ALPHANUM\-:]+)\]},
        'wiki_link_format', );
}

=item * wiki_link_format - how to format wikilinks as XHTML

=cut

sub wiki_link_format {
    my ( $self, $text ) = @_;
    my $url       = $self->escape($text);
    my $wiki_link = qq{<a href="./$url">$text</a>};
    return $wiki_link;
}

=item * no_http_link - what normally would have been an HTTP URI, but isn't

=cut

sub no_http_link {
    my ( $self, $text ) = @_;
    $self->split_method( $text, qr{(!(?:https?|ftp|irc):\S+?)}m,
        'no_http_link_format', );
}

=item * no_http_link_format - typically just the text

=cut

sub no_http_link_format {
    my ( $self, $text ) = @_;
    $text =~ s#!##;
    return $text;
}

=item * http_link - a regular http:// hyperlink

=cut

sub http_link {
    my ( $self, $text ) = @_;
    $self->split_method( $text,
        qr{((?:https?|ftp|irc):\S+?(?=[),.:;]?\s|$))}m,
        'http_link_format', );
}

=item * http_link_format - how to format the given link

=cut

sub http_link_format {
    my ( $self, $text ) = @_;
    if ( $text =~ /^http.*\.(?i:jpg|gif|jpeg|png)$/ ) {
        return $self->img_format($text);
    }
    else {
        return $self->link_format($text);
    }
}

=item * no_mailto_link - what could have been a mailto: hyperlink

=cut

sub no_mailto_link {
    my ( $self, $text ) = @_;
    $self->split_method( $text,
        qr{(![$ALPHANUM][$WORD\-\.]*@[$WORD][$WORD\-\.]+)}m,
        'no_mailto_link_format', );
}

=item * no_mailto_link_format - typically just text

=cut

sub no_mailto_link_format {
    my ( $self, $text ) = @_;
    $text =~ s#!##;
    return $text;
}

=item * mailto_link - a mailto: hyperlink

=cut

sub mailto_link {
    my ( $self, $text ) = @_;
    $self->split_method( $text,
        qr{([$ALPHANUM][$WORD\-\.]*@[$WORD][$WORD\-\.]+)}m,
        'mailto_link_format', );
}

=item * mailto_link_format - how to format the mailto: link

=cut

sub mailto_link_format {
    my ( $self, $text ) = @_;
    my $dot = ( $text =~ s/\.$// ) ? '.' : '';
    qq{<a href="mailto:$text">$text</a>$dot};
}

=item * img_format - inline images

=cut

sub img_format {
    my ( $self, $url ) = @_;
    return qq{<img src="$url" />};
}

=item * link_format - a helper method for named_http_link_format and http_link_format

=cut

sub link_format {
    my ( $self, $text ) = @_;
    $text =~ s/(^\s*|\s+(?=\s)|\s$)//g;
    my $url = $text;
    $url = $1 if $text =~ s/(.*?) +//;
    $url =~ s/https?:(?!\/\/)//;
    return qq{<a href="$url">$text</a>};
}

=item * named_http_link - an HTTP URI with a label

=cut

sub named_http_link {
    my ( $self, $text ) = @_;
    $self->split_method( $text,
        qr{(?<!\!)\[([^\[\]]*?(?:https?|ftp|irc):\S.*?)\]},
        'named_http_link_format', );
}

=item * named_http_link_format - how to format the named link

=cut

sub named_http_link_format {
    my ( $self, $text ) = @_;
    if ( $text =~ m#(.*)((?:https?|ftp|irc):.*)# ) {
        $text = "$2 $1";
    }
    return $self->link_format($text);
}

=item * inline - code samples or fixed-width font, usually

=cut

sub inline {
    my ( $self, $text ) = @_;
    $self->split_method( $text, qr{(?<!\!)\[=(.*?)(?<!\\)\]}, 'inline_format',
    );
}

=item * inline_format - how to format inline markup

=cut

sub inline_format {
    my ( $self, $text ) = @_;
    "<code>$text</code>";
}

=item * negation - when not to make an inline format

=cut

sub negation {
    my ( $self, $text ) = @_;
    $text =~ s#\!(?=\[)##g;
    return $text;
}

=item * bold - strong text

=cut

sub bold {
    my ( $self, $text ) = @_;
    $text =~ s#(?<![$WORD])\*(\S.*?\S|\S)\*(?![$WORD])#<strong>$1</strong>#g;
    return $text;
}

=item * italic - emphasized text

=cut

sub italic {
    my ( $self, $text ) = @_;
    $text =~ s#(?<![$WORD<])//(\S.*?\S|\S)//(?![$WORD])#<em>$1</em>#g;
    return $text;
}

=item * underscore - if you reall, really, really feel the need to use underlined text

=cut

sub underscore {
    my ( $self, $text ) = @_;
    $text =~ s#(?<![$WORD])_(\S.*?\S)_(?![$WORD])#<u>$1</u>#g;
    return $text;
}

=item * code - usually indented text creates blocks of preformatted text

=cut

sub code {
    my ( $self, $text ) = @_;
    $self->split_method( $text, qr{(^ +[^ \n].*?\n)(?-ms:(?=[^ \n]|$))}ms,
        'code_format', );
}

=item * code_format - how to format the code blocks

=cut

sub code_format {
    my ( $self, $text ) = @_;
    $self->_code_postformat( $self->_code_preformat($text) );
}

sub _code_preformat {
    my ( $self, $text ) = @_;
    my ($indent) = sort { $a <=> $b } map {length} $text =~ /^( *)\S/mg;
    $text =~ s/^ {$indent}//gm;

    #return $self->escape_html($text); ## already done in process order
    return $text;
}

sub _code_postformat {
    my ( $self, $text ) = @_;
    return "<pre>$text</pre>\n";
}

=item * lists - itemized or enumerated lists

=cut

sub lists {
    my ( $self, $text ) = @_;
    my $switch = 0;
    return map {
        my $level = 0;
        my @tag_stack;
        if ( $switch++ % 2 ) {
            my $text  = '';
            my @lines = /(.*\n)/g;
            for my $line (@lines) {
                $line =~ s/^([0\*]+) //;
                my $new_level = length($1);
                my $tag = ( $1 =~ /0/ ) ? 'ol' : 'ul';
                if ( $new_level > $level ) {
                    for ( 1 .. ( $new_level - $level ) ) {
                        push @tag_stack, $tag;
                        $text .= "<$tag>\n";
                    }
                    $level = $new_level;
                }
                elsif ( $new_level < $level ) {
                    for ( 1 .. ( $level - $new_level ) ) {
                        $tag = pop @tag_stack;
                        $text .= "</$tag>\n";
                    }
                    $level = $new_level;
                }
                $text .= "<li>$line</li>";
            }
            for ( 1 .. $level ) {
                my $tag = pop @tag_stack;
                $text .= "</$tag>\n";
            }
            $_ = $self->lists_format($text);
        }
        $_;
        }
        split m!(^[0\*]+ .*?\n)(?=(?:[^0\*]|$))!ms, $text;
}

=item * lists_format - how to format the lists

=cut

sub lists_format {
    my ( $self, $text ) = @_;
    return $text;
}

=item * paragraph - normal, boring paragraphs

=cut

sub paragraph {
    my ( $self, $text ) = @_;
    my $switch = 0;
    return map {
        unless ( $switch++ % 2 )
        {
            $_ = $self->paragraph_format($_);
        }
        $_;
        }
        split m!(\n\s*\n)!ms, $text;
}

=item * paragraph_format - how to format paragraphs as XHTML

=cut

sub paragraph_format {
    my ( $self, $text ) = @_;
    return ''    if $text =~ /^[\s\n]*$/;
    return $text if $text =~ /^<(o|u)l>/i;
    return "<p>\n$text\n</p>\n";
}

=item * horizontal_line - horizontal rules

=cut

sub horizontal_line {
    my ( $self, $text ) = @_;
    $self->split_method( $text, qr{^(----+)\s*$}m, 'horizontal_line_format',
    );
}

=item * horizontal_line_format - horizontal rules as XHTML

=cut

sub horizontal_line_format {
    my ($self) = @_;
    my $text = "<hr/>\n";
    return $text;
}

=item * mdash - long horizontal dashes

=cut

sub mdash {
    my ( $self, $text ) = @_;
    $text =~ s/([$WORD])-{3}([$WORD])/$1&#151;$2/g;
    return $text;
}

=item * comment - text that doesn't show up in the final markup

=cut

sub comment {
    my ( $self, $text ) = @_;
    $self->split_method( $text, qr{^\#\#(.*)$}m, 'comment_line_format', );
}

=item * comment_line_format - make XML comments out of 'em

=cut

sub comment_line_format {
    my ( $self, $text ) = @_;
    return "<!-- $text -->\n";
}

=item * header_N and header_N_format - where N is a number from 1 to 6, inclusive

=cut

for my $num ( 1 .. 6 ) {
    no strict 'refs';
    *{"header_$num"} = sub {
        my ( $self, $text ) = @_;
        $self->split_method( $text, qr#^={$num} (.*?)(?: =*)?\n#m,
            "header_${num}_format", );
    };
    *{"header_${num}_format"} = sub {
        my ( $self, $text ) = @_;
        $text =~ s/=+\s*$//;
        $text = $self->escape_html($text);
        return "<h$num>$text</h$num>\n";
    };
}

=back 

=cut

=head2 Adding User Functions

=over 4

=cut

=item * user_functions() - returns a list of custom markup plugins to handle

The default user functions are C<icon>, C<img> and C<glyph>. In the default markup, plugins are entered in the form of C<[&name arg1 arg2 ...]>.

=cut

sub user_functions {
    qw(
        icon
        img
        glyph
    );
}

=item * icon - inserts the named image with a CSS class of "icon"

    [&icon /icons/fun.png]

=cut

sub icon {
    my ( $self, $href ) = @_;
    return qq( <img src="$href" class="icon" alt="(icon)" /> );
}

=item * img - inserts a regular image, with an optional title

    [&img some_image.jpg]

    [&img another_image.jpg This image will have a title attribute]

=cut

sub img {
    my ( $self, $href, @title ) = @_;
    my $title  = join( ' ', @title ) || '';
    my $output = qq( <p style="text-align:center;"><img 
        src="$href" alt="(see caption below)" title="$title" 
        align="middle" border="0" /> );
    $output .= @title ? "<br/><small>$title</small>" : '';
    return $output . '</p>';
}

=item * glyph - attempts to insert an image that's aligned with the vertical middle of the text, but doesn't work due to the implementation of the parser

=cut

sub glyph {

    # FIXME - BROKEN! Plugins like to separate the paragraphs
    my ( $self, $href, @title ) = @_;
    my $title = join( ' ', @title ) || '*';
    return qq( <img 
        src="$href" 
        alt="$title" title="$title" 
        align="middle" border="0" 
        /> );
}

=back

=cut

=head1 DIFFERENCES FROM THE CGI::KWIKI FORMATTER

=over 4

=item * The output of the formatter is XML-compliant.

=item * Extra equal signs at the end of headings will be removed from the output for compatibility with other wikitext formats.

=item * Italicized text is marked up by two slashes instead of one. This is to prevent weirdness when writing filesystem paths in Kwikitext -- e.g., the text "Check /etc or /var or /usr/" will have unexpected results when formatted in a regular Kwiki.

=item * Horizontal rules, marked by four or more hyphens, may be followed by spaces. 

=item * Processing order of text segments has been changed (tables are processed last)

=item * Bold text is marked up as C<E<lt>strongE<gt>> instead of C<E<lt>bE<gt>>

=item * "Inline" is marked up as C<E<lt>codeE<gt>> instead of C<E<lt>ttE<gt>>

=item * mdashes (really long hyphens) are created with wikitext C<like---this>

=item * Tables and code sections are not indented with C<E<lt>blockquoteE<gt>> tags

=item * Comments do not have to have a space immediately following the hash

=item * Patch to named_link code

=item * All code pertaining to slides or Kwiki access control is removed, as neither are within the scope of this module

=back

=head2 Plugins

I've included two plugins, C<img> and C<icon>, to do basic image support besides the standard operation of including an image when the URL ends with a common image extension.

=cut

=head1 EXAMPLES

Here's some kwiki text. (Compare with
L<KwikiFormattingRules|http://www.kwiki.org/index.cgi?KwikiFormattingRules>.)

    = Level 1 Header
    
    == Level 2 with optional trailing equals ==
    
    Kwikitext provides a bit more flexibility than regular wikitext.
    
    All HTML code is <escaped>. Horizontal rules are four or more hyphens:
    
    ----
    
    While you can add an mdash---like this.
    
    ##
    ## you can add comments in the kwikitext which appear as XML comments
    ##
    
    == Links
    
    === Itemized Lists
    
    * Fruit
    ** Oranges
    ** Apples
    * Eggs
    * Salad
    
    === Enumerated Lists
    
    ##
    ## below are zero's, not "oh's"
    ##
    
    0 One
    0 Two
    0 Three
    
    * Comments in the wikitext
    * Easier:
    ** Bold/strong
    ** Italic/emphasized
    
    == More Markup
    
    *strong or bold text*
    
    //emphasized or italic text//
    
      indented text is verbatim (good for code)
    
    == Links
    
    WikiLink
    
    !NotAWikiLink
    
    http://www.kwiki.org/
    
    [Kwiki named link http://www.kwiki.org/]
    
    == Images
    
    http://search.cpan.org/s/img/cpan_banner.png
    
    == KwikiFormatish plugins
    
    This inserts an image with the CSS class of "icon" -- good for inserting a right-aligned image for text to wrap around.
    
    [&icon /images/logo.gif]
    
    The following inserts an image with an optional caption:
    
    [&img /images/graph.gif Last Month's Earnings]

=head1 AUTHOR

Maintained by Ian Langworth - ian@cpan.org

Based on L<CGI::Kwiki::Formatter> by L<Brian
Ingerson|http://search.cpan.org/~ingy/>.

Thanks to L<Jesse Vincent|http://search.cpan.org/~jesse/> for the
C<process_order> patch, related documentation and testing.

Additional thanks to Mike Burns, Ari Pollak and Ricardo SIGNES for additional testing.

=head1 SEE ALSO

L<CGI::Kwiki>, L<CGI::Kwiki::Formatter>, L<Text::WikiFormat>

=head1 LICENSE

This is free software. You may use it and redistribute it under the same terms
as perl itself.

=cut

1;

