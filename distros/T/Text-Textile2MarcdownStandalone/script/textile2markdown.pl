use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Getopt::Long;
use Text::Textile2MarcdownStandalone;

sub usage {
    die <<"EOF";
Usage: $0 --input FILE [--output FILE]
  --input,  -i  Textile file（require）
  --output, -o  Markdown file (if omitted, prints to STDOUT)
EOF
}

my ($input_file, $output_file);
GetOptions(
    'input|i=s'  => \$input_file,
    'output|i=s' => \$output_file,
) or usage();

usage unless $input_file;

my $conv = Text::Textile2MarcdownStandalone->new(
    input_file => $input_file,
    (defined $output_file ? (output_file => $output_file) : ()),
);

my $result = $conv->convert;
if (!defined $output_file) {
    print $result;
}
