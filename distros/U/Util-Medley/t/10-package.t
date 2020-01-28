use Test2::V0;
use Test2::Plugin::DieOnFail;
use Modern::Perl;
use Util::Medley::Package;
use Data::Printer alias => 'pdump';

#####################################
# constructor
#####################################

my $pkg = Util::Medley::Package->new;
ok($pkg);

#####################################
# basename
#####################################

ok($pkg->basename($pkg) eq 'Package');
ok($pkg->basename('Foo::Bar') eq 'Bar');

done_testing;
