use strict;
use warnings;
use File::Spec;
use FindBin::libs;
use Text::SimSearch;
use Data::Dumper;

my $save_file = File::Spec->catfile( $FindBin::RealBin, "save.bin" );

my $indexer = Text::SimSearch->new;
$indexer->load($save_file);

loop();

sub loop {
    print "Input text: ";
    my $in = <STDIN>;
    chomp $in;
    loop() if !$in;
    my $input = { $in => 1 };
    my $result = $indexer->search($input, 5);
    print Dumper $result;
    loop();
}