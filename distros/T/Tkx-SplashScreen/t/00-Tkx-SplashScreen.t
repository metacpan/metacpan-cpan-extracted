use strict;
use warnings;
use Tkx ();
use Test::More tests => 2;

BEGIN { use_ok('Tkx::SplashScreen') }

my $mw = Tkx::widget->new('.');
my $sp = $mw->new_tkx_SplashScreen();
ok($sp, 'new');


