use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use XML::Parser;

# Stream_Delimiter: when this string is found alone on a line while parsing
# from a stream, the parse ends as if it saw EOF.  The intended use is with
# a stream of XML documents in a MIME multipart format.

my $delim = '--BOUNDARY--';

# Helper: write content to a temp file and return an open read handle
sub make_stream {
    my ($content) = @_;
    my ( $fh, $fname ) = tempfile( UNLINK => 1, SUFFIX => '.xml' );
    binmode $fh;
    print $fh $content;
    close $fh;
    open my $rfh, '<', $fname or die "Cannot reopen $fname: $!";
    return $rfh;
}

# ===== Basic: two documents separated by delimiter =====
{
    my $doc1 = qq{<root><a/><b/></root>\n};
    my $doc2 = qq{<root><c/><d/><e/></root>\n};
    my $stream_content = $doc1 . "$delim\n" . $doc2;

    my $fh = make_stream($stream_content);

    my @elts1;
    my $p = XML::Parser->new(
        Stream_Delimiter => $delim,
        Handlers         => {
            Start => sub { push @elts1, $_[1] },
        },
    );

    $p->parse($fh);
    is_deeply( \@elts1, [qw(root a b)], 'first parse sees doc1 elements' );

    # Parse the second document from the same filehandle
    my @elts2;
    $p = XML::Parser->new(
        Handlers => {
            Start => sub { push @elts2, $_[1] },
        },
    );
    $p->parse($fh);
    is_deeply( \@elts2, [qw(root c d e)], 'second parse sees doc2 elements' );

    close $fh;
}

# ===== Delimiter must be alone on its own line =====
{
    # Delimiter embedded inside element content should NOT trigger
    my $content = qq{<root>$delim</root>\n};
    my $fh      = make_stream($content);

    my $chardata = '';
    my $p        = XML::Parser->new(
        Stream_Delimiter => $delim,
        Handlers         => {
            Char => sub { $chardata .= $_[1] },
        },
    );

    $p->parse($fh);
    is( $chardata, $delim, 'delimiter inside element content is parsed as text' );

    close $fh;
}

# ===== Delimiter requires preceding newline =====
{
    # The delimiter mechanism uses $/ = "\n$delim\n", so the delimiter
    # must appear after a newline to be recognized.  A delimiter at the
    # very start of the file (no preceding newline) is NOT recognized
    # and is treated as part of the content.
    my $content = "$delim\n" . qq{<root/>\n};
    my $fh      = make_stream($content);

    # This will fail to parse because "$delim\n<root/>\n" is not valid XML
    my $p = XML::Parser->new(
        Stream_Delimiter => $delim,
        Handlers         => {
            Start => sub { },
        },
    );

    eval { $p->parse($fh) };
    like( $@, qr/not well-formed|syntax error|no element found/,
        'delimiter at start of file (no preceding newline) is not recognized' );

    close $fh;
}

# ===== Multiple sequential documents =====
{
    my @docs = (
        qq{<d1><x/></d1>\n},
        qq{<d2><y/><z/></d2>\n},
        qq{<d3/>\n},
    );
    my $stream = join( "$delim\n", @docs );
    my $fh = make_stream($stream);

    for my $i ( 0 .. 2 ) {
        my @elts;
        my $p = XML::Parser->new(
            Stream_Delimiter => $delim,
            Handlers         => {
                Start => sub { push @elts, $_[1] },
            },
        );
        $p->parse($fh);
        my $n = $i + 1;
        ok( scalar @elts > 0, "document $n: at least one element parsed" );
        like( $elts[0], qr/^d$n$/, "document $n: root element is d$n" );
    }

    close $fh;
}

# ===== Delimiter with special regex characters =====
{
    my $special_delim = '---[boundary]+++';
    my $doc1          = qq{<a>text</a>\n};
    my $doc2          = qq{<b>more</b>\n};
    my $stream        = $doc1 . "$special_delim\n" . $doc2;
    my $fh            = make_stream($stream);

    my @elts;
    my $p = XML::Parser->new(
        Stream_Delimiter => $special_delim,
        Handlers         => {
            Start => sub { push @elts, $_[1] },
        },
    );
    $p->parse($fh);
    is_deeply( \@elts, ['a'], 'special-char delimiter: first doc parsed correctly' );

    @elts = ();
    $p    = XML::Parser->new(
        Handlers => {
            Start => sub { push @elts, $_[1] },
        },
    );
    $p->parse($fh);
    is_deeply( \@elts, ['b'], 'special-char delimiter: second doc available' );

    close $fh;
}

# ===== Single-document stream (no delimiter present) =====
{
    my $content = qq{<root><child/></root>\n};
    my $fh      = make_stream($content);

    my @elts;
    my $p = XML::Parser->new(
        Stream_Delimiter => $delim,
        Handlers         => {
            Start => sub { push @elts, $_[1] },
        },
    );
    $p->parse($fh);
    is_deeply( \@elts, [qw(root child)], 'no delimiter in stream: full document parsed' );

    close $fh;
}

# ===== Document with trailing whitespace before delimiter =====
{
    my $doc1   = qq{<root>data</root>\n};
    my $stream = $doc1 . "$delim\n";
    my $fh     = make_stream($stream);

    my $chardata = '';
    my $p        = XML::Parser->new(
        Stream_Delimiter => $delim,
        Handlers         => {
            Char => sub { $chardata .= $_[1] },
        },
    );
    $p->parse($fh);
    is( $chardata, 'data', 'chardata correct when delimiter follows document' );

    close $fh;
}

# ===== Parser reuse: same parser object for multiple delimited parses =====
{
    my $doc1   = qq{<r><a/></r>\n};
    my $doc2   = qq{<r><b/><c/></r>\n};
    my $stream = $doc1 . "$delim\n" . $doc2 . "$delim\n";
    my $fh     = make_stream($stream);

    my @all_elts;
    my $p = XML::Parser->new(
        Stream_Delimiter => $delim,
        Handlers         => {
            Start => sub { push @all_elts, $_[1] },
        },
    );

    $p->parse($fh);
    is_deeply( \@all_elts, [qw(r a)], 'parser reuse: first parse correct' );

    @all_elts = ();
    $p->parse($fh);
    is_deeply( \@all_elts, [qw(r b c)], 'parser reuse: second parse correct' );

    close $fh;
}

done_testing();
