use strict;
use warnings;
use File::Spec;
use FindBin::libs;
use Text::SimSearch;
use Data::Dumper;

my $save_file = File::Spec->catfile( $FindBin::RealBin, "save.bin" );
my $indexer = Text::SimSearch->new;
$indexer->load($save_file);

my $source_file = File::Spec->catfile( $FindBin::RealBin, "data", "sample.txt" );

open( FILE, "<", $source_file);
my $n = 0;
while (<FILE>) {
    my $rec = <FILE>;
    chomp $rec;
    my @f     = split "\t", $rec;
    my $label = shift @f;
    my %vec   = @f;

    print ++$n, "\n";
    print $label, "\n";
    print Dumper \%vec;
    my $result = $indexer->search( \%vec, 10 );
    print Dumper $result;

    print "-" x 100, "\n";
}