use Test2::V0;
use Test2::Plugin::DieOnFail;
use Modern::Perl;
use Util::Medley::DateTime;
use Data::Printer alias => 'pdump';

#####################################
# constructor
#####################################

my $dt = Util::Medley::DateTime->new;
ok($dt);

#####################################
# localdatetime
#####################################

$dt = Util::Medley::DateTime->new;

ok(my $dtstr = $dt->localDateTime);
ok( $dt->localDateTimeIsValid($dtstr));

ok(!$dt->localDateTimeIsValid('foobar'));
ok(!$dt->localDateTimeIsValid('0000-88-00 88:00:00'));

done_testing;
