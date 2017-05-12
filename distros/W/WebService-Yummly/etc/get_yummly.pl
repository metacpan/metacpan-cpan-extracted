

use lib qw/lib/;

use WebService::Yummly;
use Data::Dumper;


my $y = WebService::Yummly->new;
my $recipes = $y->search("lamb shank") ;

foreach my $r ( @{ $recipes->{matches} } ) {
    print $r->{sourceDisplayName}.  " : " . $r->{recipeName} . "\n";
}
