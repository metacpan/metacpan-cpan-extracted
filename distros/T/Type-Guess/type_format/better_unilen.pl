use Encode qw/decode encode/;
use utf8;

$\ = "\n"; $, = "\t";
# $s = 0;

open my $uni, "/home/simone/Downloads/unicode_strings.txt";
my @in = map { chomp; $_ } <$uni>;

my @l = map {
    my $decoded = utf8::is_utf8($input) ? $input : decode("UTF-8", $_);
    [
     sprintf ("%-32s", $decoded),
     sprintf ("%02i", length($decoded)),
     sprintf ("%02i", length($_)),
    ]
} @in;

print encode "UTF-8", $_ for map { join " | ", $_->@* } @l;

print "-" x 80;
use Unicode::GCString;

# Read and process each line
my @l = map {
    my $decoded = decode "UTF-8", $_;
    $gcstr = Unicode::GCString->new($decoded);
    my $formatted_string = sprintf("%-*s",  (32 + length($gcstr->as_string) - $gcstr->columns), $gcstr->as_string);

    [
     $formatted_string,  # Ensure printable string for formatting
     length($decoded),
     length($gcstr->as_string),           # Grapheme length
     $gcstr->columns,                       # Display width
     length($_),                           # Byte length
    ]
} split /\n/, path("/home/simone/Downloads/unicode_strings.txt")->slurp;

# Output the table with UTF-8 encoding
print encode("UTF-8", tablify(\@l));

use Mojo::File qw/path/;
use Mojo::Util qw/decode encode tablify/;
use Unicode::GCString;

$\ = "\n"; $, = "\t";

# Desired fixed column width for alignment
my $display_width = 32;

my @l = map {
    my $decoded = decode "UTF-8", $_;
    my $gcstr   = Unicode::GCString->new($decoded);
    my $padding = $display_width - $gcstr->columns;
    my $formatted_string = $gcstr->as_string . (' ' x ($padding > 0 ? $padding : 0));

    [
        $formatted_string,
        length($gcstr->as_string),  # Grapheme length
        length($_),                 # Byte length
        $gcstr->columns             # Display width
    ]
} split /\n/, path("/home/simone/Downloads/unicode_strings.txt")->slurp;

# Print the table with UTF-8 encoding
print encode("UTF-8", tablify(\@l));
