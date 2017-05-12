use strict;
use Text::CSV::Unicode;

my $csv = Text::CSV::Unicode->new( binary => 1 );

my @data;
while( <DATA> ) {
    while( tr/"/"/ % 2 and my $line = <DATA> ) { $_ .= $line }
    $csv -> parse($_) or die $csv->error_input;
    push @data, [$csv->fields];
}

use Data::Dumper;
print Dumper(\@data); 

__END__
Author,Organisation,Count,Comment
Robin Barker,NPL,1,"This is a short comment"
Chris Eiø,NPL,0,"This is a comment with o's ÒÓÔÕÖØğòóôõö"
Åsmund Sand,Justervesenet,-1,"This is a long comment
split over two lines"
Walter Wöger,PTB,100,"""no comment"""
