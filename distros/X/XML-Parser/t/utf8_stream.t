BEGIN { print "1..2\n"; }
END { print "not ok 1\n" unless $loaded; }
use XML::Parser;
$loaded = 1;
print "ok 1\n";

################################################################
# Test parsing from a filehandle with :utf8 layer
# Regression test for rt.cpan.org #19859 / GitHub issue #64
# A UTF-8 stream caused buffer overflow because SvPV byte count
# could exceed the pre-allocated XML_GetBuffer size.

use File::Temp qw(tempfile);

# Create a temp file with UTF-8 XML content containing multi-byte chars
my ($fh, $tmpfile) = tempfile(UNLINK => 1);
binmode($fh, ':raw');
# Write raw UTF-8 bytes: XML with Chinese characters (3 bytes each in UTF-8)
# U+4E16 U+754C (世界 = "world") repeated to create substantial multi-byte content
my $body = "\xe4\xb8\x96\xe7\x95\x8c" x 20000;  # 120000 bytes / 40000 chars of 3-byte UTF-8
print $fh qq(<?xml version="1.0" encoding="UTF-8"?>\n<doc>$body</doc>\n);
close($fh);

my $text = '';
my $parser = XML::Parser->new(
    Handlers => {
        Char => sub { $text .= $_[1]; },
    }
);

# Open with :utf8 layer - this is what triggers the bug
open(my $in, '<:utf8', $tmpfile) or die "Cannot open $tmpfile: $!";
eval { $parser->parse($in); };
close($in);

if ($@ eq '' && length($text) > 0) {
    print "ok 2\n";
} else {
    print "not ok 2 # $@\n";
}
