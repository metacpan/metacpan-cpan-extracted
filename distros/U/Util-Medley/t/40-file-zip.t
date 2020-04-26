use Test::More;
use Modern::Perl;
use Util::Medley::File::Zip;
use Data::Printer alias => 'pdump';

#####################################
# constructor
#####################################

my $fz = Util::Medley::File::Zip->new;
ok($fz);

done_testing;
