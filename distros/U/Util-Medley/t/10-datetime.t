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

ok(my $dtstr = $dt->localdatetime);
ok($dtstr =~ /\d\d\d\d\-\d\d-\d\d \d\d:\d\d:\d\d/);

done_testing;
