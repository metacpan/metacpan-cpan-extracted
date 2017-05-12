#!/usr/bin/perl -w
use strict;
use Text::CSV_XS;
use Text::CSV::Separator qw(get_separator);

$|++;

my $csv_path;
if ($ARGV[0]) {
    $csv_path = $ARGV[0];
} else {
    die "Usage: perl separator_lucky.pl <file_path>\n";
}

my $separator = get_separator( path => $csv_path, lucky => 1 );
print "\nSeparator: $separator\n";

my $csv_parser = Text::CSV_XS->new(
                                   {
                                        sep_char => "$separator",
                                        binary => '1',
                                        always_quote => '1'
                                   }
                                  );


open my $csv_fh, '<', $csv_path;

while (<$csv_fh>) {
    $csv_parser->parse($_);
    my @fields = $csv_parser->fields;
    print "\nRecord #$.\n";
    foreach my $field (@fields) {
        print "$field\n";
    }
}

close $csv_fh;