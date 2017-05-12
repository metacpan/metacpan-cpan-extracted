#!/usr/bin/perl -w
use strict;
use Text::CSV_XS;
use Text::CSV::Separator qw(get_separator);

$|++;

my $csv_path;
if ($ARGV[0]) {
    $csv_path = $ARGV[0];
} else {
    die "Usage: perl separator.pl <file_path>\n";
}

my @char_list = get_separator( path => $csv_path );

my $separator;
if (@char_list) {
    if (@char_list == 1) {
        $separator = $char_list[0];
    } else {
        $separator  = $char_list[0];
    }
} else {
    die "Couldn't detect the field separator.\n";
}

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