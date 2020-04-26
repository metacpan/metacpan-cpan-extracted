use Test::More;
use Modern::Perl;
use Util::Medley::XML;
use Data::Printer alias => 'pdump';

#####################################
# constructor
#####################################

my $util = Util::Medley::XML->new;
ok($util);

done_testing;
