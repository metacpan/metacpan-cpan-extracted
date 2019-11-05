use Test2::V0;
use Test2::Plugin::DieOnFail;
use Modern::Perl;
use Util::Medley::FileZip;
use Data::Printer alias => 'pdump';

#####################################
# constructor
#####################################

my $fz = Util::Medley::FileZip->new;
ok($fz);

done_testing;
