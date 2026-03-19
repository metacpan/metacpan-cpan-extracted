BEGIN { print "1..3\n"; }
END { print "not ok 1\n" unless $loaded; }
use XML::Parser;
use File::Temp qw(tempfile);
$loaded = 1;
print "ok 1\n";

# Test that character data spanning buffer boundaries is correctly delivered
# across multiple Char handler calls (GitHub issue #56 / rt.cpan.org #122970).
#
# The expat parser uses a fixed-size read buffer (32 KiB). When character
# data straddles two buffer fills, the Char handler is invoked once for each
# chunk. This is documented, correct behaviour — user code must concatenate
# successive Char calls between Start/End events.

my $bufsize = 32768;    # must match BUFSIZE in Expat.xs

# Build a document where text content deliberately spans the buffer boundary.
# The element markup is kept short so nearly all bytes are character data.
my $text_len = $bufsize + 512;    # guaranteed to cross at least one boundary
my $long_text = 'A' x $text_len;
my $doc = "<r>$long_text</r>";

# Write to a temp file — string parsing hands expat the whole buffer at once,
# so the split only occurs when parsing from a stream/file.
my ( $fh, $tmpfile ) = tempfile( UNLINK => 1, SUFFIX => '.xml' );
binmode($fh);
print $fh $doc;
close $fh;

# --- Test 2: multiple Char calls are made for text crossing a boundary --------
my $char_calls = 0;
my $accumulated = '';

sub count_char {
    my ( $xp, $str ) = @_;
    $char_calls++;
    $accumulated .= $str;
}

my $p = XML::Parser->new( Handlers => { Char => \&count_char } );
$p->parsefile($tmpfile);

if ( $char_calls > 1 ) {
    print "ok 2\n";
}
else {
    print "not ok 2 # expected >1 Char calls, got $char_calls\n";
}

# --- Test 3: concatenated chunks equal the original text ----------------------
if ( $accumulated eq $long_text ) {
    print "ok 3\n";
}
else {
    my $got_len = length($accumulated);
    print "not ok 3 # accumulated length $got_len, expected $text_len\n";
}
