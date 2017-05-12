use strict;
use warnings;
use Tkx;
use Test::More tests => 2;

BEGIN { use_ok('Tkx::FindBar') }

my $mw = Tkx::widget->new('.');
my $findbar = $mw->new_tkx_FindBar();
ok($findbar, 'new');
