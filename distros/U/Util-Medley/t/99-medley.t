use Test::More;
use Modern::Perl;
use Util::Medley;
use Data::Printer alias => 'pdump';

#####################################
# constructor
#####################################

my $medley = Util::Medley->new;
ok($medley);

my $dt = $medley->DateTime;
ok( $dt->localDateTime);

done_testing;
