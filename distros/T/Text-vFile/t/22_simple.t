
use Test::More qw(no_plan);


use Text::vFile::Base;

my $cards=Text::vFile::Base->load( "t/02_simple.dat" );

use Data::Dumper;
$Data::Dumper::Indent=1;

my $count=0;
foreach my $card (@$cards) {
	$count++;
    ok ( exists $card->{'ADR'}, "ADR loaded");
    is ( scalar( @{$card->{'ADR'}}), 3, "3 addresses loaded");
    ok ( exists $card->{'PHOTO'}, "PHOTO loaded");
    ok ( exists $card->{'VERSION'}, "VERSION loaded");
}

is ( $count, 1, "Just one card loaded");
