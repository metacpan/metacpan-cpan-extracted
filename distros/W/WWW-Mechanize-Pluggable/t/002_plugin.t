use Test::More tests=>5;
use FindBin;
use lib "$FindBin::Bin/lib";

use_ok qw(WWW::Mechanize::Pluggable);
my $mech = new WWW::Mechanize::Pluggable;
can_ok $mech, qw(hello_world);
can_ok $mech, qw(nested);
can_ok $mech, qw(no_params);
can_ok 'WWW::Mechanize::Pluggable', 'classy';


