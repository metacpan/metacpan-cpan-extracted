use Test2::V0;
use Test2::Plugin::DieOnFail;
use Modern::Perl;
use Util::Medley;
use Data::Printer alias => 'pdump';

#####################################
# constructor
#####################################

my $medley = Util::Medley->new;
ok($medley);

my $dt = $medley->DateTime;
ok( $dt->localdatetime);

done_testing;
