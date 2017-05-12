#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use File::Slurp;
use Text::Fuzzy;
use Getopt::Long;
my $file = '/usr/share/dict/words';
GetOptions (
    "file=s" => \$file,
    "distance=i" => \my $max_distance,
);
my $word;
if (@ARGV) {
    $word = $ARGV[0];
}
else {
    $word = 'bingos';
}
my $tf = Text::Fuzzy->new ($word);
if (defined $max_distance) {
    $tf->set_max_distance ($max_distance);
}
my $nearest = $tf->scan_file ($file);
if ($nearest) {
    print "Nearest to $word is '$nearest'.\n";
}
else {
    print "Nothing similar in $file.\n";
}
