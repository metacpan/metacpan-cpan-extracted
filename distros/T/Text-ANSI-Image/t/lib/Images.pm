package Images;

# Files which say they are images of a size: only their headers are
# read by Text::ANSI::Image, so nothing else is in them.

use strict;
use warnings;
use Exporter 'import';
our @EXPORT = qw(png gif jpeg);

sub write_file {
    my($file, $data) = @_;
    open my $fh, '>:raw', $file or die "$file: $!";
    print $fh $data;
    close $fh;
    $file;
}

sub png {
    my($file, $w, $h) = @_;
    write_file($file, "\x89PNG\r\n\x1a\n" . pack('N', 13) . 'IHDR'
	       . pack('NNCCCCC', $w, $h, 8, 6, 0, 0, 0) . "\0\0\0\0"
	       . pack('N', 0) . 'IEND' . "\xae\x42\x60\x82");
}

sub gif {
    my($file, $w, $h) = @_;
    write_file($file, 'GIF89a' . pack('vv', $w, $h) . "\0\0\0;");
}

sub jpeg {
    my($file, $w, $h) = @_;
    write_file($file, "\xff\xd8"
	       . "\xff\xe0" . pack('n', 16) . "JFIF\0" . ("\0" x 9)
	       . "\xff\xc0" . pack('n', 17) . pack('Cnn', 8, $h, $w) . ("\0" x 10)
	       . "\xff\xd9");
}

1;
