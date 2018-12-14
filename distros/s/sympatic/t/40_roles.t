use lib qw( t/lib/role );
use Test::More;
use Pet;
# use_ok 'Pet';

my $donald = Pet->new(qw( name donald ));
$donald->fly;
is $donald->altitude, 10, "donald can fly";

done_testing;
