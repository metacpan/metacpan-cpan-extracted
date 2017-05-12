# -*- perl -*-

# t/001_load.t - check module loading

use Test::More tests => 4;

BEGIN { use_ok( 'WWW::SourceForge' ); }
BEGIN { use_ok( 'WWW::SourceForge::User' ); }
BEGIN { use_ok( 'WWW::SourceForge::Project' ); }

my $object = WWW::SourceForge->new ();
isa_ok ($object, 'WWW::SourceForge', 'WWW::SourceForge interface loads ok');


