use Test2::V0;
use Test2::Plugin::DieOnFail;
use Modern::Perl;
use Util::Medley::XML;
use Data::Printer alias => 'pdump';

#####################################
# constructor
#####################################

my $util = Util::Medley::XML->new;
ok($util);

done_testing;
