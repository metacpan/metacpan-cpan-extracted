use Test2::V0;
use Test2::Plugin::DieOnFail;
use Modern::Perl;
use Util::Medley::File::Zip;
use Data::Printer alias => 'pdump';

#####################################
# constructor
#####################################

my $fz = Util::Medley::File::Zip->new;
ok($fz);

done_testing;
